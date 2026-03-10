# Game Platform EKS & CI/CD Portfolio

AWS EKS 기반으로 게임 및 백엔드 서비스를 운영하기 위한 인프라와 CI/CD 환경을 설계·구축하고, 이를 반복 가능한 형태로 문서화한 포트폴리오입니다.

이 프로젝트는 단순히 Kubernetes 클러스터를 생성하는 수준을 넘어서, 실제 서비스 운영을 고려한 네트워크 분리, 접근 제어, GitOps 기반 배포 구조, 오토스케일링, 서비스 계정 권한 분리, 로그 및 메트릭 수집 체계를 함께 구성한 경험을 정리한 것입니다.

또한 `dev / qa / prod` 환경을 분리하여 운영할 수 있도록 구성했고, `CodeBuild`, `ECR`, `ArgoCD`를 연계해 이미지 빌드부터 배포까지의 흐름을 표준화했습니다.

> 이 저장소는 실제 운영 경험을 바탕으로 외부 공개용으로 재구성한 포트폴리오입니다.  
> 계정 정보, ARN, 도메인, OAuth Secret, 내부 저장소 주소 등 민감 정보는 모두 placeholder로 대체했습니다.

---

## Why This Portfolio

백엔드 개발자로서 서비스 기능 구현뿐 아니라, 실제 운영 가능한 구조를 만들고 유지하는 과정까지 경험했습니다.

이 포트폴리오는 다음과 같은 역량을 보여주기 위해 구성했습니다.

- AWS EKS 기반 서비스 운영 구조 설계
- 멀티 AZ / Public-Private 네트워크 분리
- GitOps 기반 CI/CD 자동화
- Kubernetes Add-on 권한 분리(IRSA)
- Cluster Autoscaler 기반 확장성 확보
- 접근 제어 및 데이터 계층 보안 구성
- 운영 절차 문서화 및 표준화

즉, 단순히 “배포해봤다”가 아니라 운영 가능한 서비스 플랫폼을 구성하고 개선해 본 경험을 정리한 포트폴리오입니다.

---

## My Role

이 프로젝트에서 담당한 역할은 다음과 같습니다.

- AWS EKS 기반 인프라 구조 설계 및 운영
- VPC, Subnet, NAT Gateway, Route Table 등 네트워크 구성
- EKS Cluster 및 Managed Node Group 구성
- ALB Ingress Controller, OIDC, IRSA, Cluster Autoscaler 설정
- CodeBuild, ECR, ArgoCD 기반 CI/CD 파이프라인 구축
- Aurora / Redis 접근 제어 및 Security Group 설계
- CloudWatch Logs / Metrics 기반 운영 로그 및 지표 수집
- 구축 절차 및 운영 기준 문서화

---

## Key Highlights

### 1. EKS 기반 운영 구조 설계

- AWS EKS 기반 멀티 AZ 클러스터 운영
- Worker Node는 Private Subnet에 배치
- Public / Private / Data 계층 분리
- NAT Gateway 기반 아웃바운드 통신 구조 구성

### 2. GitOps 기반 CI/CD 구축

- GitHub Source Repository와 Manifest Repository 분리
- AWS CodeBuild로 Docker 이미지 빌드 및 ECR Push
- ArgoCD가 Manifest Repository를 polling 하여 배포 수행
- 환경별(dev / qa / prod) 배포 구조 표준화

### 3. 운영 접근 제어 및 보안 고려

- Bastion Host 기반 Private 접근
- Aurora / Redis Security Group 분리
- 필요한 Worker Node만 데이터 계층 접근 허용
- OIDC / IRSA로 Add-on 권한 분리

### 4. 확장성과 운영 효율 확보

- Cluster Autoscaler 적용
- Metrics Server 기반 HPA 활용
- CloudWatch Logs / Metrics 기반 기본 운영 모니터링 구성
- 구축 및 운영 절차를 문서화해 반복 가능한 운영 기준 정리

---

## Repository Structure

    game-platform-eks-cicd-portfolio/
    ├── README.md
    ├── architecture/
    │   ├── architecture-overview.md
    │   ├── network-design.md
    │   ├── security-and-access.md
    │   └── scaling-and-operations.md
    ├── cicd/
    │   ├── pipeline-overview.md
    │   ├── manifest-repository-strategy.md
    │   └── argocd-setup.md
    ├── infra-sample/
    │   ├── terraform/
    │   ├── argocd/
    │   ├── k8s/
    │   └── codebuild/
    └── docs/
        ├── eks-setup-summary.md
        ├── oidc-irsa-summary.md
        ├── autoscaler-summary.md
        └── monitoring-summary.md

---

## Document Guide

### architecture/

서비스 운영 구조를 어떤 원칙으로 설계했는지 설명합니다.

- `architecture-overview.md`
  - 전체 아키텍처와 설계 핵심 요약
- `network-design.md`
  - VPC / Subnet / NAT / Route Table 중심 네트워크 설계
- `security-and-access.md`
  - Bastion, Security Group, OIDC / IRSA 기반 접근 및 권한 전략
- `scaling-and-operations.md`
  - Cluster Autoscaler, Metrics Server, CloudWatch 기반 운영 및 확장 전략

### cicd/

배포 흐름과 GitOps 운영 전략을 설명합니다.

