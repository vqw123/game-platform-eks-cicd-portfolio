# Autoscaler Summary

## Overview

이 문서는 AWS EKS 환경에서 Cluster Autoscaler를 적용한 이유와 운영 방식을 요약한 문서입니다.

Kubernetes 환경에서는 Pod 수요가 증가해도 이를 수용할 Worker Node 리소스가 부족하면 실제 서비스 확장이 제한됩니다.  
이 프로젝트에서는 이러한 문제를 해결하기 위해 Cluster Autoscaler를 구성했습니다.

핵심 목표는 다음과 같았습니다.

- 트래픽 증가 시 Node 자동 확장
- 유휴 상태 자원 자동 축소
- 운영자의 수동 Scale 작업 감소
- 환경별 Node Group 운영 기준 유지
- 멀티 AZ 환경에서 확장성 확보

---

## Why Cluster Autoscaler

애플리케이션은 HPA 등을 통해 Pod를 늘릴 수 있어도, 클러스터 자체에 남는 Node 자원이 없으면 실제 스케줄링은 실패할 수 있습니다.

Cluster Autoscaler는 이런 상황에서 다음 역할을 수행합니다.

- 스케줄링 불가능한 Pod 발생 시 Node Scale Out
- 유휴 Node 발생 시 Scale In
- Auto Scaling Group을 기반으로 Node Group 크기 조정

즉, Pod 확장과 Node 확장 사이의 연결 고리를 담당합니다.

---

## Main Use Cases

### 1. 트래픽 증가 시 자원 부족 대응

서비스 부하가 증가해 Pod가 늘어나야 할 때, Node가 부족한 경우 자동으로 확장할 수 있습니다.

### 2. 운영자의 수동 조정 감소

운영자가 직접 Node 수를 늘리거나 줄이는 작업을 반복하지 않아도 됩니다.

### 3. 환경별 운영 정책 유지

환경마다 다른 Node Group 구조를 유지하면서도 자동 확장이 가능해집니다.

---

## Applied Strategy

이 프로젝트에서는 태그 기반 자동 감지 방식을 사용했습니다.

### 핵심 구성 포인트

- Auto-discovery tag 설정
- OIDC / IRSA 기반 권한 부여
- 유사 Node Group 간 균형 고려
- Amazon Linux Worker Node 기준 설정 반영

### 운영 시 고려한 옵션 예시

- `balance-similar-node-groups=true`
- `safe-to-evict=false`
- `skip-nodes-with-system-pods=false`
- Auto Scaling Group tag 기반 Node Group 감지

### 실제 적용 이유

- Node Group이 여러 AZ에 걸쳐 있을 때 한쪽으로만 증설되지 않도록 `balance-similar-node-groups=true`를 사용했습니다.
- Autoscaler Pod가 있는 노드가 쉽게 축소 대상이 되지 않도록 `safe-to-evict=false`를 명시했습니다.
- `kube-system` Pod가 있다고 해서 무조건 축소가 막히지 않게 `skip-nodes-with-system-pods=false`를 사용했습니다.
- Amazon Linux Worker Node 기준으로 인증서 마운트 경로를 맞춰 YAML을 수정했습니다.

---

## Why IRSA Was Important Here

Cluster Autoscaler는 AWS Auto Scaling Group 관련 API를 호출해야 하기 때문에, 별도의 IAM 권한이 필요합니다.

이 프로젝트에서는 Node Role에 권한을 몰아주기보다 IRSA를 통해 Autoscaler 전용 권한을 분리했습니다.

### 기대 효과

- Autoscaler가 필요한 권한만 사용
- Node Role 과권한 방지
- 운영 보안성 향상
- 권한 문제 추적 용이

실제로는 Cluster Autoscaler가 Auto Scaling Group 크기를 직접 조정해야 했기 때문에, Node Role에 같은 권한을 넣는 것보다 Autoscaler 전용 Role로 분리하는 편이 훨씬 명확했습니다.

---

## Relationship with Metrics Server and HPA

Cluster Autoscaler는 Node 확장을 담당하고, HPA는 Pod 확장을 담당합니다.

### 역할 구분

- Metrics Server: 리소스 메트릭 수집
- HPA: Pod 수 조정
- Cluster Autoscaler: Node 수 조정

### 의미

이 세 가지가 함께 구성되어야, 실제 트래픽 증가 상황에서 애플리케이션과 클러스터가 함께 확장할 수 있습니다.

---

## Operational Considerations

Cluster Autoscaler 운영 시 중요하게 본 점은 다음과 같습니다.

### Node Group 태그 관리

Auto-discovery가 동작하려면 Node Group 또는 ASG 태그가 정확해야 합니다.

실제 기준:

- `k8s.io/cluster-autoscaler/enabled=true`
- `k8s.io/cluster-autoscaler/<CLUSTER_NAME>=owned`

### 시스템 Pod 처리

시스템 Pod가 올라간 Node를 어떻게 다룰지에 따라 Scale In 동작이 달라질 수 있습니다.

### 멀티 AZ 균형

유사한 Node Group이 여러 AZ에 걸쳐 있다면, 균형 있게 확장 및 축소되도록 고려해야 합니다.

### 권한 분리

Autoscaler가 AWS API를 호출할 수 있어야 하지만, 과도한 권한은 피해야 합니다.

### HPA와 분리해서 이해할 필요

HPA가 Pod를 늘려도 스케줄링 가능한 Node가 없으면 실제 확장은 실패합니다. 그래서 Metrics Server, HPA, Cluster Autoscaler를 하나의 흐름으로 같이 봐야 했습니다.

---

## Trade-offs

Cluster Autoscaler를 적용하면 운영 효율은 좋아지지만, 설정과 운영 시 고려해야 할 항목도 늘어납니다.

### 감수한 복잡도

- IRSA 구성 필요
- Auto-discovery tag 관리 필요
- Scale In / Scale Out 조건 이해 필요
- 시스템 Pod와의 관계 고려 필요

### 대신 얻은 것

- 수동 확장 작업 감소
- 트래픽 변화에 대한 유연한 대응
- 멀티 AZ 환경에서의 확장성 확보
- 운영 효율 향상

---

## Outcome

Cluster Autoscaler 구성을 통해 다음과 같은 기반을 확보했습니다.

- Node 자동 확장 및 축소 구조 마련
- 트래픽 변화에 유연한 클러스터 운영 가능
- 운영자의 수동 개입 감소
- IRSA 기반 권한 분리 적용
- HPA 및 Metrics Server와 연계 가능한 확장 기반 확보
- 멀티 AZ와 환경별 Node Group 구조를 유지하면서도 확장 정책을 표준화
