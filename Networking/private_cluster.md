# 🔒 AKS Private Cluster - Guia Completo

## 🎯 O que é um Private Cluster?

Um **Private Cluster** é um cluster AKS onde o **API Server** (plano de controle) só é acessível através de IPs privados, não da Internet pública.

### 🏗️ Arquitetura Normal vs Private

#### Cluster Normal (Public):
```
🌍 Internet
  ↓
🔓 API Server (IP Público: 52.123.45.67:443)
  ↓
🏠 VNet (10.0.0.0/16)
  └─ Nós AKS (10.0.1.x)
```

#### Private Cluster:
```
🌍 Internet ❌ (bloqueado)
  
🏠 VNet (10.0.0.0/16)
  ├─ 🔒 API Server (IP Privado: 10.0.0.10:443)
  ├─ 🖥️ VM Jumpbox (10.0.2.5)
  └─ 🎯 Nós AKS (10.0.1.x)
```

---

## 🔐 Por que usar Private Cluster?

### ✅ **Vantagens:**
- **Segurança máxima**: API Server não exposto na Internet
- **Compliance**: Atende requisitos de segurança corporativa
- **Controle de acesso**: Só quem está na VNet consegue acessar
- **Zero trust**: Reduz superfície de ataque

### ❌ **Desvantagens:**
- **Complexidade**: Precisa de VM/VPN para acessar
- **CI/CD**: Pipelines precisam estar na mesma rede
- **Troubleshooting**: Mais difícil debugar remotamente

---

## 🏗️ Como Criar um Private Cluster

### Método 1: Azure CLI
```bash
# Criar Resource Group
az group create --name rg-private-aks --location eastus

# Criar VNet
az network vnet create \
  --resource-group rg-private-aks \
  --name vnet-private \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name subnet-aks \
  --subnet-prefix 10.0.1.0/24

# Criar Private AKS
az aks create \
  --resource-group rg-private-aks \
  --name aks-private \
  --network-plugin azure \
  --vnet-subnet-id /subscriptions/{subscription}/resourceGroups/rg-private-aks/providers/Microsoft.Network/virtualNetworks/vnet-private/subnets/subnet-aks \
  --enable-private-cluster \
  --private-dns-zone system \
  --generate-ssh-keys
```

### Método 2: Terraform
```hcl
resource "azurerm_kubernetes_cluster" "private" {
  name                = "aks-private"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-private"
  
  private_cluster_enabled = true
  private_dns_zone_id     = "System"
  
  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks.id
  }
  
  network_profile {
    network_plugin = "azure"
  }
}
```

---

## 🖥️ Como Acessar um Private Cluster

### Opção 1: VM Jumpbox na mesma VNet
```bash
# 1. Criar VM na mesma VNet
az vm create \
  --resource-group rg-private-aks \
  --name vm-jumpbox \
  --image Ubuntu2204 \
  --vnet-name vnet-private \
  --subnet subnet-jumpbox \
  --admin-username azureuser \
  --generate-ssh-keys

# 2. SSH na VM
ssh azureuser@<VM-PUBLIC-IP>

# 3. Instalar kubectl na VM
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 4. Instalar Azure CLI na VM
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 5. Login e pegar credenciais
az login
az aks get-credentials --resource-group rg-private-aks --name aks-private

# 6. Testar acesso
kubectl get nodes
```

### Opção 2: VPN Gateway
```bash
# Criar VPN Gateway para conectar sua rede local
az network vnet-gateway create \
  --resource-group rg-private-aks \
  --name vpn-gateway \
  --vnet vnet-private \
  --public-ip-addresses pip-vpn \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw1
```

### Opção 3: VNet Peering
```bash
# Conectar com outra VNet onde você tem acesso
az network vnet peering create \
  --resource-group rg-private-aks \
  --name private-to-hub \
  --vnet-name vnet-private \
  --remote-vnet vnet-hub \
  --allow-vnet-access
```

---

## 🔍 Como Identificar se é Private Cluster

### Via Azure CLI:
```bash
# Verificar se é private
az aks show --resource-group SEU-RG --name SEU-CLUSTER --query apiServerAccessProfile.enablePrivateCluster -o tsv

# Ver FQDN privado
az aks show --resource-group SEU-RG --name SEU-CLUSTER --query privateFqdn -o tsv

# Ver FQDN público (se existir)
az aks show --resource-group SEU-RG --name SEU-CLUSTER --query fqdn -o tsv
```

### Via kubectl (se já conectado):
```bash
# Ver endpoint do API Server
kubectl cluster-info

# Se mostrar IP privado (10.x.x.x) = Private Cluster
# Se mostrar IP público = Cluster Normal
```

---

## 🚨 Troubleshooting Comum

### Problema 1: "Unable to connect to the server"
```bash
# Erro comum quando tenta acessar de fora da VNet
Error: Unable to connect to the server: dial tcp 52.123.45.67:443: i/o timeout

# Solução: Acessar de dentro da VNet (VM, VPN, etc.)
```

### Problema 2: DNS não resolve
```bash
# Verificar DNS privado
nslookup aks-private-12345678.hcp.eastus.azmk8s.io

# Se não resolver, verificar Private DNS Zone
az network private-dns zone list --resource-group MC_rg-private-aks_aks-private_eastus
```

### Problema 3: CI/CD não consegue acessar
```bash
# Opções para CI/CD:
# 1. Self-hosted agents na mesma VNet
# 2. VPN connection
# 3. Authorized IP ranges (híbrido)

# Híbrido - permitir IPs específicos
az aks update \
  --resource-group rg-private-aks \
  --name aks-private \
  --api-server-authorized-ip-ranges "203.0.113.0/24,198.51.100.0/24"
```

---

## 🎯 Cenários de Uso

### ✅ **Use Private Cluster quando:**
- Compliance/segurança exige isolamento total
- Dados sensíveis (financeiro, saúde, governo)
- Ambiente corporativo com VPN já estabelecida
- Zero trust architecture

### ❌ **NÃO use Private Cluster quando:**
- Desenvolvimento/teste simples
- Equipe pequena sem infraestrutura de rede
- CI/CD na nuvem pública (GitHub Actions, etc.)
- Prototipagem rápida

---

## 📊 Comparação: Public vs Private vs Hybrid

| Aspecto | Public Cluster | Private Cluster | Hybrid (Authorized IPs) |
|---------|----------------|-----------------|-------------------------|
| **Segurança** | 🟡 Média | 🟢 Alta | 🟡 Média-Alta |
| **Complexidade** | 🟢 Baixa | 🔴 Alta | 🟡 Média |
| **CI/CD** | 🟢 Fácil | 🔴 Complexo | 🟡 Médio |
| **Custo** | 🟢 Baixo | 🔴 Alto | 🟡 Médio |
| **Acesso Remoto** | 🟢 Direto | 🔴 VPN/VM | 🟡 IPs Autorizados |

---

## 🔗 Referências

- [AKS Private Clusters - Microsoft Docs](https://docs.microsoft.com/azure/aks/private-clusters)
- [Private DNS Zones](https://docs.microsoft.com/azure/dns/private-dns-overview)
- [VNet Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)

---

## 💡 Dicas Finais

1. **Planeje a rede antes**: Private clusters exigem arquitetura bem pensada
2. **Teste o acesso**: Sempre valide conectividade antes de ir para produção
3. **Documente bem**: Equipe precisa saber como acessar
4. **Monitore custos**: VMs jumpbox e VPN gateways custam dinheiro
5. **Backup de acesso**: Tenha sempre 2+ formas de acessar o cluster