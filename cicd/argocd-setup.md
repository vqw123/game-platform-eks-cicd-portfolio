# ArgoCD Setup

## Overview

ArgoCD는 GitOps 방식의 CD 도구로 사용했습니다.

이 프로젝트에서는 ArgoCD를 단순 설치하는 데 그치지 않고, Manifest Repository를 기준으로 환경별 리소스를 동기화하는 운영 도구로 사용했습니다. 핵심은 "소스 코드 저장소"와 "배포 정의 저장소"를 분리한 뒤, ArgoCD가 후자를 기준으로 클러스터 상태를 맞추도록 한 점입니다.

## Why ArgoCD

ArgoCD를 선택한 이유는 다음과 같습니다.

- Manifest Repository를 기준으로 배포 상태를 선언적으로 관리할 수 있음
- `dev / qa / prod` 환경을 분리해 운영하기 쉬움
- 수동 `kubectl apply` 중심 배포보다 변경 이력과 배포 기준이 명확함
- 운영자가 현재 Git 상태와 클러스터 상태의 차이를 빠르게 확인할 수 있음

## How It Fit Into The Pipeline

이 프로젝트의 배포 흐름은 다음과 같았습니다.

1. 개발자가 Source Repository에 코드를 Push하거나 PR을 Merge
2. GitHub Webhook으로 CodeBuild 실행
3. CodeBuild가 이미지를 빌드하고 ECR에 Push
4. CodeBuild가 Manifest Repository의 `deployment.yaml` 이미지 경로 또는 태그를 갱신
5. ArgoCD가 Manifest Repository 변경을 감지하고 클러스터에 동기화

즉, ArgoCD는 빌드 도구가 아니라 "Manifest를 기준으로 실제 배포를 수행하는 CD 계층"이었습니다.

## Manifest Structure

ArgoCD가 바라보는 Manifest Repository는 `${STAGE}/${PRODUCT}` 구조를 기준으로 정리했습니다.

예시:

```text
dev/
  common/
    base-configs/
  ezplay/
    backend/
    auth/
    cms/
  tnmt/
    backend/
    game/
```

이 구조를 통해 환경, 제품군, 서비스 단위를 분리해서 관리했고, Application 또는 ApplicationSet이 특정 경로를 기준으로 리소스를 동기화하도록 구성했습니다.

## ApplicationSet Usage

실제 운영에서는 환경별 서비스 묶음을 관리하기 위해 ApplicationSet을 사용했습니다.

적용 의도:

- 공통 리소스와 서비스 리소스를 경로 기준으로 분리
- 신규 서비스 추가 시 경로만 추가해 배포 단위를 확장
- 환경별로 같은 구조를 유지해 운영 복잡도를 낮춤

이 방식은 이전 실무 저장소의 `dev/common/...`, `dev/ezplay/...`, `dev/tnmt/...` 구조와 직접 연결됩니다.

## Values Customization Points

ArgoCD는 Helm values를 기본값 그대로 쓰지 않고, 운영 환경에 맞게 일부 항목을 조정했습니다.

주요 포인트는 다음과 같습니다.

- `global.domain`
  - 환경별 ArgoCD 도메인 분리
- `global.nodeAffinity`
  - ArgoCD 컴포넌트가 특정 성격의 Node에만 스케줄링되도록 제어
- `config.cm.server.rbac.log.enforce.enable`
  - 권한 거부 이벤트 등 운영 로그 확인 목적
- `config.cm.exec.enabled`
  - Web UI를 통한 컨테이너 exec 허용 여부 제어
- `config.cm.dex.config`
  - GitHub OAuth 기반 로그인 연동
- `config.rbac.policy.default`, `config.rbac.policy.csv`
  - 읽기/쓰기 권한을 역할별로 분리
- `server.ingress`
  - ALB Ingress 노출, 인증 헤더, TLS, 도메인 연결 등 운영 접근 정책 반영

## Ingress and Access Strategy

ArgoCD 서버는 외부 접근이 필요한 운영 도구였기 때문에 Ingress 구성을 신중하게 다뤘습니다.

핵심 기준은 다음과 같습니다.

- AWS Load Balancer Controller 기반 ALB Ingress 사용
- TLS 적용
- 환경별 도메인 분리
- 헤더 기반 제한이나 OAuth를 통한 접근 통제 고려
- 내부 운영 도구이므로 공개 서비스와 같은 수준으로 노출 범위를 제한

즉, ArgoCD도 "그냥 띄우는 서비스"가 아니라 운영 접근 제어 대상이라는 관점으로 관리했습니다.

## Example Install

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd
helm install argocd argo/argo-cd -n argocd -f values.yaml
```

## Operational Notes

- 설치 자체보다 values.yaml 커스터마이징이 더 중요했습니다.
- OAuth, RBAC, Ingress, NodeAffinity는 운영 정책에 따라 달라질 수 있어 환경별로 검토가 필요했습니다.
- ArgoCD를 도입한 뒤에는 배포 정의를 Git으로 관리하는 흐름이 명확해져, 수동 배포보다 변경 이력과 추적성이 좋아졌습니다.
