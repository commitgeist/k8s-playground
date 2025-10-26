# 🌐 Fundamentos de Rede - Base Necessária

## 🎯 O que você vai aprender aqui

Este documento explica **APENAS** o que você precisa saber sobre redes para entender Kubernetes e Azure. Sem enrolação, sem teoria desnecessária.

---

## 🏠 1. O que é uma REDE (conceito real)

### Analogia da Casa
Imagina que você mora em um **condomínio**:

```
🏢 Condomínio (Internet)
  🏠 Sua Casa (Rede Local - 192.168.1.0/24)
    📱 Seu Celular (192.168.1.10)
    💻 Seu Notebook (192.168.1.11)
    📺 Smart TV (192.168.1.12)
    🖨️ Impressora (192.168.1.13)
```

**Conceitos importantes:**
- **Rede = sua casa** (todos os dispositivos dentro conseguem se falar)
- **IP = endereço do dispositivo** (tipo número do apartamento)
- **Roteador = porteiro** (controla quem entra e sai)

---

## 🔢 2. O que é IP

**IP = endereço único de cada dispositivo na rede**

### Formato: 4 números separados por ponto
```
192.168.1.10
 │   │   │ │
 │   │   │ └─ Dispositivo específico (1-254)
 │   │   └─── Sub-rede (0-255)
 │   └─────── Rede local (168 = rede privada)
 └─────────── Classe da rede (192 = rede privada)
```

### Tipos de IP:
- **IP Privado**: Só funciona dentro da sua rede
  - `192.168.x.x` (casa/empresa)
  - `10.x.x.x` (empresas grandes)
  - `172.16.x.x` até `172.31.x.x` (empresas médias)

- **IP Público**: Funciona na Internet
  - `8.8.8.8` (Google DNS)
  - `1.1.1.1` (Cloudflare DNS)

---

## 📏 3. O que é CIDR (o mais importante!)

**CIDR = forma de definir quantos IPs cabem na rede**

### Formato: IP/número
```
192.168.1.0/24
            │
            └─ Quantos IPs cabem (24 = 256 IPs)
```

### 🧮 Tabela de CIDR (decore esta!)

| CIDR | Quantos IPs | Faixa de IPs | Uso Comum |
|------|-------------|--------------|-----------|
| `/30` | 4 IPs | .0 até .3 | Conexão ponto-a-ponto |
| `/28` | 16 IPs | .0 até .15 | Rede muito pequena |
| `/24` | 256 IPs | .0 até .255 | Rede doméstica/pequena empresa |
| `/20` | 4.096 IPs | .0 até .15.255 | Empresa média |
| `/16` | 65.536 IPs | .0.0 até .255.255 | Empresa grande |
| `/8` | 16.777.216 IPs | .0.0.0 até .255.255.255 | Muito grande |

### 🎯 Regra de Ouro:
**Quanto MAIOR o número após a `/`, MENOR a rede**
- `/8` = rede GIGANTE
- `/30` = rede MINÚSCULA

### 💡 Exemplos Práticos:

#### Rede `/24` (256 IPs):
```
10.0.1.0/24
├─ 10.0.1.0 (endereço da rede - não usar)
├─ 10.0.1.1 (primeiro IP utilizável)
├─ 10.0.1.2 (segundo IP utilizável)
├─ ...
├─ 10.0.1.254 (último IP utilizável)
└─ 10.0.1.255 (broadcast - não usar)
```

#### Rede `/16` (65.536 IPs):
```
10.0.0.0/16
├─ 10.0.0.1 até 10.0.0.254
├─ 10.0.1.1 até 10.0.1.254
├─ 10.0.2.1 até 10.0.2.254
├─ ...
└─ 10.0.255.1 até 10.0.255.254
```

---

## 🔄 4. O que é NAT (Network Address Translation)

**NAT = tradutor de IPs privados para públicos**

### 🏠 Analogia do Correio:
Imagina que você mora em um **prédio** e quer receber uma **encomenda**:

```
📦 Entregador (Internet)
  ↓
🏢 Porteiro (Roteador com NAT)
  ↓
🚪 Seu Apartamento (Seu Dispositivo)
```

