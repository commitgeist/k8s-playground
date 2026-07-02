# Lab: Migração NGINX Ingress → Traefik

> Dois labs independentes cobrindo o mesmo objetivo — migrar do NGINX Ingress Controller para o Traefik — em ambientes distintos: **local via kind** e **nuvem via AKS**.

## Mapa dos materiais nesta pasta

| Material | Onde | Pra quê |
|---|---|---|
| Lab kind passo-a-passo (Traefik sozinho) | [`traefik-lab/`](traefik-lab/README.md) | Aprender Traefik do zero, sem nginx envolvido |
| Lab kind passo-a-passo (migração) | [`migration-nginx-to-traefik/`](migration-nginx-to-traefik/README.md) | Rodar nginx + traefik lado a lado e fazer cutover |
| Referência consolidada (kind **e** AKS) | este arquivo | Material de consulta, cobre os dois ambientes |
| Curso original LinuxTips | [`traefik-migration-study/`](traefik-migration-study/readme.md) | Sections 1-5 do material da LinuxTips (Rancher + HAProxy) |

> Recomendação: comece pelos labs guiados (`traefik-lab/` → `migration-nginx-to-traefik/`) e use este arquivo + o curso como referência quando travar.

---

## Pré-requisitos Gerais

| Ferramenta | Versão mínima | Observação |
|---|---|---|
| Docker | 24+ | Necessário para os dois labs |
| kubectl | 1.27+ | Mesmo contexto do cluster alvo |
| Helm | 3.12+ | Instalação dos controllers |
| curl | qualquer | Testes de rota |
| openssl | qualquer | Geração de TLS self-signed |

---

## Lab 1 — kind (Local)

**Objetivo:** Subir um cluster Kubernetes local, instalar o NGINX Ingress com rotas reais (incluindo path rewrites), migrar para o Traefik side-by-side, e validar cada rota sem downtime.

**Custo:** Zero.  
**Tempo estimado:** ~2h.

---

### 1.1 Ferramentas adicionais

```bash
# kind
curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x /usr/local/bin/kind

# Verificar
kind version
kubectl version --client
```

---

### 1.2 Criar o Cluster kind

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: traefik-lab
nodes:
  - role: control-plane
    image: kindest/node:v1.29.2
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
  - role: worker
    image: kindest/node:v1.29.2
  - role: worker
    image: kindest/node:v1.29.2
```

```bash
kind create cluster --config kind-config.yaml
kubectl cluster-info --context kind-traefik-lab
kubectl get nodes
```

> **Por que extraPortMappings?** O kind não expõe portas do container automaticamente para o host. O mapping 80→8080 e 443→8443 permite testar com `curl http://localhost:8080` sem precisar de MetalLB ou LoadBalancer externo.

---

### 1.3 Instalar MetalLB (LoadBalancer local)

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=180s
```

Descobrir a subnet do kind e configurar o pool de IPs:

```bash
# Pegar o range da docker network kind
DOCKER_SUBNET=$(docker network inspect kind \
  -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | head -1)

echo "Subnet: $DOCKER_SUBNET"
# Exemplo de saída: 172.18.0.0/16
# Use o range 172.18.255.200-172.18.255.250 como pool
```

```yaml
# metallb-pool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: kind-pool
  namespace: metallb-system
spec:
  addresses:
    - 172.18.255.200-172.18.255.250   # ajuste conforme sua subnet
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: kind-l2
  namespace: metallb-system
```

```bash
kubectl apply -f metallb-pool.yaml
```

---

### 1.4 Instalar NGINX Ingress Controller (estado atual)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.default=false \
  --wait

kubectl get svc -n ingress-nginx
# EXTERNAL-IP será um IP do pool MetalLB, ex: 172.18.255.200
export NGINX_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller \
  -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "NGINX IP: $NGINX_IP"
```

---

### 1.5 Deploy das Aplicações Mock

Simula 3 backends com path prefix diferente — o cenário "chato" de path rewrite.

```yaml
# apps-mock.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-auth
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-auth
  template:
    metadata:
      labels:
        app: app-auth
    spec:
      containers:
        - name: app
          image: traefik/whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-auth
spec:
  selector:
    app: app-auth
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-api
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-api
  template:
    metadata:
      labels:
        app: app-api
    spec:
      containers:
        - name: app
          image: traefik/whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-api
spec:
  selector:
    app: app-api
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-portal
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-portal
  template:
    metadata:
      labels:
        app: app-portal
    spec:
      containers:
        - name: app
          image: traefik/whoami
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app-portal
spec:
  selector:
    app: app-portal
  ports:
    - port: 80
```

