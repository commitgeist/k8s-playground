# O que é o Ingress?
Referência: [Ingress-Nginx no GitHub](https://github.com/kubernetes/ingress-nginx)

O Ingress é um recurso do Kubernetes que gerencia o acesso externo aos serviços dentro de um cluster. Ele funciona como uma camada de roteamento HTTP/HTTPS, permitindo a definição de regras para direcionar o tráfego externo para diferentes serviços back-end. Implementado através de um controlador de Ingress, ele pode ser alimentado por várias soluções, como NGINX, Traefik ou Istio.

Tecnicamente, o Ingress atua como uma abstração de regras de roteamento de alto nível interpretadas e aplicadas pelo controlador de Ingress. Ele oferece recursos como balanceamento de carga, SSL/TLS, redirecionamento e reescrita de URL.

## Principais Componentes e Funcionalidades

- **Controlador de Ingress**: Implementação real que satisfaz um recurso Ingress, podendo ser implementado através de soluções de proxy reverso como NGINX ou HAProxy.
- **Regras de Roteamento**: Definidas em um objeto YAML, determinam como as requisições externas são encaminhadas para os serviços internos.
- **Backend Padrão**: Serviço de fallback para requisições que não correspondem a nenhuma regra de roteamento.
- **Balanceamento de Carga**: Distribuição automática de tráfego entre múltiplos pods de um serviço.
- **Terminação SSL/TLS**: Configuração de certificados SSL/TLS para criptografia no ponto de entrada do cluster.
- **Anexos de Recurso**: Inclusão de recursos adicionais como ConfigMaps ou Secrets, úteis para configurações adicionais como autenticação básica ou listas de controle de acesso.

### Implementação do Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
```

Para aguardar a prontidão dos pods do Ingress Controller:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

Configurando Ingress no Kind
Para configurar o Ingress no Kind, você pode usar o seguinte YAML:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP

```
Ingress em Outras Plataformas
Minikube: Utilize o comando minikube addons enable ingress.
MicroK8s: Ative o ingress com microk8s enable ingress.
AWS: Instale via kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml. A terminação TLS pode ser configurada no Load Balancer.
Azure: Use kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml.
GCP: Garanta permissões de cluster-admin e instale com kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml. Pode ser necessário configurar regras de firewall para clusters privados.
Bare Metal: Para testes rápidos, use kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml para mapear o ingress controller para uma porta entre



Neste ajuste, eu organizei o conteúdo para melhor legibilidade, converti a referência para um link clicável, estruturei as seções e formatei os comandos e listas para um formato mais limpo e consistente.

# Criando regra de Ingress

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: blog-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example(Se não tiver não bota isso)
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: techdayweproc-service
            port:
              number: 80
```

Agora basta applicar o yaml sem o namespace no apply

```bash
kubectl apply -f file-name-ingress.yaml 
```

E para ver os detalhes,

```bash
kubectl describe ingress name-ingress

```

Pegando o IP de saída

```bash
kubectl get ingress ingress-1 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```


```bash
kubectl get ingress ingress-1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
Isso porque quando você possui um cluster EKS, AKS, GCP, etc, o Ingress Controller irá criar um LoadBalancer para você, e o endereço IP do LoadBalancer será o endereço IP do seu Ingress, simples assim.

Para testar, você pode usar o comando curl com o IP, hostname ou load balancer do seu Ingress:

```bash
curl ENDEREÇO_DO_INGRESS/giropops-senhas
```