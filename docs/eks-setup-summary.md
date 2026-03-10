# EKS Setup Summary

## Overview

이 문서는 AWS EKS 클러스터를 구축하면서 정리한 핵심 절차와 운영 포인트를 공개용으로 재구성한 요약 문서입니다.

실제 구축은 단순히 클러스터를 생성하는 데 그치지 않고, 네트워크, IAM, 노드 그룹, 접근 제어, Add-on, 운영 환경 구성을 함께 고려하는 방향으로 진행했습니다. 포트폴리오에서는 콘솔 클릭 순서를 나열하기보다, 어떤 순서와 기준으로 운영 환경을 만들었는지에 집중해 정리했습니다.

핵심 목표는 다음과 같았습니다.

- 환경별(dev / qa / prod) 반복 가능한 구축 절차 정리
- EKS 운영에 필요한 기본 구성 요소 명확화
- 운영 중 필요한 Add-on 및 접근 정책 정리
- 신규 환경 구축 시 재사용 가능한 기준 문서 확보

---

## Setup Scope

이 문서에서 다루는 범위는 다음과 같습니다.

- VPC 및 Subnet 사전 준비
- IAM Cluster Role 생성
- EKS Cluster 생성
- Worker Node Role 생성
- Node Group 생성
- Security Group 설정
- OIDC / IRSA 관련 기초 설정
- 운영 Add-on 준비
- 로컬 접근 및 운영 점검 기반 구성

## Recommended Build Order

실제 구축은 대체로 아래 순서로 진행했습니다.

1. VPC, Subnet, NAT Gateway, Route Table 구성
2. EKS Cluster Role 준비 후 Cluster 생성
3. Worker Node Role 준비 후 Managed Node Group 생성
4. Cluster / Node / Data 계층 Security Group 정리
5. OIDC Provider 연결 및 IRSA 대상 Add-on 준비
6. AWS Load Balancer Controller, Cluster Autoscaler, Metrics Server 등 운영 Add-on 설치
7. `aws eks update-kubeconfig` 기반 운영 접근과 점검 절차 정리

이 순서를 유지한 이유는, EKS는 클러스터만 먼저 만들어도 운영 구성이 완성되지 않기 때문입니다. 특히 Private Node 중심 구조, 데이터 계층 접근 제어, Add-on 권한 분리는 앞 단계의 네트워크와 IAM 구성이 정리되어 있어야 안정적으로 이어집니다.

---

## 1. VPC and Network Preparation

EKS 클러스터는 먼저 네트워크 구성이 준비되어 있어야 안정적으로 운영할 수 있습니다.

### 확인 항목

- VPC의 DNS Hostnames 활성화
- VPC의 DNS Resolution 활성화
- DHCP Option 확인
- Public / Private Subnet 분리
- DB 계층용 Subnet 분리
- 멀티 AZ 기준 Subnet 구성
- Private Subnet에서 아웃바운드 가능한 NAT Gateway 구성

### 목적

- EKS Control Plane 및 Worker Node의 정상 동작 보장
- Private 기반 Worker Node 운영 구조 확보
- Aurora / Redis 같은 데이터 계층 분리 기반 확보
- 이후 ALB, NAT, Add-on 구성을 위한 네트워크 기반 마련

### 실제 운영 기준

- 최소 2개 이상의 AZ를 사용해 단일 AZ 장애 영향을 줄이도록 구성했습니다.
- Worker Node는 Public Subnet에 두지 않고 Private Subnet에 배치했습니다.
- 운영 접근은 Bastion을 통해 일원화하고, Pod의 외부 통신은 NAT Gateway를 통해 처리하는 구조를 선택했습니다.
- Aurora / Redis는 DB Subnet에 두고, Node Group 전체가 아니라 필요한 워크로드만 접근하도록 SG를 분리했습니다.

---

## 2. IAM Cluster Role

EKS Control Plane이 AWS 리소스를 관리할 수 있도록 IAM Cluster Role을 구성합니다.

### 주요 역할

- EKS Cluster 생성 시 Control Plane 권한 제공
- 클러스터 운영에 필요한 AWS API 접근 기반 제공

