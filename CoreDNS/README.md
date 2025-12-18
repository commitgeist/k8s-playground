# CoreDNS no Kubernetes

---

## O que é o CoreDNS?

O CoreDNS é o servidor DNS padrão do Kubernetes que fornece:
- **Service Discovery**: Resolução de serviços pelo nome
- **Resolução dinâmica**: Atualização automática quando serviços mudam
- **DNS externo**: Resolução de domínios da Internet
- **Performance**: Cache e otimizações

### Analogia
O CoreDNS funciona como uma "lista telefônica" do cluster:
- Aplicação solicita: `nginx-service`
- CoreDNS responde: `10.96.1.5`

---

## Como Funciona

### Resolução Interna (Kubernetes)
```bash
# Pod faz requisição para outro serviço
curl http://nginx-service

# CoreDNS resolve para:
# nginx-service.default.svc.cluster.local → 10.96.1.5
```

### Resolução Externa (Internet)
```bash
# Pod faz requisição externa
curl http://google.com

# CoreDNS encaminha para DNS externo (8.8.8.8)
```

### Fluxo Completo
```
Pod → CoreDNS → Serviço/Internet
  ↓       ↓           ↓
curl  resolve     resposta
nginx 10.96.1.5
```

---

## Principais Funcionalidades

### Service Discovery
```bash
# Formatos de DNS que funcionam:
nginx-service                           # Mesmo namespace
nginx-service.production               # Namespace específico
nginx-service.production.svc.cluster.local  # FQDN completo
```

### Atualizações Dinâmicas
- Serviço criado: DNS automaticamente disponível
- Serviço deletado: DNS automaticamente removido
- Endpoints mudam: IPs atualizados em tempo real

### Cache Inteligente
- Respostas ficam em cache por 30s (padrão)
- Reduz latência e carga no API Server
- Cache limpo automaticamente quando serviços mudam

### Extensibilidade
- Sistema de plugins modular
- Logs, métricas, health checks
- Regras customizadas

---

## Configuração do CoreDNS

### Ver Configuração Atual
```bash
# Ver ConfigMap do CoreDNS
kubectl get configmap coredns -n kube-system -o yaml

# Ver apenas o Corefile
kubectl describe configmap coredns -n kube-system
```

### Exemplo de Corefile
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors                    # Log de erros
        health                    # Health check endpoint
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure         # Resolve nomes de pods
            fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf  # Encaminha para DNS externo
        cache 30                  # Cache por 30 segundos
        log                       # Log de queries
        reload                    # Recarrega config automaticamente
    }
```

### Plugins Principais

| Plugin | Função | Exemplo |
|--------|--------|---------|
| `kubernetes` | Resolve serviços K8s | `nginx.default.svc.cluster.local` |
| `forward` | Encaminha para DNS externo | `google.com → 8.8.8.8` |
| `cache` | Cache de respostas | Cache por 30s |
| `errors` | Log de erros | Debug de problemas |
| `health` | Health check | `/health` endpoint |
| `log` | Log de queries | Debug de requisições |

---

## Comandos Úteis para Debug

### Verificar Status do CoreDNS
```bash
# Ver pods do CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Ver logs do CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Ver deployment
kubectl get deployment coredns -n kube-system

# Escalar CoreDNS (se necessário)
kubectl scale deployment coredns --replicas=2 -n kube-system
```

### Testar Resolução DNS
```bash
# Criar pod de teste
kubectl run test-dns --image=busybox --restart=Never --rm -i --tty -- sh

# Dentro do pod, testar DNS:
nslookup kubernetes.default
nslookup google.com
cat /etc/resolv.conf
```

### Ver Serviços DNS
```bash
# Ver serviço do CoreDNS
kubectl get svc -n kube-system

# Resultado esperado:
# kube-dns   ClusterIP   10.96.0.10   <none>   53/UDP,53/TCP
```

---

## Troubleshooting Comum

### Problema 1: DNS não resolve serviços internos
```bash
# Sintomas:
curl: (6) Could not resolve host: nginx-service

# Debug:
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Soluções:
# 1. Verificar se CoreDNS está rodando
# 2. Verificar se CNI está instalado
# 3. Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system
```

### Problema 2: DNS externo não funciona
```bash
# Sintomas:
curl: (6) Could not resolve host: google.com

