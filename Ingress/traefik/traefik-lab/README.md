# Lab — Traefik no Kind

Lab prático de Traefik como Ingress Controller rodando em cluster local com `kind`.
Cobre instalação via Helm, dashboard com basic-auth, Ingress nativo do Kubernetes,
IngressRoute (CRD do Traefik) e Middlewares.

## Pré-requisitos

- [`kind`](https://kind.sigs.k8s.io/) >= 0.20
- `kubectl`
- `helm` >= 3.12
- `docker`
- `htpasswd` (opcional, pra mexer no basic-auth)
- Portas 80, 443 e 9000 livres no host

## Estrutura

```
traefik-lab/
├── 01-kind/kind-config.yaml      # cluster com NodePorts mapeados
├── 02-install/values.yaml        # values do helm chart
├── 03-apps/apps.yaml             # whoami + nginx-hello
└── 04-routing/
    ├── 01-ingress-native.yaml    # Ingress (k8s nativo) -> traefik
    └── 02-ingressroute-crd.yaml  # IngressRoute (CRD) com Middleware
```

## Passo 1 — Subir o cluster

> ⚠️ **K8s >= 1.31 obrigatório.** O chart do Traefik instala as CRDs do
> Gateway API, que usam a função CEL `isIP()` introduzida só no 1.31.
> Em 1.30 o `helm install` quebra com:
> `CustomResourceDefinition ... is invalid: undeclared reference to 'isIP'`.
> O [`kind-config.yaml`](01-kind/kind-config.yaml) já fixa `kindest/node:v1.31.0`.

```bash
cd 01-kind
kind create cluster --config kind-config.yaml
kubectl get nodes
kubectl version  # confirma server >= 1.31
```

O kind mapeia:
- `host:80`   → `node:30080` (entrypoint `web`)
- `host:443`  → `node:30443` (entrypoint `websecure`)
- `host:9000` → `node:30900` (dashboard)

### Já tem um cluster com K8s 1.30 rodando?

Recria com a imagem nova:

```bash
kind delete cluster --name traefik-lab
kind create cluster --config kind-config.yaml
```

Atualizar `kindest/node` num cluster existente **não é suportado** — tem que
recriar.

## Passo 2 — Instalar o Traefik via Helm

> ⚠️ Rode os 3 comandos **no mesmo shell**, na ordem. O `helm install` falha
> com `Error: INSTALLATION FAILED: repo traefik not found` se o `helm repo add`
> não tiver sido executado nessa sessão.

```bash
# 1) registra o repo do Traefik (uma vez por máquina)
helm repo add traefik https://traefik.github.io/charts

# 2) atualiza o índice local
helm repo update

# 3) confirma que o repo está listado
helm repo list | grep traefik

# 4) instala
cd ../02-install
helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --values values.yaml
```

Valida:

```bash
kubectl -n traefik get pods,svc,ingressroute
kubectl get ingressclass
```

## Passo 3 — Subir as apps

```bash
cd ../03-apps
kubectl apply -f apps.yaml
kubectl get pods,svc -n lab-apps
```

## Passo 4 — Ingress nativo do Kubernetes

A graça do Traefik é que ele entende **tanto** Ingress nativo **quanto** o CRD
próprio. Comece pelo Ingress padrão (mesma sintaxe que nginx):

```bash
kubectl apply -f ../04-routing/01-ingress-native.yaml
kubectl get ingress -n lab-apps
```

Adiciona no `/etc/hosts`:

```
127.0.0.1 traefik.kubenerd.local whoami.kubenerd.local hello.kubenerd.local
```

Testa:

```bash
curl http://whoami.kubenerd.local/
curl http://hello.kubenerd.local/
```

## Passo 5 — IngressRoute (CRD) + Middleware

```bash
kubectl apply -f ../04-routing/02-ingressroute-crd.yaml
kubectl get ingressroute,middleware -n lab-apps
```

Testa o `stripPrefix` middleware:

```bash
# Sem prefixo: bate na rota "Host(...)"
curl http://whoami.kubenerd.local/

# Com /api: middleware tira o prefixo antes de mandar pro backend
curl http://whoami.kubenerd.local/api/qualquer/coisa
```

## Passo 6 — Dashboard

Lab local sem auth e sem TLS — direto no browser:

```
http://traefik.kubenerd.local/dashboard/
```

> Atenção à barra final em `/dashboard/` — sem ela o Traefik retorna 404.
> Em produção: re-habilitar `basicAuth` + TLS no `IngressRoute` do dashboard
> (ver bloco comentado em [`02-install/values.yaml`](02-install/values.yaml)).

## Observabilidade

```bash
# logs do controller
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# rotas/middlewares descobertas
kubectl get ingressroute,middleware -A
```

## Cleanup

```bash
helm uninstall traefik -n traefik
kind delete cluster --name traefik-lab
```

## Próximo passo

→ [`../migration-nginx-to-traefik/`](../migration-nginx-to-traefik/README.md): rodar
nginx + traefik em paralelo no mesmo cluster e fazer cutover sem downtime.
