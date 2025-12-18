# CoreDNS - Exemplos Práticos

Esta pasta contém manifestos prontos para uso com configurações customizadas do CoreDNS.

## Índice de Exemplos

| # | Arquivo | Descrição |
|---|---------|-----------|
| 01 | custom-dns-entries.yaml | Entradas DNS estáticas para servidores legados |
| 02 | conditional-forwarding.yaml | DNS condicional para multi-cloud/AD |
| 03 | rewrite-dns.yaml | Reescrita de DNS para migração |
| 04 | logging-debugging.yaml | Logging e debugging avançado |
| 05 | cache-optimization.yaml | Otimização de cache |
| 06 | wildcard-dns.yaml | DNS wildcard para dev/staging |
| 10 | production-ready.yaml | Configuração production-ready |

## Como Usar

```bash
# 1. Backup da configuração atual
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# 2. Aplicar exemplo
kubectl apply -f CoreDNS/examples/01-custom-dns-entries.yaml

# 3. Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# 4. Verificar
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```

## Rollback

```bash
kubectl apply -f coredns-backup.yaml
kubectl rollout restart deployment coredns -n kube-system
```
