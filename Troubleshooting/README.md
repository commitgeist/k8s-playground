# Troubleshooting no Kubernetes

Guias práticos para diagnosticar e resolver problemas em clusters Kubernetes.

## Índice

### Ferramentas
- [netshoot.md](netshoot.md) - Guia completo do netshoot para debugging de rede

### Guias de Debug
- [dns-debugging.md](dns-debugging.md) - Como debugar problemas de DNS e CoreDNS
- [network-debugging.md](network-debugging.md) - Debug de rede, CNI e NetworkPolicy
- [service-debugging.md](service-debugging.md) - Debug de Services e Endpoints

### Exemplos
- [examples/](examples/) - Manifestos prontos para troubleshooting

---

## Quick Start

### Debug Rápido com netshoot

```bash
# Pod temporário para debug
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash

# Dentro do pod:
nslookup kubernetes.default
curl http://nginx-service
ping 8.8.8.8
```

### Comandos Úteis

```bash
# Ver logs de um pod
kubectl logs <pod-name> -f

# Ver eventos do cluster
kubectl get events --sort-by='.lastTimestamp'

# Descrever recurso
kubectl describe pod <pod-name>

# Exec em pod
kubectl exec -it <pod-name> -- bash

# Port-forward para debug local
kubectl port-forward svc/<service-name> 8080:80
```

---

## Cenários Comuns

### DNS não resolve
1. Verificar CoreDNS está rodando
2. Testar DNS com netshoot
3. Ver [dns-debugging.md](dns-debugging.md)

### Pod não consegue acessar Service
1. Verificar Service e Endpoints
2. Testar conectividade com netshoot
3. Ver [service-debugging.md](service-debugging.md)

### Problemas de rede entre Pods
1. Verificar NetworkPolicy
2. Testar conectividade
3. Ver [network-debugging.md](network-debugging.md)

---

## Recursos Adicionais

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [netshoot GitHub](https://github.com/nicolaka/netshoot)
- [kubectl debug](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)

