# AKS + VNET: Networking no Azure Kubernetes Service

## Índice
- [Visão Geral](#visão-geral)
- [Modelos de Rede](#modelos-de-rede)
- [Container Network Interface (CNI)](#container-network-interface-cni)
- [Arquiteturas de Rede](#arquiteturas-de-rede)
- [Implementação Prática](#implementação-prática)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Visão Geral

O Azure Kubernetes Service (AKS) oferece diferentes modelos de rede para integrar clusters Kubernetes com redes virtuais do Azure (VNets). A escolha do modelo correto impacta na escalabilidade, segurança e conectividade do cluster.

### Conceitos Fundamentais

- **VNET (Virtual Network)**: Rede virtual no Azure que permite conectividade segura entre recursos
- **CNI (Container Network Interface)**: Plugin responsável por gerenciar rede em clusters Kubernetes
- **Pod IP**: Endereço IP atribuído aos pods no cluster
- **Node IP**: Endereço IP dos nós do cluster

## Modelos de Rede

### 1. Overlay Networks

Nos modelos overlay, os pods recebem IPs de um CIDR privado e logicamente separado da subnet da VNET onde os nós AKS estão implantados.

#### Características:
- ✅ Conserva espaço de endereços IP da VNET
- ✅ Configuração mais simples
- ✅ Suporte a escalabilidade máxima
- ❌ Um hop adicional para conectividade dos pods
- ❌ Pods não são acessíveis diretamente via IP externo

### 2. Flat Networks

Nos modelos flat, os pods recebem IPs da mesma subnet da VNET dos nós AKS, permitindo acesso direto via IP.

#### Características:
- ✅ Conectividade direta pod-to-pod e pod-to-VM
- ✅ Acesso direto de recursos externos aos pods
- ❌ Requer grande espaço de endereços IP
- ❌ Planejamento complexo de IPs

## Container Network Interface (CNI)

### Comparação dos Plugins CNI

| Plugin | Tipo | Caso de Uso | Limitações |
|--------|------|-------------|------------|
| **Azure CNI Overlay** | Overlay | Recomendado para a maioria dos cenários | 1000 nós, 250 pods/nó |
| **Azure CNI Pod Subnet** | Flat | Acesso direto aos pods necessário | Consome muitos IPs |
| **Azure CNI Node Subnet (Legacy)** | Flat | VNet gerenciada necessária | Uso ineficiente de IPs |
| **Kubenet (Legacy)** | Overlay | Clusters pequenos (<400 nós) | Gerenciamento manual de rotas |

### Azure CNI Overlay (Recomendado)

```yaml
# Características principais
- IP Conservation: ✅ Usa CIDR privado para pods
- Scale Support: ✅ Até 1000 nós e 250 pods por nó  
- Configuration: ✅ Configuração simplificada
- External Access: ❌ Pods não são diretamente acessíveis
```

### Azure CNI Pod Subnet

```yaml
# Características principais
- External Access: ✅ Pods diretamente acessíveis
- IP Usage: ❌ Consome IPs da subnet para cada pod
- Connectivity: ✅ Conectividade bidirecional total
- Scale: ⚠️ Limitado pelo espaço de IPs
```

## Arquiteturas de Rede

### Hub-Spoke com AKS

```
┌─────────────────┐
│   Hub VNet      │
│  ┌───────────┐  │     ┌─────────────────┐
│  │  Gateway  │  │────▶│  On-Premises    │
│  └───────────┘  │     └─────────────────┘
└─────────┬───────┘
          │
          │ VNet Peering
          │
┌─────────▼───────┐
│   Spoke VNet    │
│  ┌───────────┐  │
│  │AKS Cluster│  │
│  └───────────┘  │
└─────────────────┘
```

#### Configuração Hub-Spoke:

1. **Hub VNet**: Contém gateways VPN/ExpressRoute
2. **Spoke VNet**: Contém cluster AKS
3. **Peering**: Conecta Hub e Spoke com gateway transit

### Multi-Region com Global Peering

```
┌─────────────────┐     ┌─────────────────┐
│   East US Hub   │────▶│   West US Hub   │
│  ┌───────────┐  │     │  ┌───────────┐  │
│  │  Gateway  │  │     │  │  Gateway  │  │
│  └───────────┘  │     │  └───────────┘  │
└─────────┬───────┘     └─────────┬───────┘
          │                       │
    ┌─────▼───────┐         ┌─────▼───────┐
    │  Spoke 1    │         │  Spoke 2    │
    │ AKS Cluster │         │ AKS Cluster │
    └─────────────┘         └─────────────┘
```

## Implementação Prática

### 1. Criando AKS com Azure CNI Overlay

```bash
# Criar Resource Group
az group create \
  --name rg-aks-vnet \
  --location eastus

# Criar VNET
az network vnet create \
  --resource-group rg-aks-vnet \
  --name vnet-aks \
  --address-prefixes 10.0.0.0/16

# Criar Subnet para AKS
az network vnet subnet create \
  --resource-group rg-aks-vnet \
  --vnet-name vnet-aks \
  --name subnet-aks \
  --address-prefixes 10.0.1.0/24

# Criar AKS com CNI Overlay
az aks create \
  --resource-group rg-aks-vnet \
  --name aks-overlay \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 192.168.0.0/16 \
  --vnet-subnet-id /subscriptions/{subscription}/resourceGroups/rg-aks-vnet/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/subnet-aks \
  --generate-ssh-keys
```

### 2. Configurando VNET Peering

```bash
# Criar Hub VNET
az network vnet create \
  --resource-group rg-hub \
  --name vnet-hub \
  --address-prefixes 10.1.0.0/16

# Criar Peering Hub -> Spoke
az network vnet peering create \
  --resource-group rg-hub \
  --name hub-to-spoke \
  --vnet-name vnet-hub \
  --remote-vnet vnet-aks \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit

# Criar Peering Spoke -> Hub
az network vnet peering create \
  --resource-group rg-aks-vnet \
  --name spoke-to-hub \
  --vnet-name vnet-aks \
  --remote-vnet vnet-hub \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --use-remote-gateways
```

### 3. Exemplo com Pod Subnet (CNI Flat)

```bash
# Criar subnet dedicada para pods
az network vnet subnet create \
  --resource-group rg-aks-vnet \
  --vnet-name vnet-aks \
  --name subnet-pods \
  --address-prefixes 10.0.2.0/23

# Criar AKS com Pod Subnet
az aks create \
  --resource-group rg-aks-vnet \
  --name aks-pod-subnet \
  --network-plugin azure \
  --vnet-subnet-id /subscriptions/{subscription}/resourceGroups/rg-aks-vnet/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/subnet-aks \
  --pod-subnet-id /subscriptions/{subscription}/resourceGroups/rg-aks-vnet/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/subnet-pods \
  --generate-ssh-keys
```

## Network Security Groups (NSGs)

### Exemplo de NSG para AKS

```bash
# Criar NSG
az network nsg create \
  --resource-group rg-aks-vnet \
  --name nsg-aks

# Permitir tráfego interno do cluster
az network nsg rule create \
  --resource-group rg-aks-vnet \
  --nsg-name nsg-aks \
  --name AllowAKSInternal \
  --priority 100 \
  --source-address-prefixes 10.0.1.0/24 \
  --destination-address-prefixes 10.0.1.0/24 \
  --access Allow \
  --protocol "*" \
  --destination-port-ranges "*"

# Associar NSG à subnet
az network vnet subnet update \
  --resource-group rg-aks-vnet \
  --vnet-name vnet-aks \
  --name subnet-aks \
  --network-security-group nsg-aks
```

## Troubleshooting

### Problemas Comuns

#### 1. Conectividade Pod-to-Pod Falha
```bash
# Verificar configuração CNI
kubectl get nodes -o wide
kubectl describe node <node-name>

# Verificar logs do Azure CNI
kubectl logs -n kube-system -l k8s-app=azure-cni-networkmonitor
```

#### 2. Problemas de Resolução DNS
```bash
# Testar DNS interno
kubectl run test-pod --image=busybox --restart=Never --rm -i --tty -- nslookup kubernetes.default

# Verificar CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

#### 3. Conectividade Externa Falha
```bash
# Verificar rotas
kubectl get nodes -o wide
az network route-table list

# Verificar NSGs
az network nsg show --resource-group rg-aks-vnet --name nsg-aks
```

### Comandos de Diagnóstico

```bash
# Status da rede do cluster
kubectl get nodes -o wide
kubectl get pods -o wide --all-namespaces

# Informações detalhadas do nó
kubectl describe node <node-name>

# Logs do Azure CNI
kubectl logs -n kube-system -l component=azure-cni-networkmonitor

# Verificar conectividade
kubectl exec -it <pod-name> -- ping <target-ip>
kubectl exec -it <pod-name> -- netstat -rn
```

## Best Practices

### 1. Planejamento de Rede

- **Separar por Ambientes**: Use VNETs diferentes para dev/prod
- **CIDR Planning**: Evite sobreposição de CIDRs
- **Subnet Sizing**: Planeje crescimento futuro
- **Reserve Address Space**: Mantenha espaço para expansão

### 2. Segurança

```yaml
# Network Policies Example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 3. Monitoramento

```bash
# Habilitar Network Policy logs
az aks update \
  --resource-group rg-aks-vnet \
  --name aks-cluster \
  --network-policy azure
```

### 4. Conectividade Híbrida

- **Use Gateway Transit**: Para conectividade on-premises
- **Configure UDRs**: Para roteamento customizado
- **Implement Firewall**: Para controle de tráfego
- **Monitor Costs**: VNet peering tem custos

### 5. Escalabilidade

| Modelo | Máx. Nós | Máx. Pods/Nó | IP Usage |
|--------|-----------|---------------|----------|
| CNI Overlay | 1000 | 250 | Eficiente |
| CNI Pod Subnet | 5000* | 250 | Alto |
| Kubenet | 400 | 110 | Baixo |

\* Com modo dinâmico

## Limitações e Considerações

### CNI Overlay
- ❌ Pods não são diretamente roteáveis
- ❌ Limitado a 1000 nós
- ✅ Conserva IPs da VNET

### CNI Pod Subnet  
- ✅ Pods diretamente roteáveis
- ❌ Consome muitos IPs da VNET
- ✅ Melhor para conectividade externa

### Kubenet (Legacy)
- ❌ Limitado a 400 nós
- ❌ Requires UDR management
- ✅ Uso mínimo de IPs

---

## Recursos Adicionais

- [Documentação Oficial AKS Networking](https://docs.microsoft.com/azure/aks/concepts-network)
- [Azure CNI Networking](https://docs.microsoft.com/azure/aks/configure-azure-cni)
- [Network Policies no AKS](https://docs.microsoft.com/azure/aks/use-network-policies)
- [VNET Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
