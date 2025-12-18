# 🧩 Ingress vs Ingress Controller - Entendendo a Diferença

## 📋 O que é cada coisa?

### 1️⃣ **Ingress** (Recurso Kubernetes)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress  # ← ISSO é um Ingress (apenas configuração)
metadata:
  name: meu-ingress
spec:
  rules:
  - host: meuapp.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: meu-service
            port:
              number: 80
```

### 2️⃣ **Ingress Controller** (Software que executa)
O Ingress Controller é o **software real** que:
- ✅ Lê as regras do Ingress
- ✅ Configura o proxy/load balancer
- ✅ Roteia o tráfego para os pods

## 🏗️ Tipos de Ingress Controllers

| Nome | O que é | Onde usar |
|------|---------|-----------|
| **HTTP Application Routing** | Ingress Controller **simples** do Azure | 🟡 Desenvolvimento/Teste |
| **NGINX Ingress Controller** | Ingress Controller **robusto** baseado no NGINX | 🟢 Produção |
| **Traefik** | Ingress Controller moderno | 🟢 Produção |
| **Istio Gateway** | Service Mesh avançado | 🟢 Produção complexa |

## 🎯 HTTP Application Routing - O que é?

É um **Ingress Controller SIMPLES** que o Azure oferece:

### ✅ **Vantagens:**
- 🚀 **Fácil de ativar**: 1 comando no AKS
- 🎯 **DNS automático**: Cria domínio `.cloudapp.azure.com`
- 🔧 **Zero configuração**: Funciona "out of the box"

### ❌ **Limitações:**
- 🚫 **Não é para produção** (Microsoft mesmo diz isso!)
- 🚫 **Sem SSL/TLS automático**
- 🚫 **Sem features avançadas** (rate limiting, auth, etc.)
- 🚫 **Performance limitada**

## 🔄 Como Funciona na Prática

### Passo 1: Ativar HTTP Application Routing
```bash
# Ativar no cluster existente
az aks enable-addons \
  --resource-group meu-rg \
  --name meu-cluster \
  --addons http_application_routing

# Ou criar cluster já com ele ativado
az aks create \
  --name meu-cluster \
  --enable-addons http_application_routing
```

### Passo 2: Pegar o DNS Zone
```bash
# Ver qual DNS foi criado
az aks show \
  --resource-group meu-rg \
  --name meu-cluster \
  --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName \
  --output tsv

# Resultado: algo como "abc123.eastus.aksapp.io"
```

### Passo 3: Criar Ingress usando esse DNS
/*
  https://docs.azure.cn/en-us/aks/web-app-routing?tabs=without-osm

*/
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: meu-app-ingress
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
  - host: meuapp.abc123.eastus.aksapp.io  # ← DNS automático
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: meu-service
            port:
              number: 80
```

## 🆚 Comparação Prática

### HTTP Application Routing:
```bash
# 1. Ativar (super fácil)
az aks enable-addons --addons http_application_routing

# 2. Usar (DNS automático)
# Host: meuapp.abc123.eastus.aksapp.io
```

### NGINX Ingress Controller:
```bash
# 1. Instalar (mais passos)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# 2. Configurar DNS manualmente
# Host: meuapp.meudominio.com (você gerencia)
```

## 🎯 Quando Usar Cada Um?

### 🟡 **HTTP Application Routing**
- ✅ Desenvolvimento local
- ✅ Testes rápidos
- ✅ Demos/POCs
- ✅ Aprendizado

### 🟢 **NGINX Ingress Controller**
- ✅ Produção
- ✅ SSL/TLS automático
- ✅ Múltiplas aplicações
- ✅ Features avançadas

## 💡 Resumo da Confusão

**Ingress** = Arquivo YAML com regras
**Ingress Controller** = Software que executa essas regras
**HTTP Application Routing** = Um tipo específico de Ingress Controller (simples)
**NGINX** = Outro tipo de Ingress Controller (robusto)

Todos usam o **mesmo formato de Ingress YAML**, só muda quem processa! 🚀