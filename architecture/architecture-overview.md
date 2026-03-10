# Architecture Overview

## Overview

본 프로젝트는 AWS EKS 기반으로 게임 및 백엔드 서비스를 운영하기 위한 구조를 설계한 사례입니다.

핵심은 “클러스터를 만들었다”가 아니라, 실제 서비스 운영을 고려해 네트워크 분리, 접근 제어, 확장성, 배포 자동화, 문서화까지 함께 구성했다는 점입니다.

이 아키텍처는 다음 목표를 기준으로 설계했습니다.

- 멀티 AZ 기반의 안정적인 운영 구조 확보
- Public / Private / Data 계층 분리
- EKS Worker Node의 외부 직접 노출 최소화
- GitOps 기반 CI/CD 자동화
- 서비스 계정 단위 권한 분리(IRSA)
- 오토스케일링 기반 확장성 확보
- 반복 가능한 운영 절차 문서화

---

## High-Level Architecture

### Request Flow

외부 요청은 다음 흐름으로 서비스에 도달합니다.

    User
      ↓
    CloudFront
      ↓
    AWS WAF
      ↓
    Application Load Balancer
      ↓
    AWS Load Balancer Controller / Ingress
      ↓
    Kubernetes Service
      ↓
    Application Pod
      ↓
    Aurora / Redis

### Delivery Flow

배포는 GitOps 기반 흐름으로 구성했습니다.

    Developer
      ↓
    GitHub Source Repository
      ↓
    AWS CodeBuild
      ├─ Docker Build
      ├─ Image Push to ECR
      └─ Manifest Repository Update
                  ↓
               ArgoCD
                  ↓
            Kubernetes Deploy

---

## Core Design Principles

### 1. Multi-AZ 기반 운영

클러스터와 네트워크는 최소 2개 이상의 가용 영역을 기준으로 구성했습니다.

#### 이유

- 단일 AZ 장애에 대한 리스크 완화
- 트래픽 분산 및 서비스 가용성 확보
- 운영 환경 안정성 향상

#### 효과

- 특정 영역 장애 시 전체 서비스 영향 최소화
- 확장형 운영 구조의 기반 확보

---

### 2. Public / Private / Data 계층 분리

네트워크는 역할에 따라 다음과 같이 계층을 나누어 운영했습니다.

#### Public Layer

- NAT Gateway
- ALB
- Bastion Host
- 외부 연계가 필요한 리소스

#### Private Layer

- EKS Worker Node
- 내부 서비스 Pod
- 외부 직접 노출이 필요 없는 애플리케이션

#### Data Layer

- Aurora
- Redis

#### 이유

- 서비스 실행 계층과 데이터 계층의 책임 분리
- 외부 노출 최소화
- 운영 및 보안 정책 적용 범위 명확화

---

### 3. Private Node 중심 클러스터 운영

EKS Worker Node는 Private Subnet에 배치했습니다.

#### 이유

- Worker Node의 외부 직접 노출 방지
- 서비스 실행 환경 보호
- 운영 접근 경로를 Bastion 중심으로 일원화

#### 보완 구조

Private Subnet에서 필요한 외부 아웃바운드 통신은 NAT Gateway를 통해 처리했습니다.

예시:

- ECR 이미지 Pull
- 외부 API 호출
- AWS API 연동
- 패키지 다운로드

---

### 4. CloudFront + ALB + Ingress 구조

외부 요청은 CloudFront를 거쳐 ALB로 유입되고, Kubernetes 내부에서는 AWS Load Balancer Controller 기반 Ingress를 통해 서비스로 라우팅했습니다.

#### 이유

- 외부 트래픽 유입 구조 분리
- CloudFront / WAF 레벨에서 1차 접근 제어 가능
- Kubernetes 서비스 라우팅 표준화
- 환경별 도메인 및 Ingress 정책 적용 용이

#### 기대 효과

- 운영 구조 단순화
- Ingress 기반 서비스 확장 용이
- 외부 진입점 관리 일관성 확보

#### 실제 운영 포인트

- CloudFront 앞단에 AWS WAF를 연결해 국가 제한, Rate limit, AWS Managed Rule, Bot 계열 방어를 적용했습니다.
- `dev / qa` 환경은 IP 기반 접근 제한을 더 강하게 두어 비운영 환경 노출 범위를 줄였습니다.
- 즉, 외부 진입점은 단순히 CloudFront를 연결하는 수준이 아니라 환경별 접근 제어 정책까지 포함해 운영했습니다.

---

### 5. GitOps 기반 배포 구조

배포는 Source Repository와 Manifest Repository를 분리한 GitOps 방식으로 구성했습니다.

#### 흐름

- Source Repository: 애플리케이션 코드 관리
- CodeBuild: Docker 이미지 빌드 및 ECR Push
- Manifest Repository: 배포 정의 관리
- ArgoCD: Manifest 변경 감지 후 클러스터 배포

#### 이유

