# OIDC / IRSA Summary

## Overview

이 문서는 AWS EKS 환경에서 OIDC와 IRSA를 왜 사용했고, 어떤 방식으로 적용했는지 요약한 문서입니다.

EKS 운영 시 Kubernetes Add-on이나 특정 서비스가 AWS API를 호출해야 하는 경우가 있습니다.  
이때 모든 권한을 Node IAM Role에 몰아주는 방식은 운영상 과도할 수 있기 때문에, 이 프로젝트에서는 OIDC / IRSA 기반 권한 분리 방식을 적용했습니다.

핵심 목표는 다음과 같았습니다.

- Node Role 과권한 방지
- 서비스 계정 단위 AWS 권한 부여
- Add-on별 역할 분리
- 운영 보안성 향상

---

## Why OIDC / IRSA

EKS 환경에서 AWS API를 호출하는 컴포넌트는 종종 다음과 같은 작업을 수행합니다.

- Load Balancer 생성 및 수정
- Target Group 관리
- Auto Scaling Group 조회 및 조정
- EBS / IAM / 기타 AWS 리소스 연동

이 권한을 모두 Worker Node Role에 포함시키면, 클러스터 전체 관점에서 권한 범위가 불필요하게 커질 수 있습니다.

### 그래서 선택한 방식

- EKS Cluster에 OIDC Provider 연결
- 필요한 Service Account에만 IAM Role 연결
- 특정 Add-on이 필요한 AWS 권한만 가지도록 분리

이 방식은 "클러스터 안의 모든 Pod가 Node Role을 통해 AWS 권한을 공유하는 구조"를 피하기 위한 선택이었습니다. 실제 운영에서는 ALB Controller와 Autoscaler처럼 AWS API 호출이 명확한 컴포넌트부터 우선 적용했습니다.

---

## Core Concept

### OIDC Provider

EKS Cluster와 AWS IAM 사이의 신뢰 기반을 연결하는 구성입니다.

#### 역할

- EKS Service Account가 IAM Role을 Assume 할 수 있는 기반 제공
- IRSA를 사용할 수 있도록 연결 고리 역할 수행

### IRSA

IAM Roles for Service Accounts의 약자로, Kubernetes Service Account에 IAM Role을 연결하는 방식입니다.

#### 역할

- Pod 또는 Add-on이 특정 Service Account를 통해 AWS 권한 획득
- Node Role이 아닌 Service Account 단위로 권한 관리 가능

---

## Why This Matters

이 구조를 적용하면 다음과 같은 장점이 있습니다.

### 최소 권한에 가까운 운영 가능

필요한 컴포넌트에만 필요한 권한을 줄 수 있습니다.

### 역할 분리 명확화

Load Balancer Controller와 Autoscaler 같은 컴포넌트가 각자 필요한 역할만 수행하게 할 수 있습니다.

### 운영 추적성 향상

권한 문제가 발생했을 때, 어떤 Service Account가 어떤 Role을 사용했는지 더 명확하게 볼 수 있습니다.

### Node Role 단순화

Worker Node 전체에 과도한 AWS 권한을 부여하지 않아도 됩니다.

---

## Applied Components

이 프로젝트에서는 IRSA를 우선 핵심 운영 컴포넌트 중심으로 적용했습니다.

### 1. AWS Load Balancer Controller

#### 필요한 이유

- Ingress 기반으로 ALB를 생성하고 관리해야 함
- Listener, Target Group, Security Group 등 AWS 리소스를 제어해야 함

#### 기대 효과

- ALB 관련 권한을 Controller에만 한정
- Node Role 과권한 방지
- Ingress 운영 구조와 자연스럽게 연결

#### 실제 적용 포인트

- OIDC Provider를 먼저 연결한 뒤, `kube-system/aws-load-balancer-controller` Service Account를 신뢰하는 IAM Role을 만들었습니다.
- 이후 Service Account annotation으로 Role ARN을 연결하고, Helm 설치 시 `serviceAccount.create=false`로 두어 IRSA 대상 계정을 명시적으로 사용했습니다.
- 이 방식으로 ALB 생성 권한이 Ingress Controller에만 묶이도록 유지했습니다.

---