- `pipeline-overview.md`
  - GitHub → CodeBuild → ECR → ArgoCD → Kubernetes 흐름 설명
- `manifest-repository-strategy.md`
  - `${STAGE}/${PRODUCT}` 구조 기반 Manifest Repository 전략 설명
- `argocd-setup.md`
  - ArgoCD 설치 및 운영 구조 요약

### docs/

구축 및 운영 경험을 요약한 문서입니다.

- `eks-setup-summary.md`
- `oidc-irsa-summary.md`
- `autoscaler-summary.md`
- `monitoring-summary.md`

### infra-sample/

공개용 예시 파일 모음입니다.

- `terraform/`
  - 인프라 샘플 코드
- `argocd/`
  - ArgoCD 설정 예시
- `k8s/`
  - Kubernetes Manifest 예시
- `codebuild/`
  - BuildSpec 예시

---

## Technical Decisions

이 프로젝트는 이상적인 구조를 100% 완성하는 것보다, 실제 서비스 운영에 필요한 구조를 먼저 확보하고 점진적으로 정리하는 방향으로 진행했습니다.

### Terraform + Manual Configuration 병행

모든 리소스를 완전히 IaC로 관리하지는 않았습니다.  
Terraform과 수동 구성을 병행하며, 운영 일정과 우선순위에 맞춰 실서비스에 필요한 구조를 먼저 확보했습니다.

### CloudWatch 중심 운영

초기 운영 단계에서는 CloudWatch Logs / Metrics를 중심으로 로그와 메트릭을 수집했습니다.  
Prometheus / Grafana / Loki 같은 확장형 스택은 이후 고도화 여지로 남겨 두었습니다.

### Bastion 기반 접근

Private 리소스 접근은 Bastion을 통해 일원화했습니다.  
보안과 운영 편의성 사이에서 현실적인 접근 방식을 선택한 케이스입니다.

### IRSA의 점진적 적용

모든 서비스에 완벽히 적용하기보다, AWS Load Balancer Controller와 Cluster Autoscaler 같은 핵심 컴포넌트 중심으로 우선 적용했습니다.

---

## Outcomes

이 프로젝트를 통해 다음과 같은 결과를 얻었습니다.

- EKS 기반 멀티 AZ 운영 구조 확보
- Public / Private / Data 계층 분리
- ALB Ingress Controller + CloudFront 연계 서비스 운영
- CodeBuild + ECR + ArgoCD 기반 GitOps 배포 자동화
- IRSA와 Cluster Autoscaler 기반 운영 효율 개선
- 환경별(dev / qa / prod) 배포 구조 표준화
- 구축 및 운영 절차 문서화를 통한 반복 가능성 확보

---

## What I Learned

이 프로젝트를 통해 단순히 Kubernetes를 사용하는 수준을 넘어, 실제 서비스 운영에 필요한 인프라 설계와 운영 기준이 무엇인지 더 깊이 이해할 수 있었습니다.

특히 다음과 같은 부분을 실무적으로 학습했습니다.

- Private 중심 클러스터 운영 구조
- 네트워크 및 Security Group 분리 전략
- Kubernetes Add-on의 IAM 권한 분리 방식
- GitOps 기반 배포 체계 운영
- 환경 분리와 운영 표준화의 중요성
- 운영 문서화의 가치

또한 완벽한 이상적 구조보다, 서비스 상황에 맞는 현실적인 트레이드오프를 선택하는 것이 중요하다는 점도 경험했습니다.

---

## Future Improvements

향후 보완하고 싶은 부분은 다음과 같습니다.

- Terraform 관리 범위 확대
- Secrets Manager / External Secrets 기반 민감 정보 관리 고도화
- Prometheus / Grafana / Loki 기반 관측성 스택 적용
- SSM Session Manager 기반 접근 방식 검토
- SG for Pods 등 더 정교한 서비스 단위 접근 제어
- 배포 정책 및 롤백 전략 정교화

---

## Quick Links

- [Architecture Overview](architecture/architecture-overview.md)
- [Network Design](architecture/network-design.md)
- [Security and Access](architecture/security-and-access.md)
- [Scaling and Operations](architecture/scaling-and-operations.md)
- [Pipeline Overview](cicd/pipeline-overview.md)
- [Manifest Repository Strategy](cicd/manifest-repository-strategy.md)
- [ArgoCD Setup](cicd/argocd-setup.md)
- [EKS Setup Summary](docs/eks-setup-summary.md)
- [OIDC / IRSA Summary](docs/oidc-irsa-summary.md)
- [Autoscaler Summary](docs/autoscaler-summary.md)
- [Monitoring Summary](docs/monitoring-summary.md)

---

## Notes for Public Release

공개 전 아래 항목은 반드시 제거 또는 마스킹해야 합니다.

- AWS Account ID
- ARN
- 실제 도메인
- OAuth Client ID / Client Secret
- Office IP
- PEM Key 관련 상세
- Terraform State 파일
- `.git` 폴더
- 내부 저장소 주소
- 실제 서비스 이름 및 민감 정보

placeholder 예시:

- `<AWS_ACCOUNT_ID>`
- `<OIDC_ID>`
- `<DOMAIN>`
- `<CERTIFICATE_ARN>`
- `<CLIENT_ID>`
- `<CLIENT_SECRET>`