- 이미지 빌드와 배포 정의 책임 분리
- 배포 이력 추적
- 환경별 배포 구조 관리 단순화
- 수동 배포 절차 축소

#### 구현 방식의 현실적 선택

실제 운영에서는 이 전체 구조를 처음부터 전부 Terraform으로 관리하지는 않았습니다.

- 네트워크, EKS, Add-on은 수동 구성과 운영 문서화를 병행
- CodeBuild는 신규 서비스가 생길 때마다 반복 생성과 수정이 필요해 Terraform으로 모듈화

즉, IaC 적용 범위도 "반복 변경 비용이 큰 영역부터 우선 자동화한다"는 기준으로 선택했습니다.

따라서 이 문서에서 설명하는 네트워크와 클러스터 구조는 "실제로 운영했던 구조"를 뜻하지만, 그 구조 전체를 Terraform으로 구축했다는 뜻은 아닙니다. 실무에서 Terraform으로 직접 관리한 부분은 주로 CodeBuild였습니다.

---

### 6. OIDC / IRSA 기반 권한 분리

AWS Load Balancer Controller, Cluster Autoscaler 등 Kubernetes Add-on에는 OIDC / IRSA를 적용해 서비스 계정 단위로 AWS 권한을 분리했습니다.

#### 이유

- Node IAM Role에 권한을 몰아주지 않기 위함
- 필요한 컴포넌트에만 최소 권한 부여
- 운영 보안성 향상

#### 적용 대상 예시

- AWS Load Balancer Controller
- Cluster Autoscaler

---

### 7. Cluster Autoscaler 기반 확장성 확보

트래픽 변동과 스케줄링 요구에 대응하기 위해 Cluster Autoscaler를 적용했습니다.

#### 목적

- 필요한 시점에 Node Scale Out
- 유휴 상태 시 Scale In
- 운영자의 수동 개입 최소화

#### 보완 요소

- Metrics Server 연계
- HPA 활용 기반 마련
- Node Group 태그 기반 자동 감지

---

### 8. Security Group 기반 데이터 계층 접근 제어

Aurora와 Redis는 모든 Worker Node에 일괄 개방하지 않고, 필요한 Node Group만 접근 가능하도록 Security Group을 분리해 운영했습니다.

#### 이유

- 서비스별 데이터 접근 범위 분리
- 장애 또는 보안 이슈 시 영향 범위 축소
- 운영 정책 관리 용이

#### 예시

- backend 성격의 워크로드만 Redis 접근 허용
- 필요한 서비스만 데이터 계층 접근 가능

---

### 9. Bastion 중심 운영 접근

Private 리소스 운영 접근은 Bastion Host를 통해 일원화했습니다.

#### 이유

- Private 리소스 직접 노출 방지
- 운영 접근 경로 명확화
- 제한된 운영 접근 정책 적용 가능

#### 향후 개선 가능성

- SSM Session Manager 기반 구조로 확장 가능

---

### 10. CloudWatch 중심 운영 모니터링

로그와 메트릭은 우선 CloudWatch Logs / Metrics를 중심으로 구성했습니다.

#### 이유

- AWS 관리형 서비스 기반으로 빠른 적용 가능
- 운영 복잡도 낮춤
- EKS 운영 초기 단계에서 실용적

#### 향후 확장 고려

- Prometheus
- Grafana
- Loki / Promtail

---

## What Makes This Architecture Practical

이 구조의 장점은 “완벽하게 이상적인 구조”라서가 아니라, 실제 서비스 운영에 필요한 요소를 우선순위에 맞게 현실적으로 구성했다는 점입니다.

예를 들면:

- Terraform과 수동 구성을 병행
- CloudWatch를 우선 사용
- IRSA는 핵심 컴포넌트 중심으로 우선 적용
- Bastion 기반 운영 접근 사용
- CloudFront + WAF로 엣지 구간 접근 제어 적용
- 구축 및 운영 기준을 문서화해 재사용 가능하도록 정리

즉, 이 아키텍처는 실무에서 자주 필요한 현실적인 트레이드오프와 운영 기준을 반영한 구조입니다.

---

## Outcome

이 아키텍처를 통해 다음과 같은 결과를 얻었습니다.

- EKS 기반 멀티 AZ 운영 구조 확보
- Public / Private / Data 계층 분리
- GitOps 기반 배포 구조 정착
- CloudFront + AWS WAF 기반 외부 접근 제어 운영
- 오토스케일링 기반 확장성 확보
- 서비스 계정 권한 분리 적용
- 데이터 계층 접근 제어 강화
- 구축 및 운영 절차 문서화를 통한 반복 가능성 확보

---

## Related Documents

- [Network Design](network-design.md)
- [Security and Access](security-and-access.md)
- [Scaling and Operations](scaling-and-operations.md)
- [Pipeline Overview](../cicd/pipeline-overview.md)
- [EKS Setup Summary](../docs/eks-setup-summary.md)