### 대표 연결 정책 예시

- `AmazonEKSClusterPolicy`
- `AmazonEKSServicePolicy`

### 운영 포인트

- 클러스터 생성 전 Role 준비 필요
- 환경별 클러스터 구조에 맞춰 네이밍 관리 필요

---

## 3. EKS Cluster Creation

Cluster 생성 단계에서는 단순 생성뿐 아니라, 네트워크와 로깅, Add-on 구성 여부까지 함께 고려해야 합니다.

### 주요 고려 사항

- 환경별 Cluster 분리
- 연결할 Subnet 선택
- Control Plane Logging 활성화 여부
- Kubernetes 버전 선택
- 기본 Add-on 구성

### 목적

- 환경별로 격리된 실행 환경 확보
- 운영 시 로그 추적 가능성 확보
- 이후 Worker Node 및 Add-on과 연계 가능한 기반 마련

### 실제 운영 포인트

- `dev / qa / prod`를 별도 클러스터로 분리해 환경 혼재를 피했습니다.
- 로그는 초기 운영 단계에서 CloudWatch 중심으로 수집해, 별도 관측 스택 없이도 기본 추적이 가능하도록 했습니다.
- Add-on은 한 번에 모두 올리기보다, Load Balancer Controller와 Autoscaler처럼 운영 필수도가 높은 항목부터 우선 적용했습니다.

---

## 4. Worker Node Role

Worker Node가 EKS 클러스터에 정상적으로 참여하고, 필요한 AWS 리소스와 통신할 수 있도록 IAM Role을 구성합니다.

### 주요 역할

- EKS Worker Node의 기본 동작 권한
- ECR 이미지 Pull 권한
- CNI 동작 관련 권한
- CloudWatch 연동 권한

### 대표 연결 정책 예시

- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2ContainerRegistryReadOnly`
- `AmazonEKS_CNI_Policy`
- CloudWatch 관련 정책

### 목적

- Worker Node가 클러스터에 정상 Join
- ECR에서 이미지 Pull 가능
- 네트워크 플러그인과 로깅 구성 가능

---

## 5. Node Group Creation

Node Group은 실제 서비스 워크로드가 실행되는 기반입니다.

### 주요 고려 사항

- Managed Node Group 사용
- 환경별 Node Group 분리
- 역할별 Node Group 운영 가능
- Auto Scaling 연계를 위한 태그 설정

### 예시 역할 분리

- game
- admin
- backend

### 목적

- 워크로드 성격에 맞는 실행 환경 구성
- 자원 분리 및 운영 정책 분리
- Autoscaler와 연계 가능한 확장 구조 확보

### 실제 운영 포인트

- Node Group은 워크로드 성격에 맞게 분리할 수 있도록 설계했습니다.
- Cluster Autoscaler가 자동으로 감지할 수 있도록 `k8s.io/cluster-autoscaler/enabled=true`, `k8s.io/cluster-autoscaler/<CLUSTER_NAME>=owned` 태그를 사용했습니다.
- 멀티 AZ에 걸친 Node Group 운영을 전제로 두어, 확장 시 특정 AZ로만 쏠리지 않도록 후속 Autoscaler 설정과 함께 보완했습니다.

---

## 6. Security Group Setup

EKS 운영에서는 Cluster, Worker Node, 데이터 계층별로 적절한 Security Group 설계가 중요합니다.

### 구성 대상 예시

- Cluster Security Group
- Worker Node Security Group
- Redis Security Group
- RDS Security Group

### 목적

- Kubernetes API 접근 허용
- 내부 노드 간 통신 유지
- Aurora / Redis 접근 범위 제한
- 운영 접근 경로 통제

### 운영 포인트

- 모든 Node Group에 데이터 계층을 일괄 개방하지 않음
- 필요한 서비스만 Redis 또는 RDS 접근 허용
- Bastion 경유 운영 접근 유지
- Cluster SG와 Node SG의 역할을 분리하고, Kubernetes API 호출에 필요한 경로만 열어 두도록 관리

### 실제 운영 기준

- Cluster SG는 Worker Node와 Pod가 Kubernetes API를 호출할 수 있는 경로를 중심으로 열었습니다.
- Node SG는 내부 통신과 운영 접근을 고려해 구성했지만, 데이터 계층 접근은 별도 Redis / RDS SG에서 다시 제한했습니다.
- 결과적으로 "클러스터 내부 통신은 허용하되, 데이터 접근은 서비스 성격별로 제한"하는 방향을 유지했습니다.

---

## 7. OIDC Provider Preparation

IRSA를 적용하려면 EKS Cluster에 대응하는 OIDC Provider 구성이 필요합니다.

### 목적

- Kubernetes Service Account에 IAM Role 연결 가능
- Node Role 과권한 방지
- Add-on 단위 권한 분리 가능

### 주 활용 대상

- AWS Load Balancer Controller
- Cluster Autoscaler

---

## 8. Add-on Preparation

실제 운영을 위해 다음과 같은 Add-on 구성을 함께 고려했습니다.

### 주요 항목

- AWS Load Balancer Controller
- Cluster Autoscaler
- Metrics Server
- EBS CSI Driver
- Kubernetes Dashboard

### 목적

- Ingress 기반 서비스 노출
- 클러스터 확장 자동화
- HPA 활용 기반 마련
- 스토리지 연동
- 운영 상태 확인

### 실제 운영 포인트

- AWS Load Balancer Controller는 ALB 기반 Ingress 운영을 위해 필수 Add-on으로 보았습니다.
- Cluster Autoscaler와 Metrics Server는 함께 구성해야 Pod 확장과 Node 확장이 실제로 이어질 수 있었습니다.
- EBS CSI Driver는 상태 저장 워크로드와 Kubernetes 버전 업데이트를 고려할 때 별도로 관리가 필요했습니다.
- Kubernetes Dashboard는 편의 도구로 활용했지만, 운영 핵심은 `kubectl`, ArgoCD, CloudWatch 쪽에 두었습니다.

---

## 9. Local Access and Operations

운영 및 점검을 위해 로컬 환경에서 kubeconfig를 구성하고 클러스터 접근을 가능하게 했습니다.

### 주요 작업

- AWS CLI 설정
- `aws eks update-kubeconfig`
- `kubectl` 기반 서비스 / Pod 점검
- Pod 내부 접근
- 서비스 FQDN 기반 내부 통신 확인

### 목적

- 운영자 접근 단순화
- 장애 대응 및 점검 기반 확보
- 클러스터 상태 확인 및 조작 가능

### 실제 운영 포인트

- 원칙적으로는 Bastion을 통한 접근을 염두에 두었지만, 운영 편의를 위해 로컬 환경에서 kubeconfig를 갱신해 사용하는 흐름도 병행했습니다.
- `kubectl get svc -A`, `kubectl exec`, 서비스 FQDN 기반 내부 호출 확인은 기본 점검 절차로 사용했습니다.
- EKS 권한은 `aws-auth` ConfigMap을 통해 운영 사용자에게 부여했고, 초기에는 네임스페이스별 세분화보다 운영 속도를 우선해 넓은 권한으로 시작했습니다.

---

## 10. Why This Documentation Matters

이 문서는 단순 구축 기록이 아니라, 다음 목적을 위해 정리되었습니다.

- 신규 환경 구축 시 반복 가능성 확보
- 운영 지식의 개인 의존도 완화
- 변경 작업 시 기준 절차 제공
- 팀 차원의 재사용 가능한 운영 기준 확보

---

## Outcome

이 문서를 통해 다음과 같은 기반을 확보했습니다.

- EKS 구축 절차 표준화
- 환경별 클러스터 구성 기준 정리
- IAM / Node / SG / Add-on 구성 흐름 정리
- 운영 접근 및 점검 기준 확보
- 신규 환경 구축 시 재사용 가능한 참고 문서 마련
- 단순 생성 절차가 아니라, 실제 운영 가능한 EKS 환경을 만들기 위한 판단 기준 정리
