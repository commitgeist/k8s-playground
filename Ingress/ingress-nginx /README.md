# Lab — Ingress NGINX no Kind

Lab prático pra subir o **ingress-nginx controller** num cluster local com `kind` e brincar
com host-based routing, path-based routing com rewrite e TLS.

> Espelho do que fizemos com Traefik na pasta vizinha — agora com NGINX, que ainda é o
> ingress controller mais comum em produção.

## Pré-requisitos

- [`kind`](https://kind.sigs.k8s.io/) >= 0.20
- `kubectl`
- `docker`
- `openssl` (pro TLS self-signed)
- Portas 80 e 443 livres no host (kind faz port-forward direto)

## Estrutura

```
ingress-nginx/
├── kind/
│   └── kind-config.yaml      # cluster com extraPortMappings 80/443
├── apps/
│   ├── 01-deployments.yaml   # giropops-senhas + redis + nginx-hello
│   ├── 02-services.yaml
│   ├── 03-ingress.yaml       # host + path-based routing
│   └── 04-ingress-tls.yaml   # ingress com TLS
└── 01..10-*.yaml             # manifests do controller (alternativo ao install oficial)
```

## Passo 1 — Subir o cluster kind

```bash
cd "Ingress/ingress-nginx /kind"
kind create cluster --config kind-config.yaml

kubectl cluster-info --context kind-ingress-nginx-lab
kubectl get nodes
```

O node control-plane tem a label `ingress-ready=true` — o manifest oficial do
ingress-nginx pra kind usa ela como `nodeSelector`.

## Passo 2 — Instalar o ingress-nginx controller

**Opção A (recomendado pro kind) — manifest oficial:**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

**Opção B — usar os manifests dessa pasta** (mais didático, dá pra ler cada peça):

```bash
cd ..
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-ingressclass.yaml
kubectl apply -f 03-serviceaccount.yaml
kubectl apply -f 04-configmap.yaml
kubectl apply -f 05-clusterrole.yaml
kubectl apply -f 06-clusterrolebinding.yaml
kubectl apply -f 07-role.yaml
kubectl apply -f 08-rolebinding.yaml
kubectl apply -f 09-service.yaml
kubectl apply -f 10-deployment.yaml
```

> ⚠️ Os manifests da Opção B foram pensados pra AKS (Service `LoadBalancer` +
> annotation Azure). No kind o Service não vai ganhar IP externo — o tráfego entra
> pelas portas mapeadas no node. Pra didática funciona, mas no kind use a Opção A.

Confere:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc  -n ingress-nginx
kubectl get ingressclass
```

## Passo 3 — Subir as apps de exemplo

```bash
kubectl apply -f apps/01-deployments.yaml
kubectl apply -f apps/02-services.yaml
kubectl get pods,svc -n lab-apps
```

## Passo 4 — Criar os Ingresses

```bash
kubectl apply -f apps/03-ingress.yaml
kubectl get ingress -n lab-apps
kubectl describe ingress nginx-hello -n lab-apps
```

## Passo 5 — Testar

Sem mexer no `/etc/hosts`, mandando o `Host` no header:

```bash
# host-based routing
curl -H "Host: hello.kubenerd.local" http://localhost/

# path-based routing + rewrite
curl -H "Host: app.kubenerd.local" http://localhost/senhas/
```

Ou adiciona no `/etc/hosts` pra abrir no browser:

```
127.0.0.1 hello.kubenerd.local app.kubenerd.local secure.kubenerd.local
```

## Passo 6 — TLS

Gera um cert self-signed e cria o secret:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=secure.kubenerd.local/O=KubeNerd Lab" \
  -addext "subjectAltName = DNS:secure.kubenerd.local"

kubectl create secret tls tls-kubenerd \
  --cert=tls.crt --key=tls.key \
  -n lab-apps

kubectl apply -f apps/04-ingress-tls.yaml
```

Testa:

```bash
curl -k -H "Host: secure.kubenerd.local" https://localhost/
# ou via /etc/hosts:
curl -k https://secure.kubenerd.local/
```

## Passo 7 — Observabilidade rápida

Logs do controller (útil pra ver requests, regras carregadas, erros de validação
do webhook):

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f
```

Inspecionar o `nginx.conf` gerado dentro do pod:

```bash
POD=$(kubectl get pod -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n ingress-nginx "$POD" -- cat /etc/nginx/nginx.conf | less
```

## Cleanup

```bash
kind delete cluster --name ingress-nginx-lab
```

## Próximos passos sugeridos

- Adicionar `cert-manager` e trocar o cert self-signed por Let's Encrypt (staging)
- Habilitar métricas (`--enable-metrics`) e plugar Prometheus
- Testar annotations de rate-limit, basic-auth, canary deployments
- Comparar com a pasta `../traefik/` — mesmas funcionalidades, sintaxe diferente
