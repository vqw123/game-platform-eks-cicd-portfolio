# Manifest Repository Strategy

## Overview

이 문서는 GitOps 기반 배포 구조에서 Manifest Repository를 어떤 기준으로 구성하고 운영했는지 설명합니다.

이 프로젝트에서는 애플리케이션 코드 저장소와 배포 정의 저장소를 분리했습니다.  
Manifest Repository는 Kubernetes 리소스 정의를 관리하는 저장소로, ArgoCD가 이를 기준으로 클러스터 상태를 동기화합니다.

핵심 목표는 다음과 같았습니다.

- 환경별 배포 구조 분리
- 서비스 단위 배포 책임 명확화
- 공통 리소스와 개별 서비스 리소스 분리
- ArgoCD가 관리하기 쉬운 구조 유지
- 반복 가능한 배포 기준 확보

---

## Why Separate Manifest Repository

배포 정의를 애플리케이션 코드와 같은 저장소에 두면 구조는 단순해질 수 있지만, 운영 환경이 커질수록 다음과 같은 문제가 발생할 수 있습니다.

- 코드 이력과 배포 이력이 섞임
- 환경별 리소스 관리 복잡도 증가
- 운영자가 배포 정의만 따로 관리하기 어려움
- GitOps 기준 저장소가 명확하지 않음

이 프로젝트에서는 이러한 문제를 줄이기 위해 Manifest Repository를 별도로 운영했습니다.

---

## Directory Strategy

Manifest Repository는 `${STAGE}/${PRODUCT}` 구조를 기준으로 구성했습니다.

기본 예시는 다음과 같습니다.

    .
    ├── dev/
    │   ├── common/
    │   │   ├── base-configs/
    │   │   └── zookeeper/
    │   ├── tnmt/
    │   │   ├── game/
    │   │   ├── backend/
    │   │   └── batch/
    │   └── playhub/
    │       ├── auth/
    │       └── swagger/
    ├── qa/
    │   └── ...
    └── prod/
        └── ...

---

## Design Principles

### 1. 환경별 분리

가장 바깥 레벨은 환경 기준으로 분리했습니다.

예시:

- `dev/`
- `qa/`
- `prod/`

#### 이유

- 환경별 리소스 명확한 분리
- 운영 환경과 테스트 환경의 혼재 방지
- 배포 대상 구분 명확화
- ArgoCD Application 관리 단순화

---

### 2. Product 기준 분리

환경 하위에서는 제품 또는 서비스 그룹 단위로 구조를 분리했습니다.

예시:

- `tnmt/`
- `playhub/`

#### 이유

- 서비스 영역별 책임 분리
- 배포 대상 파악 용이
- 서로 다른 제품군 간 리소스 경계 유지

---

### 3. 공통 리소스와 개별 리소스 분리

공통으로 사용하는 리소스는 `common/` 영역에 따로 분리했습니다.

예시:

- namespace
- ingress 공통 설정
- 공통 base config
- 공용 컴포넌트

#### 이유

- 중복 정의 감소
- 공통 설정 변경 시 관리 용이
- 개별 서비스 리소스와 공통 리소스의 역할 분리

---

### 4. 서비스 단위 디렉토리 구성

제품 하위에서는 서비스 단위로 다시 구조를 분리했습니다.

예시:

- `game/yokaipump/`
- `game/spacecrush/`
- `backend/`
- `batch/`
- `auth/`
- `swagger/`

#### 이유

- 서비스별 배포 단위 명확화
- 개별 서비스 변경이 다른 서비스에 미치는 영향 최소화
- 서비스별 Deployment / Service / HPA 관리 용이

---

## Managed Resources

Manifest Repository에서는 주로 다음 리소스를 관리했습니다.

- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`
- `hpa.yaml`
- `namespace.yaml`
- 공통 설정 파일
- 서비스별 환경 리소스

이 구조를 통해 ArgoCD가 특정 경로를 기준으로 환경별 / 서비스별 리소스를 관리할 수 있도록 했습니다.

---

## Example Service Layout

서비스별 디렉토리 구성 예시는 다음과 같습니다.

    dev/
    └── tnmt/
        ├── backend/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   └── hpa.yaml
        └── game/
            ├── yokaipump/
            │   ├── deployment.yaml
            │   ├── service.yaml
            │   └── hpa.yaml
            └── spacecrush/
                ├── deployment.yaml
                ├── service.yaml
                └── hpa.yaml

---

## Benefits of This Structure

이 구조를 통해 얻은 장점은 다음과 같습니다.

### 배포 단위 명확화

어떤 환경의 어떤 서비스가 어떤 리소스로 배포되는지 직관적으로 파악할 수 있습니다.

### GitOps 친화성

ArgoCD가 경로 기준으로 애플리케이션을 관리하기 쉬워집니다.

### 운영 편의성

환경별, 제품별, 서비스별 변경 범위를 쉽게 확인할 수 있습니다.

### 재사용성

공통 리소스를 재사용할 수 있어 신규 서비스 추가 시 구조를 빠르게 확장할 수 있습니다.

### 변경 이력 추적

어떤 서비스의 어떤 배포 정의가 언제 변경되었는지 Git 기준으로 명확히 남길 수 있습니다.

---

## Operational Considerations

이 구조를 실제 운영하면서 중요하게 본 점은 다음과 같습니다.

### 환경 분리 우선

개발, 검증, 운영 환경이 같은 경로 구조를 공유하지 않도록 분리하는 것이 중요했습니다.

### 공통 리소스의 범위 정의

모든 것을 공통으로 뽑기보다, 실제로 재사용 가치가 높은 항목만 공통 리소스로 분리하는 것이 유지보수에 더 유리했습니다.

### 서비스 단위 책임 유지

서비스별 디렉토리를 유지해야 배포 책임이 명확해지고, 운영자도 빠르게 변경 범위를 파악할 수 있었습니다.

---

## Trade-offs

이 구조는 단일 디렉토리 기반 Manifest 관리보다 초기에 조금 더 복잡합니다.

### 감수한 복잡도

- 디렉토리 구조 깊이 증가
- 공통 리소스와 개별 리소스 구분 필요
- 환경별 경로 관리 필요

### 대신 얻은 것

- 배포 단위 명확화
- 운영 시 가독성 향상
- GitOps 운영 구조 정리
- 신규 서비스 추가 시 재사용 가능한 표준 확보

---

## Outcome

Manifest Repository 전략을 통해 다음과 같은 결과를 확보했습니다.

- 환경별(dev / qa / prod) 배포 정의 분리
- 제품 및 서비스 단위 배포 구조 정리
- 공통 리소스와 개별 리소스의 역할 분리
- ArgoCD 운영에 적합한 GitOps 구조 확보
- 반복 가능한 배포 기준 마련