# Debug:
kubectl describe configmap coredns -n kube-system

# Verificar se tem linha:
# forward . /etc/resolv.conf

# Solução: Verificar DNS do nó
kubectl get nodes -o wide
ssh node-ip
cat /etc/resolv.conf
```

### Problema 3: CoreDNS crashando
```bash
# Ver eventos
kubectl get events -n kube-system --sort-by='.lastTimestamp'

# Ver recursos
kubectl top pods -n kube-system

# Possíveis causas:
# 1. Falta de recursos (CPU/Memory)
# 2. CNI não instalado
# 3. Configuração inválida no Corefile
```

### Problema 4: Resolução lenta
```bash
# Verificar cache
kubectl describe configmap coredns -n kube-system | grep cache

# Aumentar cache se necessário
# cache 30 → cache 300 (5 minutos)

# Verificar número de réplicas
kubectl get deployment coredns -n kube-system
kubectl scale deployment coredns --replicas=3 -n kube-system
```

---

## Cenários Práticos

### Cenário 1: Aplicação não encontra banco
```bash
# Aplicação tenta conectar em:
mysql-service.database.svc.cluster.local

# Verificar se serviço existe:
kubectl get svc -n database

# Testar resolução:
kubectl run test --image=busybox --rm -i --tty -- nslookup mysql-service.database.svc.cluster.local
```

### Cenário 2: Microserviços não se comunicam
```bash
# Service A tenta chamar Service B
curl http://service-b:8080/api

# Debug:
kubectl get svc  # Ver se service-b existe
kubectl get endpoints service-b  # Ver se tem pods
kubectl run test --image=busybox --rm -i --tty -- nslookup service-b
```

### Cenário 3: Pods não acessam Internet
```bash
# Testar conectividade externa
kubectl run test --image=busybox --rm -i --tty -- nslookup google.com

# Se falhar, verificar:
kubectl describe configmap coredns -n kube-system
# Deve ter: forward . /etc/resolv.conf
```

---

## Monitoramento do CoreDNS

### Métricas Importantes
```bash
# Endpoint de métricas (se habilitado)
kubectl port-forward -n kube-system svc/kube-dns 9153:9153
curl http://localhost:9153/metrics

# Métricas principais:
# - coredns_dns_request_duration_seconds
# - coredns_dns_requests_total
# - coredns_cache_hits_total
```

### Health Check
```bash
# Endpoint de health
kubectl port-forward -n kube-system svc/kube-dns 8080:8080
curl http://localhost:8080/health
```

---

## Customizações Avançadas

### Adicionar DNS Customizado
```yaml
# Adicionar no Corefile:
.:53 {
    # ... configuração existente ...
    
    # DNS customizado para domínio específico
    hosts {
        192.168.1.100 meu-app.local
        fallthrough
    }
}
```

### Configurar DNS Condicional
```yaml
# Encaminhar domínio específico para DNS específico
company.local:53 {
    forward . 192.168.1.10
}
```

### Habilitar Logs Detalhados
```yaml
.:53 {
    # ... outras configurações ...
    log . {
        class denial error
    }
}
```

---

## Boas Práticas

### Recomendado:
- Monitorar logs do CoreDNS regularmente
- Manter cache em 30-300 segundos
- Usar FQDNs para comunicação entre namespaces
- Ter pelo menos 2 réplicas do CoreDNS

### Evitar:
- Cache muito baixo (< 10s) ou muito alto (> 600s)
- Modificar Corefile sem backup
- Rodar CoreDNS com recursos insuficientes
- Ignorar erros de DNS

---

## Exemplos Práticos

Exemplos prontos para uso na pasta [`examples/`](examples/):

### Casos de Uso Principais

| # | Exemplo | Quando Usar |
|---|---------|-------------|
| 01 | [Custom DNS Entries](examples/01-custom-dns-entries.yaml) | Precisa resolver servidores legados ou externos por nome |
| 02 | [Conditional Forwarding](examples/02-conditional-forwarding.yaml) | Ambiente multi-cloud ou integração com Active Directory |
| 03 | [DNS Rewrite](examples/03-rewrite-dns.yaml) | Migração de serviços ou criar aliases |
| 04 | [Logging & Debugging](examples/04-logging-debugging.yaml) | Troubleshooting de problemas de DNS |
| 05 | [Cache Optimization](examples/05-cache-optimization.yaml) | Melhorar performance e reduzir latência |
| 06 | [Wildcard DNS](examples/06-wildcard-dns.yaml) | Ambientes de dev/staging com domínios dinâmicos |
| 10 | [Production Ready](examples/10-production-ready.yaml) | Configuração completa para produção |

### Quick Start com Exemplos

```bash
# 1. Ver exemplos disponíveis
ls -la CoreDNS/examples/

