# 🚨 CoreDNS Troubleshooting - Guia Prático

## 🔍 Diagnóstico Rápido

### Checklist de 5 Minutos
```bash
# 1. CoreDNS está rodando?
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Tem erros nos logs?
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# 3. Configuração está ok?
kubectl describe configmap coredns -n kube-system

# 4. DNS interno funciona?
kubectl run test --image=busybox --rm -i --tty -- nslookup kubernetes.default

# 5. DNS externo funciona?
kubectl run test --image=busybox --rm -i --tty -- nslookup google.com
```

---

## 🚫 Problemas Mais Comuns

### 1. "Could not resolve host" (DNS interno)

**Sintomas:**
```bash
curl: (6) Could not resolve host: nginx-service
```

**Diagnóstico:**
```bash
# Verificar se serviço existe
kubectl get svc nginx-service

# Verificar se CoreDNS está rodando
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Ver logs do CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Soluções:**
```bash
# Solução 1: Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Solução 2: Verificar CNI
kubectl get pods -n kube-system | grep -E "(calico|flannel|weave)"

# Solução 3: Escalar CoreDNS
kubectl scale deployment coredns --replicas=2 -n kube-system
```

### 2. DNS externo não funciona

**Sintomas:**
```bash
curl: (6) Could not resolve host: google.com
```

**Diagnóstico:**
```bash
# Verificar configuração do forward
kubectl describe configmap coredns -n kube-system | grep forward

# Verificar DNS do nó
kubectl get nodes -o wide
# SSH no nó e verificar:
cat /etc/resolv.conf
```

**Soluções:**
```bash
# Solução 1: Corrigir forward no Corefile
kubectl edit configmap coredns -n kube-system
# Adicionar: forward . 8.8.8.8 8.8.4.4

# Solução 2: Usar DNS do sistema
# forward . /etc/resolv.conf
```

### 3. CoreDNS crashando constantemente

**Sintomas:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# STATUS: CrashLoopBackOff
```

**Diagnóstico:**
```bash
# Ver eventos
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Ver recursos
kubectl top pods -n kube-system

# Ver logs de crash
kubectl logs -n kube-system -l k8s-app=kube-dns --previous
```

**Soluções:**
```bash
# Solução 1: Aumentar recursos
kubectl edit deployment coredns -n kube-system
# resources:
#   requests:
#     memory: "170Mi"
#     cpu: "100m"

# Solução 2: Verificar Corefile
kubectl describe configmap coredns -n kube-system
# Procurar por sintaxe inválida

# Solução 3: Resetar configuração
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml
# Restaurar configuração padrão
```

### 4. Resolução DNS muito lenta

**Sintomas:**
```bash
# Demora > 5 segundos para resolver
time nslookup kubernetes.default
```

**Diagnóstico:**
```bash
# Verificar cache
kubectl describe configmap coredns -n kube-system | grep cache

# Verificar número de réplicas
kubectl get deployment coredns -n kube-system

# Verificar recursos
kubectl top pods -n kube-system -l k8s-app=kube-dns
```

**Soluções:**
```bash
# Solução 1: Aumentar cache
kubectl edit configmap coredns -n kube-system
# cache 30 → cache 300

# Solução 2: Mais réplicas
kubectl scale deployment coredns --replicas=3 -n kube-system

# Solução 3: Mais recursos
kubectl edit deployment coredns -n kube-system
```

---

## 🔧 Scripts de Debug

