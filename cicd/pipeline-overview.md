# Pipeline Overview

## Overview

이 문서는 AWS EKS 기반 서비스 운영 환경에서 구성한 CI/CD 파이프라인의 전체 흐름을 설명합니다.

이 프로젝트의 배포 목표는 다음과 같았습니다.

- 이미지 빌드와 배포 정의를 분리한 구조 구성
- 환경별(dev / qa / prod) 배포 흐름 표준화
- 수동 배포 절차를 줄이고 운영 효율 향상
- Git 기반 변경 이력 추적 가능
- 반복 가능한 배포 구조 확보

이 파이프라인은 단순히 “코드를 빌드해서 서버에 배포한다”는 수준이 아니라, Source Repository와 Manifest Repository를 분리한 GitOps 기반 배포 흐름을 중심으로 설계했습니다.

---

## High-Level Flow

전체 배포 흐름은 다음과 같습니다.

    Developer
      ↓
    GitHub Source Repository
      ↓
    Webhook Trigger
      ↓
    AWS CodeBuild
      ├─ Docker Build
      ├─ Image Push to ECR
      └─ Manifest Repository Update
                  ↓
               ArgoCD
                  ↓
            Kubernetes Cluster

---

## Pipeline Components

### GitHub Source Repository

애플리케이션 소스 코드를 관리하는 저장소입니다.

#### 역할

- 서비스 코드 관리
- 브랜치 기반 개발 흐름 유지
- PR / Merge 기반 변경 관리
- CI 시작점 역할

#### 운영 의도

애플리케이션 코드와 배포 정의를 같은 저장소에 두면 구조는 단순하지만, 운영 환경이 커질수록 배포 이력과 코드 이력이 섞이게 됩니다.  
이 프로젝트에서는 운영 관점에서 책임을 분리하기 위해 Source Repository와 Manifest Repository를 나누었습니다.

---

### Webhook Trigger

GitHub의 코드 변경 이벤트를 기반으로 CodeBuild를 실행하는 트리거입니다.

#### 역할

- Push 또는 PR Merge 이후 자동 빌드 시작
- 수동 빌드 개입 최소화
- 배포 가능한 산출물 생성 흐름 자동화

#### 기대 효과

- 운영자의 반복적인 수동 작업 감소
- 빌드 시작 시점 일관성 확보
- CI 흐름 표준화

---

### AWS CodeBuild

CI 단계의 핵심 구성 요소로 사용했습니다.

#### 역할

- 애플리케이션 빌드
- Docker 이미지 생성
- ECR Push
- Manifest Repository의 이미지 태그 또는 경로 갱신

#### 왜 CodeBuild를 사용했는가

- AWS 환경과의 연계가 자연스러움
- ECR Push 흐름 구성 용이
- 별도 CI 서버 운영 부담 감소
- 빌드 인프라를 관리형으로 운영 가능

#### 기대 효과

- 빌드 일관성 확보
- 이미지 산출물 관리 단순화
- Git 기반 배포 흐름과 자연스럽게 연결 가능

---

### Amazon ECR

Docker 이미지 저장소로 사용했습니다.

#### 역할

- CodeBuild가 생성한 이미지를 저장
- Kubernetes 배포 시 사용할 이미지 제공
- 환경별 / 서비스별 이미지 관리

#### 운영 포인트

- 이미지 태그 전략을 일관되게 유지
- Source 변경과 Manifest 변경의 연결 고리 역할
- 실제 배포 대상 산출물 저장소 역할 수행

---

### Manifest Repository

배포 정의를 관리하는 별도 저장소입니다.

#### 역할

- Deployment, Service, Ingress, HPA 등 Kubernetes 리소스 관리
- 환경별(dev / qa / prod) 배포 구조 분리
- 제품 / 서비스별 배포 단위 구분
- ArgoCD가 기준으로 삼는 GitOps 소스 역할

#### 왜 분리했는가

- 코드 변경과 배포 변경의 책임 분리
- 배포 이력 추적 용이
- 환경별 설정 관리 단순화
- 운영자가 코드와 배포를 서로 다른 관점으로 관리할 수 있음

