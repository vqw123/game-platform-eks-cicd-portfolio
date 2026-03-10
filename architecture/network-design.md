# Network Design

## Overview

이 문서는 AWS EKS 기반 서비스 운영을 위해 구성한 네트워크 설계 원칙과 구조를 설명합니다.

핵심 목표는 다음과 같습니다.

- 서비스 실행 환경과 외부 노출 구간 분리
- 데이터 계층 보호
- 멀티 AZ 기반 가용성 확보
- 운영 및 확장 시 네트워크 책임 범위 명확화

이 프로젝트에서는 단순히 VPC를 생성하는 수준을 넘어서, 실제 서비스 운영을 고려해 Public / Private / Data 계층을 분리하고, Worker Node를 Private Subnet에 배치하는 구조를 채택했습니다.

---

## VPC Design Principles

EKS 클러스터가 안정적으로 동작할 수 있도록 VPC는 최소 2개 이상의 가용 영역을 기준으로 구성했습니다.

### 설계 원칙

- RFC1918 기반 사설 IP 대역 사용
- 멀티 AZ 기반 Subnet 분산
- Public / Private Subnet 분리
- 리소스 역할별 네트워크 경계 명확화

### 기대 효과

- 단일 AZ 장애에 대한 리스크 완화
- 서비스 노출 구간과 내부 실행 환경 분리
- 운영 및 보안 정책 적용 범위 명확화

---

## Subnet Strategy

네트워크는 역할에 따라 크게 세 가지 계층으로 나누어 구성했습니다.

### Public Subnet

외부 통신 및 외부 노출이 필요한 리소스를 배치하는 계층입니다.

#### 주요 리소스

- NAT Gateway
- Application Load Balancer
- Bastion Host
- 외부와 직접 통신해야 하는 구성 요소

#### 역할

- 인터넷과 직접 연결되는 진입점 제공
- Private Subnet의 아웃바운드 통신 지원
- 제한된 운영 접근 경로 제공

### Private Subnet

실제 서비스가 실행되는 애플리케이션 계층입니다.

#### 주요 리소스

- EKS Worker Node
- Kubernetes Pod
- 내부 서비스 컴포넌트

#### 역할

- 외부 직접 노출 없이 서비스 실행
- 내부 통신 중심 구조 유지
- 데이터 계층 접근 시 필요한 경로만 허용

#### 왜 Private Subnet에 Worker Node를 배치했는가

Worker Node를 Public Subnet에 두면 관리가 단순해질 수는 있지만, 외부 노출 면에서 리스크가 커집니다.
이 프로젝트에서는 서비스 실행 환경을 보호하는 쪽에 우선순위를 두었기 때문에 Private Subnet 기반 구조를 선택했습니다.

### Data Layer

데이터 저장소는 애플리케이션 계층과 논리적으로 분리해 관리했습니다.

#### 주요 리소스

- Aurora
- Redis

#### 역할

- 서비스별 데이터 접근 경계 분리
- 데이터 계층 직접 노출 방지
- Security Group 기반 접근 제어 적용

---

## Internet Connectivity Design

인터넷 통신 구조는 외부 노출이 필요한 리소스와 내부 실행 리소스를 분리하는 방향으로 구성했습니다.

### Internet Gateway

Public Subnet이 인터넷과 직접 통신할 수 있도록 VPC에 Internet Gateway를 연결했습니다.

#### 역할

- ALB 등 외부 노출 리소스의 인바운드 및 아웃바운드 통신
- Bastion Host 등 운영 리소스의 외부 연결

### NAT Gateway

Private Subnet의 리소스가 외부 인터넷과 통신해야 하는 경우 NAT Gateway를 통해 아웃바운드 요청을 처리했습니다.

#### 필요한 이유

Private Subnet에 있는 Worker Node와 Pod도 외부와의 통신이 필요한 경우가 있습니다.

예시:

- ECR 이미지 Pull
- 외부 API 호출
- AWS API 호출
- 패키지 다운로드
- 업데이트 및 배포 관련 외부 연결

#### 설계 포인트

- NAT Gateway는 Public Subnet에 배치
- Private Subnet은 직접 IGW를 향하지 않도록 구성
- 외부 아웃바운드는 NAT를 통해 제한적으로 처리

---

## Route Table Strategy

라우팅은 서브넷 단위로 분리하여 관리했습니다.

### Public Subnet Route

- `0.0.0.0/0 -> Internet Gateway`

### Private Subnet Route

- `0.0.0.0/0 -> NAT Gateway`

### 설계 이유

- 역할에 따라 네트워크 경로를 분리
- 실수로 내부 실행 리소스가 외부에 직접 노출되는 상황 방지
- 운영자가 네트워크 책임 범위를 쉽게 이해할 수 있도록 단순화

---

## Traffic Flow

### Inbound Traffic

외부 요청은 다음 흐름으로 들어옵니다.

    User
      ↓
    CloudFront
      ↓
    ALB
      ↓
    Ingress
      ↓
    Service
      ↓
    Pod

#### 특징

- 외부 트래픽 진입점을 CloudFront와 ALB로 제한
- Kubernetes 내부 라우팅은 Ingress와 Service로 처리
- Pod 자체는 외부에 직접 노출되지 않음

### Outbound Traffic

Private Subnet에 위치한 Worker Node 및 Pod의 외부 요청은 다음 흐름을 따릅니다.

    Pod / Worker Node
      ↓
    Private Subnet
      ↓
    NAT Gateway
      ↓
    Internet

#### 특징

- Worker Node는 Public IP 없이 운영 가능
- 외부 아웃바운드는 NAT Gateway를 통해 일관되게 처리
- 운영 및 보안 정책 적용이 단순해짐

---

## Operational Considerations

이 구조는 가장 화려한 구조보다 실제 서비스 운영에 적합한 구조를 목표로 했습니다.

### 장점

- Worker Node 외부 노출 최소화
- 서비스 계층과 데이터 계층 책임 분리
- 운영 접근 경로 명확화
- 멀티 AZ 기반 가용성 확보
- 확장 가능한 네트워크 기반 마련

### 운영 중 고려했던 점

- NAT Gateway 비용
- 환경별 Subnet 및 Route Table 관리 복잡도
- 데이터 계층 접근 제어를 위한 Security Group 설계
- Bastion 기반 운영 접근의 관리 부담

---

## Trade-offs

이 구조는 보안성과 운영 안정성을 높이는 대신, 단일 Public 구조보다 관리 복잡도가 조금 높아집니다.

### 선택한 방향

- 단순함보다 운영 안정성 우선
- 직접 노출보다 Private 중심 구조 우선
- 빠른 구축보다 반복 가능한 표준 구조 우선

---

## Outcome

이 네트워크 구조를 통해 다음과 같은 운영 기반을 확보했습니다.

- 멀티 AZ 기반 인프라 구조 확보
- Public / Private / Data 계층 분리
- Private Worker Node 중심 실행 환경 구성
- NAT Gateway 기반 아웃바운드 통신 구조 확보
- 데이터 계층 접근 제어 기반 마련
- 운영 및 보안 정책을 적용하기 쉬운 네트워크 구조 확보