### Script Completo de Diagnóstico
```bash
#!/bin/bash
echo "=== CoreDNS Health Check ==="

echo "1. Verificando pods do CoreDNS..."
kubectl get pods -n kube-system -l k8s-app=kube-dns

echo -e "\n2. Verificando logs (últimas 10 linhas)..."
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=10

echo -e "\n3. Verificando configuração..."
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}'

echo -e "\n4. Testando DNS interno..."
kubectl run dns-test --image=busybox --restart=Never --rm -i --tty -- nslookup kubernetes.default 2>/dev/null || echo "FALHOU"

echo -e "\n5. Testando DNS externo..."
kubectl run dns-test --image=busybox --restart=Never --rm -i --tty -- nslookup google.com 2>/dev/null || echo "FALHOU"

echo -e "\n6. Verificando recursos..."
kubectl top pods -n kube-system -l k8s-app=kube-dns 2>/dev/null || echo "Metrics server não disponível"

echo -e "\n=== Fim do diagnóstico ==="
```

### Script de Teste de DNS
```bash
#!/bin/bash
echo "=== Teste Completo de DNS ==="

# Criar pod de teste
kubectl run dns-debug --image=busybox --restart=Never --rm -i --tty -- sh -c "
echo 'Testando resolução DNS...'
echo '1. DNS interno (kubernetes):'
nslookup kubernetes.default
echo '2. DNS interno (kube-dns):'
nslookup kube-dns.kube-system.svc.cluster.local
echo '3. DNS externo (google):'
nslookup google.com
echo '4. Configuração do pod:'
cat /etc/resolv.conf
echo '5. Teste de conectividade:'
ping -c 3 8.8.8.8
"
```

---

## 📊 Monitoramento e Alertas

### Métricas Importantes
```bash
# Habilitar métricas no CoreDNS
kubectl edit configmap coredns -n kube-system
# Adicionar plugin: prometheus :9153

# Acessar métricas
kubectl port-forward -n kube-system svc/kube-dns 9153:9153
curl http://localhost:9153/metrics | grep coredns
```

### Alertas Recomendados
```yaml
# Prometheus AlertManager rules
groups:
- name: coredns
  rules:
  - alert: CoreDNSDown
    expr: up{job="coredns"} == 0
    for: 5m
    
  - alert: CoreDNSHighErrorRate
    expr: rate(coredns_dns_responses_total{rcode!="NOERROR"}[5m]) > 0.1
    for: 2m
    
  - alert: CoreDNSHighLatency
    expr: histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m])) > 1
    for: 5m
```

---

## 🔄 Procedimentos de Recuperação

### Recuperação Rápida
```bash
# 1. Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# 2. Aguardar pods ficarem prontos
kubectl rollout status deployment coredns -n kube-system

# 3. Testar funcionamento
kubectl run test --image=busybox --rm -i --tty -- nslookup kubernetes.default
```

### Recuperação Completa
```bash
# 1. Backup da configuração atual
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# 2. Resetar para configuração padrão
kubectl delete configmap coredns -n kube-system
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        reload
    }
EOF

# 3. Reiniciar deployment
kubectl rollout restart deployment coredns -n kube-system
```

---

## 💡 Dicas de Prevenção

### ✅ **Boas Práticas:**
- Monitorar logs do CoreDNS diariamente
- Fazer backup do ConfigMap antes de mudanças
- Testar DNS após mudanças no cluster
- Manter pelo menos 2 réplicas do CoreDNS
- Configurar alertas para falhas de DNS

### ❌ **Evitar:**
- Modificar Corefile sem entender o impacto
- Rodar CoreDNS com recursos insuficientes
- Ignorar erros nos logs
- Cache muito baixo (< 10s) ou muito alto (> 600s)
- Deletar CoreDNS sem ter backup

---

## 🆘 Quando Pedir Ajuda

### Colete essas informações:
```bash
# 1. Versão do Kubernetes
kubectl version --short

# 2. Status do CoreDNS
kubectl get all -n kube-system -l k8s-app=kube-dns

# 3. Logs completos
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100

# 4. Configuração atual
kubectl get configmap coredns -n kube-system -o yaml

# 5. Eventos do sistema
kubectl get events -n kube-system --sort-by='.lastTimestamp' | tail -20

# 6. Informações do cluster
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

🚀 **Com essas informações, qualquer problema de CoreDNS pode ser resolvido!**