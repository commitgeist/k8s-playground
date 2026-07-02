# Rancher

## O que é?

Rancher é uma plataforma de gerenciamento de clusters Kubernetes. Funciona como um "painel de controle" centralizado onde você consegue:

- Gerenciar múltiplos clusters de um único lugar
- Interface web para visualizar e operar recursos
- Controle de acesso centralizado (RBAC)
- Catálogo de aplicações (Helm charts)
- Monitoramento e logging integrado

### Analogia

Pensa assim: você tem 5 clusters Kubernetes (dev, staging, prod-us, prod-eu, prod-asia). Sem Rancher, você precisa ficar trocando de contexto no kubectl o tempo todo. Com Rancher, você acessa uma interface web e gerencia todos de um lugar só.

---

## Quando usar?

**Use Rancher quando:**
- Você tem múltiplos clusters para gerenciar
- Precisa dar acesso a diferentes times com permissões diferentes
- Quer uma interface visual para gerenciar Kubernetes
- Precisa de catálogo de aplicações centralizado
- Quer monitoramento e logging integrado

**Não precisa de Rancher quando:**
- Você tem apenas 1 cluster pequeno
- Está confortável usando apenas kubectl
- Usa ferramentas como Lens ou k9s e está satisfeito

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Rancher Server                        │
│  (Interface Web + API + Autenticação + Catálogo)        │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │ Cluster  │         │ Cluster  │         │ Cluster  │
    │   Dev    │         │  Staging │         │   Prod   │
    │  (Agent) │         │  (Agent) │         │  (Agent) │
    └──────────┘         └──────────┘         └──────────┘
```

**Rancher Server**: Onde roda a interface e API
**Rancher Agent**: Roda em cada cluster gerenciado, comunica com o Server

---

## Lab 1: Docker (Local)

Lab simples para testar Rancher localmente usando Docker.

### Pré-requisitos
- Docker instalado

### Passo 1: Subir Rancher

```bash
docker run -d --restart=unless-stopped \
  --name rancher \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest
```

### Passo 2: Pegar senha inicial

```bash
# Aguardar uns 2-3 minutos para iniciar
docker logs rancher 2>&1 | grep "Bootstrap Password:"
```

### Passo 3: Acessar

```
https://localhost
```

1. Usar a senha do passo anterior
2. Definir nova senha de admin
3. Aceitar termos
4. Configurar URL (pode deixar o padrão para lab)

### Passo 4: Explorar

Agora você tem acesso à interface do Rancher. Explore:
- Cluster Management
- Apps & Marketplace
- Users & Authentication

### Cleanup

```bash
docker rm -f rancher
```

---

## Lab 2: Kind (Kubernetes Local)

Lab mais realista: Rancher rodando em Kubernetes (Kind) gerenciando outro cluster.

### Pré-requisitos
- Docker instalado
- Kind instalado
- kubectl instalado
- Helm instalado

### Passo 1: Criar cluster Kind para o Rancher

```bash
# Criar cluster
cat <<EOF | kind create cluster --name rancher-server --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Verificar
kubectl cluster-info --context kind-rancher-server
```

### Passo 2: Instalar cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Aguardar ficar pronto
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
```

### Passo 3: Instalar Rancher via Helm

```bash
# Adicionar repo
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Criar namespace
kubectl create namespace cattle-system

# Instalar
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=localhost \
  --set bootstrapPassword=admin123 \
  --set replicas=1

# Aguardar
kubectl -n cattle-system rollout status deploy/rancher
```

### Passo 4: Acessar

```
https://localhost
```

- Usuário: admin
- Senha: admin123

### Passo 5: Criar segundo cluster para gerenciar

```bash
# Criar outro cluster Kind
kind create cluster --name workload-cluster

# Verificar
kubectl cluster-info --context kind-workload-cluster
```

### Passo 6: Importar cluster no Rancher

1. Na interface Rancher: **Cluster Management → Import Existing**
2. Dar um nome: `workload-cluster`
3. Copiar o comando `kubectl apply -f ...`
4. Executar no cluster workload:

```bash
# Mudar para contexto do workload
kubectl config use-context kind-workload-cluster

# Colar e executar o comando copiado do Rancher
kubectl apply -f https://localhost/v3/import/xxxxx.yaml

# Aguardar aparecer como Active no Rancher
```

### Passo 7: Gerenciar via Rancher

Agora você pode:
- Ver os dois clusters na interface
- Fazer deploy de aplicações
- Ver logs e métricas
- Gerenciar RBAC

### Cleanup

```bash
kind delete cluster --name rancher-server
kind delete cluster --name workload-cluster
```

---

## Troubleshooting

### Rancher não inicia

```bash
# Docker
docker logs rancher

# Kubernetes
kubectl logs -n cattle-system deployment/rancher
```

### Reset de senha

```bash
# Docker
docker exec -ti rancher reset-password

# Kubernetes
kubectl -n cattle-system exec $(kubectl -n cattle-system get pods -l app=rancher --no-headers | head -1 | awk '{print $1}') -- reset-password
```

### Cluster não conecta

```bash
# Ver agent
kubectl get pods -n cattle-system

# Logs do agent
kubectl logs -n cattle-system -l app=cattle-cluster-agent
```

---

## Recursos

- [Documentação Oficial](https://rancher.com/docs/)
- [Rancher GitHub](https://github.com/rancher/rancher)
- [Rancher Academy](https://academy.rancher.com/)