```bash
kubectl apply -f apps-mock.yaml
kubectl get pods
```

---

### 1.6 Ingress NGINX com Path Rewrites

```yaml
# nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lab-nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    # Reescreve o path antes de encaminhar pro backend
    # Ex: /app/authenticate/login → /login no backend
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
    - host: lab.local
      http:
        paths:
          - path: /app/authenticate(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-auth
                port:
                  number: 80
          - path: /app/api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-api
                port:
                  number: 80
          - path: /app/portal(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-portal
                port:
                  number: 80
```

```bash
kubectl apply -f nginx-ingress.yaml

# Testar (o --resolve mapeia lab.local para o IP do NGINX)
curl --resolve lab.local:80:$NGINX_IP http://lab.local/app/authenticate/login
curl --resolve lab.local:80:$NGINX_IP http://lab.local/app/api/users
curl --resolve lab.local:80:$NGINX_IP http://lab.local/app/portal/dashboard
```

> **Validação esperada:** O `whoami` responde com o path recebido. Com o rewrite, o backend deve receber `/login`, `/users`, `/dashboard` — não o prefixo `/app/authenticate/...`.

---

### 1.7 Instalar Traefik (lado a lado com NGINX)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ingressClass.enabled=true \
  --set ingressClass.isDefaultClass=false \
  --set ingressRoute.dashboard.enabled=true \
  --wait

kubectl get svc -n traefik
export TRAEFIK_IP=$(kubectl get svc traefik -n traefik \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Traefik IP: $TRAEFIK_IP"
```

> Neste ponto os dois controllers estão rodando, cada um com seu próprio IP. Nenhuma rota existente foi afetada.

---

### 1.8 Inventariar as Annotations NGINX em Uso

Antes de criar as rotas no Traefik, mapear o que está sendo usado:

```bash
kubectl get ingress -A -o json | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name): " +
  (.metadata.annotations // {} | to_entries |
   map(select(.key | startswith("nginx.ingress.kubernetes.io/"))) |
   map(.key) | join(", "))'
```

**Mapeamento NGINX → Traefik:**

| Annotation NGINX | Equivalente Traefik |
|---|---|
| `rewrite-target: /$2` | Middleware `StripPrefixRegex` ou `ReplacePathRegex` |
| `proxy-body-size: 50m` | Middleware `Buffering` com `maxRequestBodyBytes` |
| `proxy-read-timeout: 300` | `serversTransport` com `responseHeaderTimeout` |
| `ssl-redirect: "true"` | Entrypoint `web` com `redirections` |
| `cors-allow-origin` | Middleware `Headers` com CORS |
| `rate-limit` | Middleware `RateLimit` |

---

### 1.9 Criar Middlewares no Traefik

```yaml
# traefik-middlewares.yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-app-authenticate
  namespace: default
spec:
  replacePathRegex:
    regex: "^/app/authenticate(/|$)(.*)"
    replacement: "/$2"
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-app-api
  namespace: default
spec:
  replacePathRegex:
    regex: "^/app/api(/|$)(.*)"
    replacement: "/$2"
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-app-portal
  namespace: default
spec:
  replacePathRegex:
    regex: "^/app/portal(/|$)(.*)"
    replacement: "/$2"
```

```bash
kubectl apply -f traefik-middlewares.yaml
kubectl get middleware
```

---

### 1.10 Criar IngressRoutes no Traefik

```yaml
# traefik-ingressroutes.yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: lab-traefik
  namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`lab.local`) && PathPrefix(`/app/authenticate`)
      kind: Rule
      middlewares:
        - name: strip-app-authenticate
      services:
        - name: app-auth
          port: 80
    - match: Host(`lab.local`) && PathPrefix(`/app/api`)
      kind: Rule
      middlewares:
        - name: strip-app-api
      services:
        - name: app-api
          port: 80
    - match: Host(`lab.local`) && PathPrefix(`/app/portal`)
      kind: Rule
      middlewares:
        - name: strip-app-portal
      services:
        - name: app-portal
          port: 80