---

### ArgoCD

CD를 담당하는 GitOps 도구로 사용했습니다.

#### 역할

- Manifest Repository polling
- 변경 감지 후 Kubernetes 리소스 동기화
- 배포 상태 시각화
- 환경별 애플리케이션 관리

#### 기대 효과

- 수동 배포 절차 감소
- Git 기준 배포 흐름 유지
- 운영 시 배포 상태 확인 용이
- Git과 실제 클러스터 상태의 차이를 줄이는 운영 방식 가능

---

### Kubernetes Cluster

최종적으로 애플리케이션이 배포되는 실행 환경입니다.

#### 역할

- 배포 대상 워크로드 실행
- 서비스 / ingress / autoscaling 운영
- 환경별 운영 기준 반영

#### 연결 구조

- ECR의 이미지를 사용
- Manifest Repository의 배포 정의를 기준으로 실행
- ArgoCD가 동기화 담당

---

## Why GitOps

이 프로젝트에서는 GitOps 기반 구조를 선택했습니다.

### 선택 이유

- 배포 정의를 Git으로 관리할 수 있음
- 변경 이력을 명확하게 추적 가능
- 환경별 구조를 명확하게 나눌 수 있음
- 코드 빌드와 배포 실행을 분리할 수 있음
- ArgoCD를 통해 클러스터 상태를 선언적으로 관리할 수 있음

### 실무적인 장점

- 운영자가 “무엇이 배포되어야 하는가”를 Git 기준으로 확인 가능
- 코드 저장소와 배포 저장소의 역할이 명확해짐
- 환경별 설정 누락이나 수동 수정 리스크 감소
- 신규 환경 추가 시 구조 재사용 용이

---

## Deployment Flow in Practice

실제 배포 흐름은 보통 다음 순서로 진행됩니다.

### 1. 코드 변경

개발자가 Source Repository에 변경을 Push 하거나 PR을 Merge 합니다.

### 2. 빌드 시작

Webhook에 의해 CodeBuild가 실행됩니다.

### 3. 이미지 생성 및 Push

CodeBuild가 Docker 이미지를 빌드하고 ECR에 Push 합니다.

### 4. Manifest 갱신

CodeBuild가 Manifest Repository의 이미지 태그 또는 이미지 경로를 갱신합니다.

### 5. ArgoCD 동기화

ArgoCD가 Manifest Repository의 변경을 감지하고 Kubernetes Cluster에 반영합니다.

### 6. 배포 완료 확인

운영자는 ArgoCD UI 또는 클러스터 상태를 통해 배포 결과를 확인합니다.

---

## Operational Benefits

이 구조를 통해 얻은 운영상의 장점은 다음과 같습니다.

- 배포 흐름 자동화
- 수동 개입 감소
- 배포 정의와 코드의 책임 분리
- 환경별 운영 구조 표준화
- Git 기반 변경 이력 관리
- 신규 서비스 추가 시 구조 재사용 가능

---

## Trade-offs

이 구조는 단순한 단일 저장소 배포 방식보다 운영 관점에서는 유리하지만, 초기 구성 복잡도는 더 높습니다.

### 감수한 복잡도

- Source Repository와 Manifest Repository 이원화
- CodeBuild에서 Manifest 갱신 로직 필요
- ArgoCD 운영 및 관리 필요

### 대신 얻은 것

- 배포 책임 분리
- GitOps 기반 운영 표준
- 환경별 배포 구조 정리
- 배포 변경 이력 추적 가능성

---

## Outcome

이 CI/CD 파이프라인을 통해 다음과 같은 결과를 확보했습니다.

- GitHub, CodeBuild, ECR, ArgoCD 기반 자동 배포 구조 구축
- Source와 Manifest 저장소를 분리한 GitOps 흐름 정착
- 환경별(dev / qa / prod) 배포 구조 표준화
- 수동 배포 작업 감소 및 운영 효율 향상
- 반복 가능한 배포 기준 확보