### 2. Cluster Autoscaler

#### 필요한 이유

- Auto Scaling Group 조회 및 조정 필요
- Worker Node 확장 / 축소를 위해 AWS API 호출 필요

#### 기대 효과

- Autoscaler에 필요한 권한만 별도 분리
- 클러스터 확장성 운영 기준 정리
- Node Role에 전체 확장 권한을 부여하지 않아도 됨

#### 실제 적용 포인트

- `kube-system/cluster-autoscaler` Service Account를 신뢰 대상으로 하는 Role을 별도로 만들었습니다.
- Autoscaler는 Auto Scaling Group 조회와 Desired Capacity 조정이 필요하기 때문에, 관련 정책을 별도 IAM Policy로 분리했습니다.
- 결과적으로 Node Role은 ECR Pull, CNI, 기본 노드 운영 권한에 집중시키고, 확장 제어 권한은 Autoscaler 쪽으로 분리할 수 있었습니다.

---

## Typical Flow

OIDC / IRSA 적용 흐름은 보통 다음과 같습니다.

### 1. OIDC Provider 생성

EKS Cluster와 연결된 IAM OIDC Provider를 생성합니다.

### 2. IAM Policy 생성

대상 Add-on이 필요한 AWS API 권한을 가진 정책을 생성합니다.

### 3. IAM Role 생성

OIDC Provider를 신뢰하는 IAM Role을 생성합니다.

### 4. Policy 연결

생성한 IAM Policy를 IAM Role에 연결합니다.

### 5. Service Account 구성

Kubernetes Service Account에 IAM Role ARN Annotation을 추가합니다.

### 6. Deployment 연결

대상 Add-on 또는 워크로드가 해당 Service Account를 사용하도록 배포합니다.

실제 운영에서는 "OIDC Provider 생성 -> IAM Policy/Role 생성 -> Service Account annotation -> Helm 또는 kubectl 배포" 순서가 가장 안정적이었습니다. 중간에 Namespace나 Service Account 이름이 바뀌면 Trust Policy를 다시 맞춰야 해서, 네이밍과 Namespace 고정이 중요했습니다.

---

## Operational Considerations

이 구조를 운영하면서 중요하게 본 점은 다음과 같습니다.

### 모든 서비스에 한 번에 적용하지 않음

우선 AWS API 호출이 꼭 필요한 핵심 컴포넌트부터 적용했습니다.

### 신뢰 정책 관리 필요

OIDC Provider와 Service Account 이름, Namespace까지 정확히 맞아야 Role Assume이 가능합니다.

### 환경별 관리 필요

Cluster가 다르면 OIDC ID도 달라질 수 있으므로, 환경별 Role 관리가 필요합니다.

### Service Account 이름 고정 필요

Trust Policy에는 Namespace와 Service Account 이름이 직접 들어가기 때문에, 배포 YAML과 IAM 설정을 따로 변경하면 AssumeRole 실패가 바로 발생합니다.

### 클러스터별 Role 분리 필요

`dev / qa / prod`처럼 클러스터가 나뉘면 OIDC 식별자도 달라지므로, 같은 Add-on이라도 환경별로 Role을 별도 관리하는 편이 안전합니다.

---

## Trade-offs

OIDC / IRSA는 보안성과 권한 분리 측면에서는 장점이 크지만, 초기 설정 복잡도는 증가합니다.

### 감수한 복잡도

- OIDC Provider 구성 필요
- IAM Policy / Role / Trust Policy 관리 필요
- Service Account와 Deployment 연동 필요

### 대신 얻은 것

- 서비스 계정 단위 권한 분리
- Node Role 과권한 방지
- 운영 보안성 향상
- Add-on별 책임 분리

---

## Outcome

OIDC / IRSA 적용을 통해 다음과 같은 기반을 확보했습니다.

- AWS Load Balancer Controller 권한 분리
- Cluster Autoscaler 권한 분리
- Node Role 과권한 완화
- 서비스 계정 단위 IAM 관리 기반 확보
- 보안성과 운영 관리성 모두를 고려한 권한 구조 정리
- "Node에 권한을 몰아주는 구조"에서 "필요한 Add-on에만 권한을 주는 구조"로 전환