```

```bash
kubectl apply -f traefik-ingressroutes.yaml
kubectl get ingressroute
```

---

### 1.11 Validar a Migração

```bash
# Testar via Traefik (mesmo host, IPs diferentes)
curl --resolve lab.local:80:$TRAEFIK_IP http://lab.local/app/authenticate/login
curl --resolve lab.local:80:$TRAEFIK_IP http://lab.local/app/api/users
curl --resolve lab.local:80:$TRAEFIK_IP http://lab.local/app/portal/dashboard

# Validar que NGINX ainda funciona
curl --resolve lab.local:80:$NGINX_IP http://lab.local/app/authenticate/login
```

> **Neste ponto os dois estão funcionando.** O corte de DNS (ou IP) decide qual atende o tráfego real.

---

### 1.12 Corte Final — Desativar NGINX

Após validar todas as rotas no Traefik:

```bash
# Remover o Ingress NGINX (as rotas migradas viram IngressRoutes)
kubectl delete ingress lab-nginx

# Desinstalar o NGINX Ingress Controller
helm uninstall nginx-ingress -n ingress-nginx
kubectl delete namespace ingress-nginx
```

---

### 1.13 Dashboard do Traefik

```bash
kubectl port-forward -n traefik $(kubectl get pod -n traefik -l app.kubernetes.io/name=traefik -o name) 9000:9000
# Abrir: http://localhost:9000/dashboard/
```

---

### Limpeza do Lab 1

```bash
kind delete cluster --name traefik-lab
```

---

## Lab 2 — AKS (Nuvem)

**Objetivo:** Reproduzir o mesmo cenário de migração NGINX → Traefik em um cluster AKS real, usando as práticas de produção: GitOps-ready, TLS real via cert-manager, e IngressClass separada.

**Custo estimado:** ~R$ 15-25/dia com cluster no estado `stop`.  
**Tempo estimado:** ~3h (incluindo provisionamento do AKS).

---

### 2.1 Variáveis de Ambiente

```bash
export RG="rg-traefik-lab"
export LOCATION="eastus"
export CLUSTER="aks-traefik-lab"
export NODE_COUNT=2
export NODE_SIZE="Standard_B2s"
```

---

### 2.2 Criar o Resource Group e o AKS

```bash
az group create --name $RG --location $LOCATION

az aks create \
  --resource-group $RG \
  --name $CLUSTER \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --generate-ssh-keys \
  --enable-managed-identity \
  --network-plugin azure \
  --no-wait

# Aguardar (10-15 min)
az aks wait --resource-group $RG --name $CLUSTER --created

# Pegar credenciais
az aks get-credentials --resource-group $RG --name $CLUSTER --overwrite-existing
kubectl get nodes
```

---

### 2.3 Instalar NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.default=false \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --wait

# Pegar IP público do NGINX
export NGINX_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller \
  -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "NGINX Public IP: $NGINX_IP"
```

---

### 2.4 Deploy das Aplicações Mock

Mesmo manifesto do Lab 1 — reutilizável:

```bash
kubectl apply -f apps-mock.yaml
```

---

### 2.5 Instalar cert-manager (TLS real)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait
```

Criar um ClusterIssuer com Let's Encrypt (staging primeiro):

```yaml
# clusterissuer-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: seu@email.com   # altere aqui
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
      - http01:
          ingress:
            class: nginx   # resolver via NGINX primeiro
