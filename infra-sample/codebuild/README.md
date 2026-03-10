# CodeBuild Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 CodeBuild 예시를 담고 있습니다.

실무에서는 서비스별로 CodeBuild 프로젝트를 분리하고, 각 프로젝트가 서로 다른 Source Repository, buildspec, branch, 이미지 이름, Manifest 경로를 사용했습니다. 이 영역이 실제로 Terraform을 적용했던 핵심 영역이었고, 이 샘플은 그 패턴을 설명하기 위한 단일 예시입니다.

## Included Files

- provider.tf
- versions.tf
- variables.tf
- main.tf
- terraform.tfvars.example
- buildspec.yml
- modules/codebuild/main.tf
- modules/codebuild/variables.tf

## What This Sample Shows

- 실제 운영에서 사용한 CodeBuild Terraform 모듈 패턴
- 환경별 공통 VPC / Subnet / Security Group / IAM Role 주입 방식
- 서비스별 CodeBuild 프로젝트를 `for_each`와 map 변수로 관리하는 방식
- Docker 이미지 빌드
- Amazon ECR Push
- Manifest Repository 업데이트
- GitOps 기반 배포 흐름 연결 예시
- `deployment.yaml`의 이미지 경로를 갱신해 ArgoCD 배포를 유도하는 방식

## How This Relates To The Real Setup

실제 운영에서는 Terraform이 CodeBuild 프로젝트와 GitHub webhook을 환경별로 생성했고, 각 프로젝트는 대체로 아래 값을 달리 가져갔습니다.

- Source Repository URL
- Source Branch
- ECR Repository 이름
- 이미지 이름과 태그 규칙
- Manifest Repository 내 `deployment.yaml` 경로

이 디렉토리에는 두 가지 예시가 함께 있습니다.

- `buildspec.yml`
  - 한 서비스 단위의 CI 동작 예시
- `*.tf`, `modules/codebuild/*`
  - 실제 실무에서 관리했던 CodeBuild Terraform 패턴을 placeholder 처리한 공개용 예시

이렇게 정리한 이유는 다음과 같습니다.

- VPC나 EKS는 한 번 구축한 뒤 변경 빈도가 상대적으로 낮았음
- 반면 CodeBuild는 앱이 추가될 때마다 거의 같은 형태의 프로젝트를 계속 만들어야 했음
- 수동 생성으로는 환경별 설정 차이와 Manifest 경로 관리가 번거로웠음

그래서 실제 IaC 적용은 "모든 인프라 일괄 Terraform화"보다 "반복 작업이 많은 CI 리소스 우선 모듈화"에 가까웠습니다.

즉, 실무 기준으로 보면 이 디렉토리가 Terraform 경험을 가장 직접적으로 설명하는 샘플입니다.

## Notes

- 실제 운영 환경에서는 Git 인증 방식, 환경 변수 관리, 권한 정책 등을 별도로 구성해야 합니다.
- 공개용 포트폴리오 예시이므로 민감한 값은 모두 placeholder 처리했습니다.
- 실제 환경에서는 서비스별 빌드 프로젝트가 다수 존재했고, Terraform 변수 파일에서 이를 일괄 관리했습니다.
