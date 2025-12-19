# netshoot - Troubleshooting de Rede no Kubernetes

## O que é netshoot?

netshoot é uma imagem Docker criada pela Nicolaka que contém dezenas de ferramentas de rede para debugging e troubleshooting em containers e Kubernetes.

**Imagem:** `nicolaka/netshoot`

---

## Por que usar netshoot?

Imagens de produção geralmente são minimalistas e não têm ferramentas de debug. netshoot resolve isso:

- Todas as ferramentas de rede já instaladas
- Imagem otimizada para troubleshooting
- Atualizada regularmente
- Muito usada pela comunidade
- Perfeita para debug rápido

---

## Ferramentas Incluídas

### Diagnóstico de DNS
- `nslookup` - Consulta DNS simples
- `dig` - Consulta DNS detalhada
- `host` - Resolução de hostname

### Conectividade
- `ping` - Testar conectividade ICMP
- `traceroute` - Rastrear rota de pacotes
- `mtr` - Traceroute contínuo
- `curl` - Cliente HTTP
- `wget` - Download de arquivos
- `nc` (netcat) - Cliente/servidor TCP/UDP
- `telnet` - Cliente telnet

### Análise de Rede
- `tcpdump` - Captura de pacotes
- `nmap` - Scanner de portas
- `netstat` - Estatísticas de rede
- `ss` - Socket statistics
- `iftop` - Monitor de tráfego
- `iperf3` - Teste de performance

### Outros
- `vim`, `nano` - Editores
- `jq` - Parser JSON
- `python`, `node` - Linguagens
- `git` - Controle de versão

---

## Casos de Uso

### 1. Debug de DNS

```bash
# Pod temporário
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Dentro do pod:
# Testar resolução de serviço
nslookup nginx-service.default.svc.cluster.local

# Query DNS detalhada
dig kubernetes.default.svc.cluster.local

# Testar DNS externo
nslookup google.com

# Ver configuração DNS
cat /etc/resolv.conf
```

### 2. Testar Conectividade HTTP

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Testar Service
curl http://nginx-service

# Testar com FQDN
curl http://api.default.svc.cluster.local:8080

# Ver headers e detalhes
curl -v http://nginx-service/health

# Testar Ingress
curl -H "Host: myapp.local" http://ingress-nginx-controller.ingress-nginx
```

### 3. Testar Conectividade TCP/UDP

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Testar porta TCP
nc -zv nginx-service 80

# Testar porta UDP
nc -zvu dns-service 53

# Testar conectividade com timeout
timeout 5 nc -zv database 5432
```

### 4. Debug de Rede entre Pods

```bash
# Deploy permanente
kubectl run netshoot --image=nicolaka/netshoot -- sleep infinity

# Exec no pod
kubectl exec -it netshoot -- bash

# Testar ping para outro pod
ping 10.244.1.5

# Traceroute
traceroute google.com

# MTR (traceroute contínuo)
mtr -n 8.8.8.8
```

### 5. Capturar Tráfego de Rede

```bash
kubectl exec -it netshoot -- bash

# Capturar tráfego HTTP
tcpdump -i eth0 -n port 80

# Capturar e salvar em arquivo
tcpdump -i eth0 -w /tmp/capture.pcap

# Filtrar por host
tcpdump -i eth0 host 10.96.1.5
```

### 6. Testar Performance de Rede

```bash
# Pod servidor
kubectl run iperf-server --image=nicolaka/netshoot -- iperf3 -s

# Pod cliente
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
iperf3 -c iperf-server

# Testar UDP
iperf3 -c iperf-server -u -b 100M
```

### 7. Scanner de Portas

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Scan de portas
nmap -p 80,443,8080 nginx-service

# Scan de range
nmap -p 1-1000 10.96.1.5
```

### 8. Debug de NetworkPolicy

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Testar se consegue acessar pod em outro namespace
curl http://api.production.svc.cluster.local

# Testar porta específica
nc -zv database.production.svc.cluster.local 5432
```

---

## Exemplos de Manifests

Ver pasta [examples/](examples/) para manifestos prontos.

---

## Comandos Úteis

### Pod Temporário (Descartável)
```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
```

### Pod Permanente
```bash
kubectl run netshoot --image=nicolaka/netshoot -- sleep infinity
kubectl exec -it netshoot -- bash
```

### Debug em Namespace Específico
```bash
kubectl run netshoot -n production --rm -it --image=nicolaka/netshoot -- bash
```

### Com Capabilities Extras (para tcpdump)
```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot \
  --overrides='{"spec":{"containers":[{"name":"netshoot","image":"nicolaka/netshoot","stdin":true,"tty":true,"securityContext":{"capabilities":{"add":["NET_ADMIN","NET_RAW"]}}}]}}' \
  -- bash
```

---

## Troubleshooting com netshoot

### Problema: DNS não resolve

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# 1. Ver configuração DNS
cat /etc/resolv.conf

# 2. Testar DNS do cluster
nslookup kubernetes.default

# 3. Testar DNS externo
nslookup google.com

# 4. Query direto no CoreDNS
dig @10.96.0.10 nginx-service.default.svc.cluster.local
```

### Problema: Service não responde

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# 1. Testar conectividade
curl -v http://nginx-service

# 2. Testar porta
nc -zv nginx-service 80

# 3. Ver se resolve DNS
nslookup nginx-service

# 4. Testar IP direto do Service
curl http://10.96.1.5
```

### Problema: Pods não se comunicam

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# 1. Ping para outro pod
ping 10.244.1.5

# 2. Traceroute
traceroute 10.244.1.5

# 3. Testar porta
nc -zv 10.244.1.5 8080

# 4. Verificar rota
ip route
```

### Problema: Lentidão de rede

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# 1. Testar latência
ping -c 10 nginx-service

# 2. Testar throughput
iperf3 -c iperf-server

# 3. MTR para ver onde está o problema
mtr -n nginx-service

# 4. Monitorar tráfego
iftop -i eth0
```

---

## Alternativas ao netshoot

| Ferramenta | Tamanho | Ferramentas | Quando Usar |
|------------|---------|-------------|-------------|
| **netshoot** | ~400MB | Todas | Troubleshooting completo |
| **busybox** | ~5MB | Básicas | Debug simples, ambiente restrito |
| **alpine** | ~7MB | Instalar manualmente | Customização |
| **ubuntu/debian** | ~100MB | Instalar manualmente | Familiaridade |

---

## Boas Práticas

### Recomendado

- Use pod temporário (`--rm`) para debug rápido
- Delete pods de debug após uso
- Use em namespace específico quando necessário
- Adicione capabilities apenas quando necessário (tcpdump)

### Evitar

- Deixar pods de debug rodando indefinidamente
- Usar em produção sem necessidade
- Expor pods de debug externamente
- Dar privilégios desnecessários

---

## Recursos Adicionais

- [netshoot GitHub](https://github.com/nicolaka/netshoot)
- [Documentação Oficial](https://github.com/nicolaka/netshoot/blob/master/README.md)
- [Kubernetes Network Troubleshooting](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [CoreDNS Troubleshooting](../CoreDNS/troubleshooting.md)

