# Security and Access

## Overview

이 문서는 AWS EKS 기반 서비스 운영 환경에서 적용한 접근 제어 및 보안 설계 방식을 설명합니다.

이 프로젝트의 보안 설계 목표는 다음과 같습니다.

- Private 리소스의 직접 외부 노출 최소화
- 데이터 계층 접근 범위 제한
- 서비스 계정 단위 AWS 권한 분리
- 운영 접근 경로 일원화
- 운영 가능성과 보안성 사이의 현실적인 균형 확보

이 구조는 완벽하게 이상적인 제로트러스트 환경을 구현하는 것보다, 실서비스 운영에 필요한 보호 수준과 운영 편의성 사이에서 현실적으로 균형을 맞추는 방향으로 설계했습니다.

---

## Access Strategy

### Bastion 중심 접근 구조

Private 리소스에 대한 운영 접근은 Bastion Host를 통해 일원화했습니다.

#### 적용 방식

- Bastion Host는 Public 영역에 배치
- 허용된 운영 IP만 접근 허용
- PEM Key 기반 접근
- Bastion 경유 후 Private Worker Node 또는 내부 자원 접근

#### 목적

- Private Node 및 내부 리소스 직접 노출 방지
- 운영 접근 경로를 단일화
- 접근 정책 관리 단순화

#### 장점

- 외부에서 Private 리소스를 직접 노출하지 않아도 됨
- 운영 접근 기준을 Bastion 중심으로 관리 가능
- 네트워크 경계가 명확해짐

#### 한계

- PEM Key 관리 부담 존재
- Bastion이 운영 접근의 핵심 경로가 됨
- 향후에는 SSM Session Manager 방식으로 대체 가능

---

## Security Group Design

보안 그룹은 서비스 운영 편의성과 접근 제어 사이에서 균형을 고려해 구성했습니다.

### Cluster Security Group

EKS Control Plane과 Worker Node 사이의 통신을 위해 기본적인 클러스터 보안 그룹을 설정했습니다.

#### 역할

- Worker Node의 Kubernetes API 접근 허용
- 클러스터 내부 통신 유지

#### 주요 포인트

- Node Group이 API Server에 접근할 수 있도록 443 포트 허용
- 내부 클러스터 통신은 기본적으로 허용

### Worker Node Security Group

Worker Node에 대한 보안 그룹은 내부 통신과 운영 접근, 서비스 실행 관점에서 구성했습니다.

#### 역할

- Cluster와의 통신 허용
- 내부 노드 간 통신 허용
- 제한적 운영 접근 허용
- 데이터 계층 접근 시 기준 그룹 역할 수행

#### 설계 의도

- Worker Node는 외부 직접 노출을 피하고 Private 환경에서 운영
- 서비스별 접근 정책은 추가 Security Group 조합으로 보완

### Redis Security Group

Redis는 모든 Worker Node에 일괄 개방하지 않고, 필요한 서비스 그룹만 접근할 수 있도록 설계했습니다.

#### 목적

- 서비스별 Redis 접근 범위 제한
- 불필요한 내부 접근 최소화
- 장애 또는 오용 시 영향 범위 축소

#### 예시

- backend 계열 워크로드만 Redis 접근 허용
- game 또는 admin 계열은 필요 시 별도 정책 적용

### RDS Security Group

Aurora 역시 서비스 성격에 따라 필요한 접근만 허용하는 방향으로 운영했습니다.

#### 목적

- DB 접근 범위 최소화
- 데이터 계층 보호
- 서비스 책임 범위 분리

#### 설계 방향

- 모든 Node Group에 무조건 허용하지 않음
- 필요한 그룹만 DB 접근 가능하도록 정책 구성
- 운영 경로는 Bastion 등 제한된 경로 중심으로 유지

---

## OIDC / IRSA

### Why IRSA

Kubernetes Add-on이나 특정 서비스가 AWS API를 호출해야 할 때, Node IAM Role에 권한을 몰아주는 방식은 운영상 과도할 수 있습니다.

이 프로젝트에서는 이를 보완하기 위해 OIDC / IRSA를 적용했습니다.

#### 적용 목적

- 서비스 계정 단위 AWS 권한 부여
- Node Role 과권한 방지
- Add-on별 역할 분리
- 운영 보안성 향상

### Applied Components

IRSA는 우선 핵심 운영 컴포넌트에 적용했습니다.

#### 적용 대상 예시

- AWS Load Balancer Controller
- Cluster Autoscaler

#### 이유

이 두 컴포넌트는 AWS API를 직접 호출해야 하므로, Node Role에 모든 권한을 두는 것보다 서비스 계정 단위 권한 분리가 더 적절했습니다.

### Security Perspective

IRSA를 통해 얻은 장점은 다음과 같습니다.

- 특정 Add-on에 필요한 권한만 부여 가능
- IAM Role 관리 범위를 서비스 계정 단위로 축소 가능
- 노드 전체에 과도한 권한을 부여하지 않아도 됨
- 운영 시 권한 문제를 더 명확히 추적 가능

---

## Public Exposure Strategy

### 외부 노출 구간 최소화

외부에 노출되는 구성 요소는 필요한 범위로 제한했습니다.

#### 외부 노출 구성

- CloudFront
- ALB
- Bastion Host (제한적 접근)

#### 직접 노출하지 않은 구성

- Worker Node
- 내부 Pod
- Aurora
- Redis

#### 기대 효과

- 서비스 실행 환경 외부 노출 최소화
- 데이터 계층 보호
- 운영 접근 정책 일관성 확보

---

## Realistic Trade-offs

이 구조는 보안성을 높이기 위해 운영 복잡도를 일부 감수한 구조입니다.

### 선택한 방향

- 직접 접근 편의성보다 Private 구조 우선
- Node Role 단순화보다 서비스 계정 권한 분리 우선
- 모든 것을 완벽히 최소 권한으로 잠그기보다, 운영 가능한 수준에서 점진적 개선

### 실제 운영에서의 의미

실무에서는 보안과 운영 편의성 사이의 균형이 중요합니다.  
이 프로젝트에서는 운영 가능하면서도 안전한 구조를 우선 확보하고, 이후 정교화할 수 있는 형태로 구성했습니다.

---

## Future Improvements

향후 보완하고 싶은 보안 관련 항목은 다음과 같습니다.

- SSM Session Manager 기반 접근 방식 검토
- Secrets Manager / External Secrets 기반 민감 정보 관리 고도화
- SG for Pods 기반 더 세밀한 서비스 단위 접근 제어
- 최소 권한 정책 재정비
- 운영 접근 감사 체계 강화

---

## Outcome

이 접근 제어 및 보안 구조를 통해 다음과 같은 기반을 확보했습니다.

- Private 리소스 직접 노출 최소화
- Bastion 중심 운영 접근 구조 정리
- Aurora / Redis 데이터 계층 접근 범위 분리
- OIDC / IRSA를 통한 Add-on 권한 분리
- 운영 보안성과 관리 용이성 간 균형 확보