# Lab de migração — Ingress NGINX → Traefik

Migração **com zero downtime** rodando os dois ingress controllers em paralelo no mesmo
cluster e fazendo cutover por `ingressClassName`.

## Cenário

Você já tem app rodando atrás do `ingress-nginx` em produção. Quer trocar pra Traefik
sem dropar tráfego. A estratégia:

```
   Antes                 Migração                   Depois
┌─────────┐         ┌──────┬──────┐             ┌─────────┐
│  NGINX  │   →     │NGINX │TRAEFIK│   →         │ TRAEFIK │
└─────────┘         └──────┴──────┘             └─────────┘
   :80/:443         coexistência via             :80/:443
                    IngressClass
```

## Pré-requisitos

Reaproveita o cluster do lab anterior (`../traefik-lab`). Se ainda não subiu:

```bash
cd ../traefik-lab/01-kind
kind create cluster --config kind-config.yaml
```

> Importante: o kind-config do `traefik-lab` mapeia 80/443 do host pros NodePorts do
> Traefik (30080/30443). Pra esse lab de migração vamos rodar os **dois** controllers
> e usar `kubectl port-forward` pra testar individualmente — sem brigar pela porta 80.

## Passo 1 — Instalar os dois controllers em paralelo

### 1a. NGINX (situação "atual")

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClassResource.default=true \
  --set controller.service.type=ClusterIP
```

### 1b. Traefik (controller "novo")

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --values ../traefik-lab/02-install/values.yaml \
  --set ingressClass.isDefaultClass=false
```

Confirma que tem **dois** IngressClasses:

```bash
kubectl get ingressclass
# nginx     k8s.io/ingress-nginx        <default>
# traefik   traefik.io/ingress-controller
```

## Passo 2 — App rodando atrás do NGINX (estado inicial)

```bash
kubectl apply -f manifests/01-app.yaml
kubectl apply -f manifests/02-ingress-nginx.yaml

kubectl get ingress -n migration-lab
```

Testa:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 &
curl -H "Host: app.kubenerd.local" http://localhost:8080/
```

## Passo 3 — Coexistência: criar Ingress paralelo apontando pro Traefik

Mesma app, mesmo Service, **outro Ingress** com `ingressClassName: traefik`:

```bash
kubectl apply -f manifests/03-ingress-traefik.yaml
```

Agora a app responde **pelos dois** controllers. Valida:

```bash
# Via NGINX (porta 8080)
curl -H "Host: app.kubenerd.local" http://localhost:8080/

# Via Traefik (porta 8081)
kubectl port-forward -n traefik svc/traefik 8081:80 &
curl -H "Host: app.kubenerd.local" http://localhost:8081/
```

Os dois devem retornar a mesma resposta. Esse é o ponto-chave: **antes de mexer
no DNS/LB, valide que o Traefik atende exatamente igual.**

## Passo 4 — Cutover do tráfego externo

Em produção isso é feito **no LB ou no DNS**:

- **Trocando o Service do NGINX**: aponta o LB pro `svc/traefik` em vez do
  `svc/ingress-nginx-controller`.
- **Via DNS**: muda o A/CNAME pro IP/hostname do LB do Traefik.
- **Via Gateway API/Ingress shadow**: routing percentual (canary) — fora do
  escopo desse lab.

No kind, simulamos trocando o port-forward que "representa" o LB externo. A partir
desse momento, o tráfego real chega no Traefik.

## Passo 5 — Migrar o Ingress definitivo

Ao invés de manter dois Ingress objects, troca o `ingressClassName` do original e
remove o duplicado:

```bash
kubectl apply -f manifests/04-ingress-final.yaml
kubectl delete ingress app-nginx -n migration-lab
kubectl delete ingress app-traefik -n migration-lab
```

## Passo 6 — Mudar o IngressClass default

Pra que novos Ingress sem `ingressClassName` caiam no Traefik:

```bash
kubectl annotate ingressclass nginx ingressclass.kubernetes.io/is-default-class-
kubectl annotate ingressclass traefik ingressclass.kubernetes.io/is-default-class=true --overwrite
```

## Passo 7 — Remover o NGINX

Antes de deletar, **garanta que nenhum Ingress aponta mais pra ele**:

```bash
kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} -> {.spec.ingressClassName}{"\n"}{end}'
```

Tudo `traefik`? Pode remover:

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
kubectl delete ingressclass nginx
kubectl delete validatingwebhookconfiguration ingress-nginx-admission 2>/dev/null || true
```

## Conversão de annotations comuns

Migrar Ingress com annotations do nginx? Equivalentes diretos:

| nginx (`nginx.ingress.kubernetes.io/...`) | Traefik                                                   |
| ----------------------------------------- | --------------------------------------------------------- |
| `rewrite-target: /`                       | Middleware `replacePath` ou `replacePathRegex`            |
| `ssl-redirect: "true"`                    | Middleware `redirectScheme` (scheme: https, permanent)    |
| `force-ssl-redirect: "true"`              | EntryPoint `web` com `redirections.entryPoint`            |
| `auth-type: basic` + `auth-secret`        | Middleware `basicAuth` (secret kubernetes.io/basic-auth)  |
| `whitelist-source-range`                  | Middleware `ipAllowList`                                  |
| `proxy-body-size: 10m`                    | EntryPoint `transport.respondingTimeouts` / buffering     |
| `configuration-snippet`                   | **Sem equivalente direto** — refatorar pra middlewares    |

> A annotation `nginx.ingress.kubernetes.io/configuration-snippet` é o maior
> bloqueador típico em migrações reais. Mapeie-as antes de migrar.

## Cleanup

```bash
kind delete cluster --name traefik-lab
```
