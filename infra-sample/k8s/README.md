# Kubernetes Manifest Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 Kubernetes 리소스 예시를 담고 있습니다.

## Included Files

- namespace.yaml
- deployment.yaml
- service.yaml
- ingress.yaml
- hpa.yaml

## What This Sample Shows

- 기본 Namespace 구성
- Deployment / Service / Ingress / HPA 구조
- ALB Ingress Controller 기반 Ingress 예시
- Backend 워크로드 배포 예시
- HPA 기반 확장 예시

## Notes

- 실제 운영 환경에 맞춰 Secret, ConfigMap, Affinity, Toleration 등을 추가로 확장할 수 있습니다.
- 공개용 예시이므로 값은 placeholder로 대체했습니다.