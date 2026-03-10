# Terraform Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 Terraform 예시를 담고 있습니다.

중요한 점은, 이 디렉토리의 코드는 실제 운영에서 적용했던 Terraform 코드가 아니라는 것입니다. 실제 운영에서는 VPC, Subnet, NAT Gateway, EKS 같은 기반 인프라를 Terraform으로 관리하지 않았고, 공개용 포트폴리오에서 네트워크 구조를 설명하기 위해 별도로 재구성한 예시를 두었습니다.

실무에서 Terraform으로 실제 관리했던 핵심 영역은 `CodeBuild`였습니다. 서비스가 늘어날수록 반복 생성과 수정이 계속 필요했던 CodeBuild 프로젝트를 모듈과 변수 파일로 관리했고, 이 디렉토리의 네트워크 예시는 그와 별개의 공개용 아키텍처 샘플입니다.

## Included Files

- versions.tf
- provider.tf
- variables.tf
- main.tf

## What This Sample Shows

- VPC 생성
- Public / Private Subnet 구성
- Database Subnet 구성
- Internet Gateway 연결
- NAT Gateway 생성
- Route Table 구성
- Private Node 중심 EKS 운영을 위한 네트워크 기반 예시
- ALB / Internal Load Balancer 연계를 위한 subnet tag 예시
- Aurora / Redis 같은 데이터 계층 분리를 고려한 subnet tier 예시

## What This Sample Does Not Mean

- 실제 운영 VPC를 Terraform으로 구축했다는 뜻은 아님
- 실제 EKS 네트워크 구성을 그대로 export한 코드는 아님
- 실무 Terraform 범위가 네트워크까지 포함됐다는 의미는 아님

## How This Relates To The Architecture

이 샘플은 다음 설계 원칙을 코드로 보여주기 위한 것입니다.

- Public Subnet
  - ALB, NAT Gateway, Bastion 같은 외부 연계 리소스 배치 전제
- Private Subnet
  - EKS Worker Node와 애플리케이션 Pod 배치 전제
- Database Subnet
  - Aurora, Redis 같은 데이터 계층 분리 전제

실제 운영 환경에서는 이런 형태의 네트워크 위에 EKS Cluster, Managed Node Group, 보안 그룹 분리, OIDC / IRSA, ArgoCD, CodeBuild가 연결되었습니다. 다만 이 저장소의 Terraform 샘플은 "실무에서 Terraform으로 관리한 코드"가 아니라 "이런 구조로 운영했다는 점을 설명하기 위한 공개용 샘플" 성격이 더 강합니다.

## Notes

- 실제 운영값은 placeholder로 대체했습니다.
- Terraform state 파일은 공개 저장소에 포함하지 않습니다.
- 공개용 포트폴리오 예시이므로 일부 값과 구조는 단순화했습니다.
- 이 샘플은 네트워크 중심 예시이며, 전체 운영 구성을 완전히 재현하는 코드는 아닙니다.
- 실제 Terraform 실무 경험은 이 디렉토리보다 `infra-sample/codebuild` 쪽 설명이 더 직접적으로 대응됩니다.