**Como funciona:**
1. **Você** (192.168.1.10) quer acessar **Google** (8.8.8.8)
2. **Roteador** troca seu IP privado pelo IP público dele
3. **Google** responde para o IP público do roteador
4. **Roteador** traduz de volta e entrega pra você

### 📊 Exemplo Visual:

#### Sem NAT (não funciona):
```
❌ Seu PC (192.168.1.10) → Internet
   Internet não conhece 192.168.1.10
```

#### Com NAT (funciona):
```
✅ Seu PC (192.168.1.10) → Roteador → Internet (200.100.50.25)
   Internet responde para 200.100.50.25 → Roteador → Seu PC
```

### 🎯 Por que NAT existe?
- **IPs públicos são limitados** (e caros)
- **IPs privados são infinitos** (e gratuitos)
- **NAT permite** que milhões de dispositivos privados usem poucos IPs públicos

---

## 🌐 5. Aplicando no Azure/Kubernetes

### No Azure:
```
🌍 Internet
  ↓
🔄 Load Balancer (IP Público: 52.123.45.67)
  ↓ (NAT)
🏠 VNet (10.0.0.0/16)
  ├─ Subnet AKS (10.0.1.0/24)
  │   ├─ Nó1 (10.0.1.4)
  │   └─ Nó2 (10.0.1.5)
  └─ Subnet VMs (10.0.2.0/24)
      ├─ VM1 (10.0.2.4)
      └─ VM2 (10.0.2.5)
```

### No Kubernetes:
- **Kubenet**: Pods têm IPs privados (10.244.x.x) + NAT
- **Azure CNI**: Pods têm IPs da VNet (10.0.x.x) + sem NAT interno

---

## 🧪 6. Testando seu Conhecimento

### Exercício 1: Quantos IPs?
```
10.0.0.0/20 = ? IPs
10.0.0.0/28 = ? IPs
192.168.1.0/25 = ? IPs
```

### Exercício 2: Qual é maior?
```
A) 10.0.0.0/16
B) 10.0.0.0/24
```

### Exercício 3: NAT ou não?
```
Cenário: Pod (10.244.1.5) quer acessar Google (8.8.8.8)
Precisa de NAT? Por quê?
```

---

## 🔧 7. Comandos Úteis

### Ver sua rede atual:
```bash
# Linux/Mac
ip route show
ifconfig

# Windows
ipconfig
route print

# Kubernetes
kubectl get nodes -o wide
kubectl get pods -o wide
```

### Testar conectividade:
```bash
# Ping básico
ping 8.8.8.8

# Trace route (ver caminho)
traceroute 8.8.8.8

# DNS lookup
nslookup google.com
```

---

## 🎯 8. Resumo Final

### O que você PRECISA lembrar:
1. **IP = endereço único** (tipo CPF do dispositivo)
2. **CIDR = tamanho da rede** (/24 = 256 IPs, /16 = 65.536 IPs)
3. **NAT = tradutor** (IP privado ↔ IP público)
4. **Rede privada = dentro de casa** (192.168.x.x, 10.x.x.x)
5. **Rede pública = Internet** (qualquer outro IP)

### Regras de Ouro:
- **Maior número após `/` = rede menor**
- **IPs privados precisam de NAT para Internet**
- **Tudo na mesma rede se comunica diretamente**

---

## 📚 Próximos Passos

Agora que você entende os fundamentos, pode partir para:
- [Overview de Redes](./overview.md) - Aplicação no Kubernetes
- [Azure VNET](./Azure/VNET.md) - Implementação prática
- [Kubenet vs CNI](./kubenet-vs-cni.md) - Diferenças detalhadas

---

## 🆘 Respostas dos Exercícios

### Exercício 1:
- `10.0.0.0/20` = 4.096 IPs
- `10.0.0.0/28` = 16 IPs  
- `192.168.1.0/25` = 128 IPs

### Exercício 2:
- **A) 10.0.0.0/16** é maior (65.536 IPs vs 256 IPs)

### Exercício 3:
- **SIM, precisa de NAT** porque 10.244.1.5 é IP privado e não roteável na Internet