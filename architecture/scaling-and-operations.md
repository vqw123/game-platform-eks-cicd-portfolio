# Scaling and Operations

## Overview

이 문서는 AWS EKS 기반 서비스 운영 환경에서 적용한 확장성 구성과 운영 방식에 대해 설명합니다.

이 프로젝트의 운영 목표는 다음과 같았습니다.

- 트래픽 변동에 유연하게 대응할 수 있는 구조 확보
- 수동 개입을 줄이고 운영 효율 향상
- 클러스터 및 애플리케이션 상태를 관찰할 수 있는 최소한의 모니터링 체계 확보
- 운영 절차를 문서화하여 반복 가능한 기준 정리

이 구조는 완벽한 플랫폼 운영 체계보다는, 실제 서비스 운영에 필요한 확장성과 관측성을 우선 확보하는 방향으로 설계했습니다.

---

## Cluster Autoscaler

### Why Cluster Autoscaler

Kubernetes 환경에서는 Pod가 증가해도 이를 수용할 Node 리소스가 부족하면 실제 서비스 확장이 제한됩니다.

이 프로젝트에서는 이러한 문제를 해결하기 위해 Cluster Autoscaler를 적용했습니다.

#### 목적

- 스케줄링 불가능한 Pod 발생 시 Node 자동 확장
- 유휴 상태 Node 자동 축소
- 운영자의 수동 Scale 작업 감소
- 트래픽 변화에 대한 유연한 대응

### Applied Strategy

Cluster Autoscaler는 태그 기반 Node Group 자동 감지 방식을 사용했습니다.

#### 적용 포인트

- Auto-discovery tag 설정
- OIDC / IRSA 기반 권한 부여
- 유사한 Node Group 간 균형 고려
- Amazon Linux Worker Node 기준 설정 반영

#### 운영 시 고려한 옵션 예시

- `balance-similar-node-groups=true`
- `safe-to-evict=false`
- Node Group auto discovery tag 사용

### Expected Benefits

Cluster Autoscaler 적용을 통해 기대한 효과는 다음과 같습니다.

- 트래픽 증가 시 수동 개입 없이 Node 확장 가능
- 필요하지 않은 리소스는 줄여 운영 효율 개선
- 환경별 Node Group 운영 정책 유지 가능
- 멀티 AZ 기반 구조와 함께 확장성 확보

---

## Metrics Server

### Why Metrics Server

Pod 수준 확장(HPA)을 활용하려면 CPU / Memory 등 기본 리소스 메트릭 수집이 필요합니다.

이 프로젝트에서는 Metrics Server를 통해 기본 메트릭 수집 구조를 갖췄습니다.

#### 목적

- HPA 활용 기반 마련
- 클러스터 리소스 상태 확인
- 운영 시 기본적인 Pod / Node 상태 파악

#### 기대 효과

- Pod 레벨 스케일링과 연계 가능
- 운영 중 리소스 병목 파악 용이
- Auto Scaling 구성의 기초 체계 확보

---

## Monitoring Strategy

### CloudWatch 중심 운영

초기 운영 단계에서는 CloudWatch Logs / Metrics를 중심으로 모니터링을 구성했습니다.

#### 수집 대상 예시

- EKS 관련 로그
- 애플리케이션 로그
- 기본 인프라 메트릭
- 클러스터 운영 상태

#### 이유

- AWS 관리형 서비스 기반으로 빠르게 적용 가능
- 별도 모니터링 스택 구성 비용과 운영 부담이 낮음
- 실제 운영 초기 단계에서 가장 현실적인 선택지

### Why Not Full Observability Stack First

Prometheus, Grafana, Loki, Promtail 같은 스택은 확장성이 뛰어나지만, 초기부터 적용하면 운영 복잡도가 증가합니다.

이 프로젝트에서는 우선 서비스 운영 가능한 수준의 관측성 확보를 먼저 목표로 잡았습니다.

#### 선택 이유

- 초기 운영 안정화 우선
- 관리형 서비스 우선 활용
- 구축 및 운영 복잡도 최소화
- 이후 필요 시 확장 가능한 구조 유지

---

## Operational Documentation

### Why Documentation Matters

운영 경험에서 중요한 점 중 하나는 한 번 구축했다보다, 다시 같은 품질로 반복할 수 있는가였습니다.

이 프로젝트에서는 구축 및 운영 절차를 문서화해 운영 기준을 정리했습니다.

#### 문서화 대상 예시

- EKS 구축 사전 준비
- IAM Role / Worker Node Role 생성
- OIDC / IRSA 적용 절차
- AWS Load Balancer Controller 설치
- Cluster Autoscaler 설치
- Metrics Server 적용
- aws-auth 권한 추가
- Local kubeconfig 구성
- 운영 접근 및 기본 점검 절차

#### 효과

- 신규 환경 구축 시 반복 가능성 확보
- 운영 지식의 개인 의존도 완화
- 변경 작업 및 장애 대응 기준 확보
- 팀 단위 재사용성 향상

---

## Operational Trade-offs

### Practical Choices

이 운영 구조는 이상적인 플랫폼 운영 체계를 한 번에 완성하기보다, 실제 서비스 운영에 필요한 요소부터 확보하는 방향으로 구성했습니다.

#### 선택한 방향

- 완전한 IaC보다 필요한 영역 우선 정리
- 완전한 관측성 스택보다 CloudWatch 우선 적용
- 운영 접근은 Bastion 기반으로 우선 정리
- Cluster Autoscaler와 Metrics Server를 통한 기본 확장 체계 먼저 구성

#### 의미

실제 서비스 운영에서는 기술적 완성도만큼 운영 가능성과 적용 속도가 중요합니다.  
이 구조는 그런 현실적인 운영 판단을 반영한 결과입니다.

---

## Future Improvements

향후 보완하고 싶은 운영 항목은 다음과 같습니다.

- Prometheus / Grafana / Loki 기반 관측성 고도화
- Alerting 정책 정교화
- Terraform 관리 범위 확대
- 운영 접근 방식 고도화 (예: SSM Session Manager)
- 서비스 단위 세밀한 보안 정책 강화
- 배포 정책 및 롤백 전략 고도화

---

## Outcome

이 확장성과 운영 구조를 통해 다음과 같은 결과를 확보했습니다.

- EKS 기반 확장형 운영 구조 마련
- Cluster Autoscaler 기반 Node 확장 및 축소 가능
- Metrics Server 기반 HPA 활용 기반 마련
- CloudWatch 중심 모니터링 체계 확보
- 구축 및 운영 절차 문서화를 통한 반복 가능성 확보
- 운영자의 수동 개입을 줄이는 방향의 구조 정리