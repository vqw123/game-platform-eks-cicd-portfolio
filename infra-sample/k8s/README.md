# Kubernetes Manifest Sample

이 디렉토리는 공개용 포트폴리오에서 사용할 수 있는 Kubernetes 리소스 예시를 담고 있습니다.

실무에서 사용한 Manifest Repository는 `dev / qa / prod` 환경 분리와 서비스별 디렉토리 구조를 갖고 있었고, ArgoCD가 이를 기준으로 동기화했습니다. 이 디렉토리는 그 구조 전체를 복제한 것이 아니라, 서비스 단위 배포에 필요한 대표 리소스만 축약한 예시입니다.

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
- `nodeSelector`를 통한 워크로드 성격별 배치 예시
- CodeBuild가 갱신하는 이미지 경로와 ArgoCD가 동기화하는 Deployment 연결 예시

## How This Relates To The Manifest Repository

실제 운영에서는 아래와 같은 구조를 사용했습니다.

- `${STAGE}/${PRODUCT}/${SERVICE}`
- 예: `dev/tnmt/backend`, `qa/ezplay/auth`, `prod/common/base-configs`

이 샘플 파일들은 그중 한 서비스 디렉토리 안에 들어갈 `deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml`의 공개용 축약본에 해당합니다.

## Notes

- 실제 운영 환경에 맞춰 Secret, ConfigMap, Affinity, Toleration 등을 추가로 확장할 수 있습니다.
- 공개용 예시이므로 값은 placeholder로 대체했습니다.
- 실제 환경에서는 ingress 공통 설정, namespace 공통 리소스, 서비스별 환경 변수 분리가 별도 디렉토리에서 관리되었습니다.
