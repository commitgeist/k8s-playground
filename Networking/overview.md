# 🌐 Overview de Redes - Conceitos Básicos

## 🧱 1️⃣ O que é uma rede (de verdade)

Imagina que tua empresa é um prédio.
- Cada andar é uma "rede" diferente.
- Cada sala dentro do andar tem tomadas de rede com endereços (IPs).

**A rede é o andar** (ex: 10.0.0.x)

**Os computadores são IPs** dentro dessa rede (10.0.0.2, 10.0.0.3...)

**O "síndico"** que liga um andar ao outro é o **roteador**

---

## 🌐 2️⃣ O que é IP e CIDR

Cada máquina tem um **IP** — tipo um CPF.

O **CIDR** (Classless Inter-Domain Routing) é a forma de definir o tamanho da rede.

### Exemplo:
```
10.0.0.0/24
```
→ quer dizer:
- A rede começa no `10.0.0.0`
- `/24` define quantos IPs cabem dentro
- `/24` significa **256 endereços** (de 10.0.0.0 até 10.0.0.255)

### Tabela rápida:

| CIDR | Quantos IPs | Exemplos válidos |
|------|-------------|------------------|
| /30  | 4           | 10.0.0.0 → 10.0.0.3 |
| /24  | 256         | 10.0.0.0 → 10.0.0.255 |
| /16  | 65.536      | 10.0.0.0 → 10.0.255.255 |

### 📘 Dica pra decorar:
**Quanto maior o número depois da barra, menor a rede.**
- `/16` é bem maior que `/24`.

---

## ⚙️ 3️⃣ O que é NAT

**NAT = Network Address Translation**

Ele serve pra "disfarçar" IPs internos com um IP público.

### 💡 Exemplo prático:

**Dentro da tua casa:** tu e tua TV têm IPs locais (tipo 192.168.0.2 e 192.168.0.3).

**Pra sair pra Internet:** o roteador troca teu IP por um IP público (ex: 52.43.11.22).

👉 **Isso é NAT.**
Quem faz a tradução é o roteador (ou, no caso da cloud, o nó do cluster).

---

## ☁️ 4️⃣ Aplicando isso no contexto do Azure

No Azure, tudo fica dentro de **VNets** (Virtual Networks) — que são redes virtuais baseadas em CIDRs.

### Exemplo:
```
VNet: 10.0.0.0/16
  ├─ Subnet1: 10.0.0.0/24 → VMs
  ├─ Subnet2: 10.0.1.0/24 → AKS Nodes
  └─ Subnet3: 10.0.2.0/24 → Banco de Dados
```

- Cada **sub-rede** é como um andar do prédio.
- Tudo dentro da mesma VNet se comunica diretamente (sem NAT).

---

## 🧩 5️⃣ E onde entra o AKS

Quando tu cria um cluster AKS, ele precisa:

1. **Ter nós** (as VMs onde o Kubernetes roda)
2. **Criar pods** (os containers dentro dos nós)
3. **Conectar tudo isso à VNet**

Aí vem a diferença entre **Kubenet** e **Azure CNI**:

| Conceito | Kubenet | Azure CNI |
|----------|---------|-----------|
| **Quem tem IP da VNet** | Só os nós (VMs) | Nós e Pods |

### Kubenet (Simples)
```
VNet: 10.0.0.0/16
  └─ Subnet AKS: 10.0.1.0/24
       ├─ Nó1: 10.0.1.4
       ├─ Nó2: 10.0.1.5
       └─ Pods: 10.244.x.x (rede interna)
```

### Azure CNI (Avançado)
```
VNet: 10.0.0.0/16
  └─ Subnet AKS: 10.0.1.0/24
       ├─ Nó1: 10.0.1.4
       ├─ Pod1: 10.0.1.10
       ├─ Pod2: 10.0.1.11
       └─ Pod3: 10.0.1.12
```

---

## 🔧 6️⃣ Conceitos Importantes

### Inbound vs Outbound
- **Inbound**: Tráfego **chegando** ao teu recurso
- **Outbound**: Tráfego **saindo** do teu recurso

### Load Balancer
- Distribui tráfego entre múltiplos destinos
- Exemplo: 3 pods rodando a mesma aplicação

### Network Security Groups (NSG)
- Firewall do Azure
- Define quem pode entrar e sair

### Private vs Public
- **Private**: Só acessível dentro da VNet
- **Public**: Acessível da Internet

---

## 🎯 7️⃣ Resumo Prático

### Para criar um AKS, você precisa entender:

1. **Qual CIDR usar** para a VNet (ex: 10.0.0.0/16)
2. **Quantos IPs** você vai precisar para pods
3. **Se os pods precisam** ser acessíveis diretamente da VNet
4. **Como conectar** com outras redes (on-premises, outras VNets)

### Regra de ouro:
- **Kubenet**: Mais simples, economiza IPs
- **Azure CNI**: Mais flexível, consome mais IPs

---

## 📚 Próximos Passos

Agora que você entende os conceitos básicos, pode partir para:
- [Azure VNET com AKS](./Azure/VNET.md) - Implementação prática
- [Network Policies](./NetworkPolicies/) - Segurança entre pods
- [Ingress Controllers](../Ingress/) - Exposição de aplicações

---

## 🔗 Referências Úteis

- [Calculadora de CIDR](https://www.subnet-calculator.com/)
- [Documentação Azure VNet](https://docs.microsoft.com/azure/virtual-network/)
- [AKS Networking Concepts](https://docs.microsoft.com/azure/aks/concepts-network)