```

```bash
kubectl apply -f clusterissuer-staging.yaml
```

> **Nota:** Para TLS funcionar com Let's Encrypt, o domínio precisa estar apontando para o IP público. Em lab, você pode usar nip.io: `lab.$NGINX_IP.nip.io` resolve automaticamente para `$NGINX_IP`.

---

### 2.6 Ingress NGINX com TLS

```yaml
# nginx-ingress-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lab-nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  tls:
    - hosts:
        - lab.NGINX_IP_AQUI.nip.io   # substitua pelo IP real
      secretName: lab-tls-nginx
  rules:
    - host: lab.NGINX_IP_AQUI.nip.io
      http:
        paths:
          - path: /app/authenticate(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-auth
                port:
                  number: 80
          - path: /app/api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-api
                port:
                  number: 80
          - path: /app/portal(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: app-portal
                port:
                  number: 80
```

```bash
# Substituir o IP no arquivo antes de aplicar
sed -i "s/NGINX_IP_AQUI/$NGINX_IP/g" nginx-ingress-tls.yaml
kubectl apply -f nginx-ingress-tls.yaml

# Verificar emissão do certificado
kubectl get certificate
kubectl describe certificate lab-tls-nginx
```

---

### 2.7 Instalar Traefik no AKS (side-by-side)

```bash
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ingressClass.enabled=true \
  --set ingressClass.isDefaultClass=false \
  --set ingressRoute.dashboard.enabled=true \
  --set service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/ping \
  --wait

export TRAEFIK_IP=$(kubectl get svc traefik -n traefik \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Traefik Public IP: $TRAEFIK_IP"
```

---

### 2.8 Middlewares e IngressRoutes no AKS

Mesmos manifestos do Lab 1, com ajuste de host:

```bash
# Aplicar middlewares
kubectl apply -f traefik-middlewares.yaml

# Substituir o host nos IngressRoutes para o IP do Traefik
sed "s/lab.local/lab.$TRAEFIK_IP.nip.io/g" traefik-ingressroutes.yaml | kubectl apply -f -
```

---

### 2.9 TLS no Traefik via cert-manager

```yaml
# traefik-ingressroutes-tls.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: lab-tls-traefik
  namespace: default
spec:
  secretName: lab-tls-traefik
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
    - lab.TRAEFIK_IP_AQUI.nip.io
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: lab-traefik-tls
  namespace: default
spec:
  entryPoints:
    - websecure
  tls:
    secretName: lab-tls-traefik
  routes:
    - match: Host(`lab.TRAEFIK_IP_AQUI.nip.io`) && PathPrefix(`/app/authenticate`)
      kind: Rule
      middlewares:
        - name: strip-app-authenticate
      services:
        - name: app-auth
          port: 80
    - match: Host(`lab.TRAEFIK_IP_AQUI.nip.io`) && PathPrefix(`/app/api`)
      kind: Rule
      middlewares:
        - name: strip-app-api
      services:
        - name: app-api
          port: 80
    - match: Host(`lab.TRAEFIK_IP_AQUI.nip.io`) && PathPrefix(`/app/portal`)
      kind: Rule
      middlewares:
        - name: strip-app-portal
      services:
        - name: app-portal
          port: 80
```

```bash
sed -i "s/TRAEFIK_IP_AQUI/$TRAEFIK_IP/g" traefik-ingressroutes-tls.yaml
kubectl apply -f traefik-ingressroutes-tls.yaml

kubectl get certificate
kubectl get ingressroute
```

---

### 2.10 Validar no AKS

```bash
# Via NGINX (ainda ativo)
curl -k https://lab.$NGINX_IP.nip.io/app/authenticate/login
curl -k https://lab.$NGINX_IP.nip.io/app/api/users

# Via Traefik (novo)
curl -k https://lab.$TRAEFIK_IP.nip.io/app/authenticate/login
curl -k https://lab.$TRAEFIK_IP.nip.io/app/api/users

# Dashboard Traefik
kubectl port-forward -n traefik svc/traefik 9000:9000
# Abrir: http://localhost:9000/dashboard/
```

---

### 2.11 Corte Final no AKS

```bash
kubectl delete ingress lab-nginx

helm uninstall nginx-ingress -n ingress-nginx
kubectl delete namespace ingress-nginx

# Verificar que Traefik ainda serve as rotas
curl -k https://lab.$TRAEFIK_IP.nip.io/app/authenticate/login
```

---

### 2.12 Economizar custo — Stop do Cluster

```bash
# Parar o cluster (para não pagar as VMs paradas)
az aks stop --resource-group $RG --name $CLUSTER

# Retomar
az aks start --resource-group $RG --name $CLUSTER
```

---

### Limpeza do Lab 2

```bash
az group delete --name $RG --yes --no-wait
```

---

## Comparativo Rápido: kind vs AKS

| Aspecto | Lab 1 (kind) | Lab 2 (AKS) |
|---|---|---|
| Custo | Zero | ~R$ 15-25/dia |
| Provisionamento | ~2 min | ~15 min |
| LoadBalancer | MetalLB (L2) | Azure LB (cloud) |
| TLS | Self-signed / sem TLS | cert-manager + Let's Encrypt |
| Iteração (erro e retry) | ~30s | ~5 min |
| Fidelidade ao prod | Baixa (sem cloud APIs) | Alta |
| Ideal para | Aprender CRDs, testar config | Validar antes de prod real |

---

## Referências

- [Traefik Docs — IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/)
- [Traefik Docs — Middlewares](https://doc.traefik.io/traefik/middlewares/http/overview/)
- [kind — Local Clusters](https://kind.sigs.k8s.io/)
- [MetalLB — kind Setup](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
- [cert-manager — AKS](https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/)