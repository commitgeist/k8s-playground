# 🤔 Kubenet vs Azure CNI - Qual Usar?

## 📊 Uso Real no Mercado

| Cenário | Plugin Recomendado | Por quê? |
|---------|-------------------|----------|
| **Produção Enterprise** | Azure CNI | Integração com outros serviços Azure |
| **Desenvolvimento** | Kubenet | Mais simples, economiza IPs |
| **Clusters pequenos** | Kubenet | Menos complexidade |
| **Clusters grandes** | Azure CNI | Melhor performance e conectividade |

## 🏗️ Ambos Funcionam com VNet!

### Kubenet + VNet:
```
🌐 VNet (10.0.0.0/16)
  └─ Subnet AKS (10.0.1.0/24)
       ├─ Nó1 (10.0.1.4) ← IP da VNet
       ├─ Nó2 (10.0.1.5) ← IP da VNet
       └─ Pods (10.244.x.x) ← IPs internos + NAT
```

### Azure CNI + VNet:
```
🌐 VNet (10.0.0.0/16)
  └─ Subnet AKS (10.0.1.0/24)
       ├─ Nó1 (10.0.1.4) ← IP da VNet
       ├─ Pod1 (10.0.1.10) ← IP da VNet
       └─ Pod2 (10.0.1.11) ← IP da VNet
```

## 🚀 Exposição de Aplicações (AMBOS)

### Com Kubenet:
```bash
# Service LoadBalancer
kubectl expose deployment app --type=LoadBalancer --port=80

# Ingress + NGINX
kubectl apply -f ingress.yaml

# Application Gateway
# Funciona normalmente!
```

### Com Azure CNI:
```bash
# Mesma coisa! 
# Service LoadBalancer
kubectl expose deployment app --type=LoadBalancer --port=80

# Ingress + NGINX  
kubectl apply -f ingress.yaml

# Application Gateway
# Funciona normalmente!
```

## 🎯 A Diferença Real

| Aspecto | Kubenet | Azure CNI |
|---------|---------|-----------|
| **Exposição via Service** | ✅ Funciona igual | ✅ Funciona igual |
| **Ingress Controller** | ✅ Funciona igual | ✅ Funciona igual |
| **Application Gateway** | ✅ Funciona igual | ✅ Funciona igual |
| **VM acessar Pod direto** | ❌ Não consegue | ✅ Consegue |
| **IPs consumidos** | 🟢 Poucos | 🔴 Muitos |
| **Performance** | 🟡 Boa | 🟢 Melhor |

## 💡 Quando a Diferença Importa

### Kubenet é suficiente quando:
- ✅ Só expõe apps via Service/Ingress
- ✅ Não precisa de VMs acessando pods diretamente
- ✅ Quer economizar IPs da VNet
- ✅ Cluster simples

### Azure CNI é necessário quando:
- ✅ VMs precisam acessar pods diretamente
- ✅ Integração com Azure Firewall
- ✅ Network Policies avançadas
- ✅ Conectividade híbrida complexa
