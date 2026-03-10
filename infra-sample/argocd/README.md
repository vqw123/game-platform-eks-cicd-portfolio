# ArgoCD Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 ArgoCD 설정 예시를 담고 있습니다.

## Included Files

- values.yaml
- application.yaml

## What This Sample Shows

- ArgoCD Helm values 구조
- ALB Ingress 기반 접근 예시
- GitHub OAuth / Dex placeholder 설정
- RBAC 기본 예시
- Application 리소스를 통한 GitOps 배포 예시

## Notes

- 실제 도메인, ARN, OAuth 정보는 placeholder 처리했습니다.
- 실제 운영 환경에서는 환경별 values 파일을 별도로 분리할 수 있습니다.