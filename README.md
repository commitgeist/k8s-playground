# PRÉ INICIO
### README - Introdução a Contêineres e Tecnologias Relacionadas

Este documento fornece uma introdução às tecnologias relacionadas a contêineres, incluindo contêineres em si, container engines, container runtime e a Open Container Initiative (OCI).

## Contêineres

Um contêiner é uma unidade de software leve que empacota um aplicativo e suas dependências, incluindo bibliotecas, em um ambiente isolado. A principal vantagem dos contêineres é a portabilidade, garantindo que um aplicativo funcione de maneira consistente em diferentes ambientes, independentemente das configurações do sistema operacional.

## Container Engine

Um container engine é um software que permite criar, executar e gerenciar contêineres. Ele é responsável por empacotar o aplicativo e fornecer recursos necessários para a execução dos contêineres em um sistema operacional. O Docker é um exemplo bem conhecido de um container engine.

## Container Runtime

O container runtime é a parte do container engine responsável pela execução efetiva dos contêineres. Ele inicia, para e gerencia os processos dentro dos contêineres e também fornece isolamento de recursos, como CPU e memória. O container runtime é uma parte crítica para a execução segura e eficiente dos contêineres.

## OCI (Open Container Initiative)

A OCI é uma iniciativa de código aberto que estabelece padrões para o formato de contêineres e a execução de contêineres. Esses padrões visam garantir a interoperabilidade entre diferentes container engines e runtimes. É como um conjunto de regras que todos devem seguir para assegurar que os contêineres funcionem consistentemente em qualquer ambiente.

Para obter mais informações sobre esses tópicos e como usá-los na prática, consulte a documentação relevante e tutoriais disponíveis online.

Esperamos que esta introdução tenha fornecido uma compreensão básica de contêineres e tecnologias relacionadas.


## Deployment
um deployment é um objeto que gerencia um conjunto de réplicas de pods. Um pod é a menor unidade que pode ser criada e gerenciada pelo Kubernetes, e geralmente contém um ou mais contêineres com aplicativos.

Quando você cria um deployment no Kubernetes, você está basicamente dizendo ao sistema como você quer que sua aplicação seja executada e acessível. O deployment garante que um número especificado de réplicas do pod estejam rodando a qualquer momento. Se um pod falha, o deployment automaticamente cria outro pod para substituir, mantendo o estado desejado da aplicação.

Esse processo é essencial para a implementação de estratégias de entrega contínua e para a garantia de alta disponibilidade e escalabilidade das aplicações em contêineres. O Kubernetes cuida da complexidade de gerenciar onde e como os contêineres são executados, permitindo que os desenvolvedores se concentrem na construção de software.


## POD
Um pod é a menor e mais básica unidade de implantação que você pode criar e gerenciar. É um wrapper que contém um ou mais contêineres (geralmente Docker), os quais compartilham recursos como armazenamento e rede. Cada pod é executado em um nó do cluster do Kubernetes, que pode ser uma máquina física ou virtual.

Os contêineres dentro de um mesmo pod têm o seguinte em comum:

Endereço IP: Todos os contêineres no pod compartilham um único endereço IP e podem se comunicar entre si através de localhost.
Volumes: Os contêineres podem compartilhar dados usando volumes que são definidos no nível do pod.
Informações de ciclo de vida: O estado do pod abrange todos os contêineres dentro dele. Se o pod inicia ou termina, isso afeta todos os contêineres simultaneamente.
O pod é fundamental no Kubernetes porque ele é a unidade de escala, ou seja, quando você escala sua aplicação, você está aumentando ou diminuindo o número de pods.

<hr/>

# DIA 1
### Arquitetura do Kubernetes

Node Control Plane
  1. Garantir a disponibilidade do cluster
  2. Controle do Cluster
  3. Tem serviços e containers de administração do cluster
  4. Garante a saúde, capacidade, e armazenar o estado do cluster
  5. É possivel rodas aplicações nele, mas não é default.

  ### Componentes do Control Plane:
    - etcd -> Armazena o estado do cluster(de fato o cérebro do cluster)
    - kube-api-server -> Conversa com o etcd por default, é o unico que fala com o etcd.  Mas de forma geral, ele se comunica com todos os demais componentes
    - kube-scheduler -> Responsável pelos agendamentos, no caso, o kube-api-server valida as ações a serem feitas, e o kube-scheduler faz o agendamento disso.
    - kube-controller-manager -> Fala com o kube-api-server, é o gerente dos estados dos pods do cluster, ou melhor, é o gerente de todos os controllers.

  ### Quais portas TCP e UDP dos Componentes Control Plane no Kubernetes

    Kube-Api-Server
      6443 -> TCP

    Kube-Etcd
      2379 - 2380 -> TCP

    Kubelet 
      10250 -> TCP

    Kube-Scheduler
      10251 -> TCP

    Kube-Controller
      10252 -> TCP


<hr/>

Node Workers
- Workers
  1. Roda a aplicação

  ### Componentes dos Workers

  - kubelet(agent que roda em todos os nós. Cada nó tem um kubelet.)
  - kube-proxy

  ### Quais portas TCP e UDP dos Componentes Workers no Kubernetes

  Node-Port
    3000 - 32767 -> TCP
  WeveNet
    6783 - 6784 -> TCP/UDP




<hr/>

### Introdução a pods, replica sets, deployments, e service

POD -> Menor unidade, roda os containers e aplicações
Deployments ->  Gerencia o estado dos pods, e tem a ver com o replica sets, pois me permite definir a quantidade de replicas de um pod.
Replica Sets -> Gerencia o número de instâncias de Pods
Services -> Exporta um serviço para ser acessado fora do cluster


### Instalando o kind

```bash
#!/usr/bin/bash
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Criando primeiro cluster com kind
Referência: https://kind.sigs.k8s.io/docs/user/configuration/#cluster-wide-options

```bash
kind create cluster
```
### Criando com yaml
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cloudminecluster
nodes:
- role: control-plane
- role: worker
```
```bash
kind create cluster --config createfile.yaml --name cloudmine
```

---

## Estrutura do Repositório

### Workloads
- [Workloads/](Workloads/) - Pods, Deployments, StatefulSets, DaemonSets, Services, Volumes, Probes

### Networking
- [Networking/](Networking/) - CNI, Kubenet, Azure CNI, Private Cluster
- [Ingress/](Ingress/) - Ingress Controllers, HTTP Application Routing, NGINX
- [CoreDNS/](CoreDNS/) - DNS no Kubernetes, configurações customizadas

### Segurança e Acesso
- [RBAC/](RBAC/) - Role-Based Access Control, Service Accounts, AAD Integration
- [Cert-Manager/](Cert-Manager/) - Gerenciamento de certificados TLS

### Ferramentas
- [Helm/](Helm/) - Package manager para Kubernetes
- [Troubleshooting/](Troubleshooting/) - Guias de debug e ferramentas (netshoot)

### Outros
- [Annotations/](Annotations/) - Anotações no Kubernetes