# 2. Backup da configuração atual
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# 3. Aplicar um exemplo
kubectl apply -f CoreDNS/examples/01-custom-dns-entries.yaml

# 4. Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# 5. Testar
kubectl run test-dns --image=busybox --rm -it -- nslookup legacy-db.company.local
```

### Cenários Comuns

#### Cenário 1: Integração com Sistemas Legados
Você tem um banco de dados legado em `192.168.1.50` que não está no Kubernetes.

**Solução:** Use [exemplo 01](examples/01-custom-dns-entries.yaml)
```bash
kubectl apply -f CoreDNS/examples/01-custom-dns-entries.yaml
# Agora seus pods podem acessar: legacy-db.company.local
```

#### Cenário 2: Multi-Cloud (AWS + Azure)
Você tem serviços na AWS e Azure que precisam se comunicar.

**Solução:** Use [exemplo 02](examples/02-conditional-forwarding.yaml)
```bash
# *.aws.internal → DNS da AWS
# *.azure.local → DNS do Azure
kubectl apply -f CoreDNS/examples/02-conditional-forwarding.yaml
```

#### Cenário 3: Migração de Microserviços
Você está renomeando `old-api` para `new-api` mas não quer quebrar clientes.

**Solução:** Use [exemplo 03](examples/03-rewrite-dns.yaml)
```bash
# old-api.* → new-api.* (transparente para clientes)
kubectl apply -f CoreDNS/examples/03-rewrite-dns.yaml
```

#### Cenário 4: DNS não está funcionando
Você precisa debugar problemas de resolução DNS.

**Solução:** Use [exemplo 04](examples/04-logging-debugging.yaml)
```bash
kubectl apply -f CoreDNS/examples/04-logging-debugging.yaml
kubectl logs -n kube-system -l k8s-app=kube-dns -f
```

#### Cenário 5: Latência Alta de DNS
Suas aplicações estão lentas por causa de DNS.

**Solução:** Use [exemplo 05](examples/05-cache-optimization.yaml)
```bash
# Cache otimizado + prefetch
kubectl apply -f CoreDNS/examples/05-cache-optimization.yaml
```

#### Cenário 6: Ambiente de Desenvolvimento
Você quer que `*.dev.local` aponte para seu servidor de dev.

**Solução:** Use [exemplo 06](examples/06-wildcard-dns.yaml)
```bash
# Qualquer *.dev.local → 192.168.1.100
kubectl apply -f CoreDNS/examples/06-wildcard-dns.yaml
```

#### Cenário 7: Deploy em Produção
Você precisa de alta disponibilidade, autoscaling e resiliência.

**Solução:** Use [exemplo 10](examples/10-production-ready.yaml)
```bash
# HA + HPA + PDB + Cache otimizado
kubectl apply -f CoreDNS/examples/10-production-ready.yaml
```

---

## Referências

- [CoreDNS Official Docs](https://coredns.io/manual/toc/)
- [Kubernetes DNS Concepts](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [CoreDNS Plugins](https://coredns.io/plugins/)
- [Troubleshooting DNS](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [Exemplos Práticos](examples/)

---

## Resumo

CoreDNS é essencial para:
- Service discovery automático
- Resolução de DNS externo
- Performance com cache
- Flexibilidade com plugins

Pontos importantes:
- CoreDNS funciona como "lista telefônica" do cluster
- Sem CoreDNS os pods não conseguem se encontrar
- Configuração via ConfigMap/Corefile
- Debug sempre pelos logs