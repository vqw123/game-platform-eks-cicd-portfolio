# ArgoCD Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 ArgoCD 설정 예시를 담고 있습니다.

실제 운영에서는 환경별 values 조정, OAuth, RBAC, ALB Ingress, ApplicationSet 기반 서비스 묶음 관리까지 함께 사용했습니다. 이 샘플은 그중 외부에 보여줄 수 있는 핵심 구조만 남긴 예시입니다.

## Included Files

- values.yaml
- application.yaml

## What This Sample Shows

- ArgoCD Helm values 구조
- ALB Ingress 기반 접근 예시
- GitHub OAuth / Dex placeholder 설정
- RBAC 기본 예시
- Application 리소스를 통한 GitOps 배포 예시
- 운영 도구로서 ArgoCD를 별도 admin 계열 노드에 배치하는 예시

## How This Relates To The Real Setup

- `values.yaml`
  - ArgoCD 서버 접근 방식, RBAC, Dex, Ingress 정책의 축약본
- `application.yaml`
  - Manifest Repository의 특정 경로를 동기화하는 기본 Application 예시

실제 환경에서는 서비스 수가 많아지면서 ApplicationSet을 사용해 환경별 경로 목록을 관리했습니다.

## Notes

- 실제 도메인, ARN, OAuth 정보는 placeholder 처리했습니다.
- 실제 운영 환경에서는 환경별 values 파일을 별도로 분리할 수 있습니다.
- 공개용 샘플에서는 민감 정보와 세부 인증 정책을 단순화했습니다.
