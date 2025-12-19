# Exemplos de Troubleshooting

Manifestos prontos para troubleshooting no Kubernetes.

## netshoot

### Pod Simples
**Arquivo:** [netshoot-pod.yaml](netshoot-pod.yaml)

```bash
# Deploy
kubectl apply -f netshoot-pod.yaml

# Usar
kubectl exec -it netshoot -- bash

# Remover
kubectl delete -f netshoot-pod.yaml
```

**Quando usar:**
- Debug rápido e temporário
- Testar conectividade de rede
- Debug de DNS

---

### Deployment
**Arquivo:** [netshoot-deployment.yaml](netshoot-deployment.yaml)

```bash
# Deploy
kubectl apply -f netshoot-deployment.yaml

# Usar
kubectl exec -it deployment/netshoot -- bash

# Remover
kubectl delete -f netshoot-deployment.yaml
```

**Quando usar:**
- Troubleshooting persistente
- Múltiplas sessões de debug
- Ambiente de desenvolvimento

---

### DaemonSet
**Arquivo:** [netshoot-daemonset.yaml](netshoot-daemonset.yaml)

```bash
# Deploy
kubectl apply -f netshoot-daemonset.yaml

# Listar pods (um por node)
kubectl get pods -l app=netshoot -o wide

# Usar em node específico
kubectl exec -it <pod-name> -- bash

# Remover
kubectl delete -f netshoot-daemonset.yaml
```

**Quando usar:**
- Debug de problemas específicos de node
- Troubleshooting de rede do host
- Análise de performance por node

**Atenção:** Usa `hostNetwork` e `privileged`, use apenas quando necessário.

---

## Comandos Úteis

### Pod Temporário (sem manifest)
```bash
# Criar e deletar automaticamente ao sair
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
```

### Debug em Namespace Específico
```bash
kubectl run netshoot -n production --rm -it --image=nicolaka/netshoot -- bash
```

### Com Capabilities Extras
```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot \
  --overrides='{"spec":{"containers":[{"name":"netshoot","image":"nicolaka/netshoot","stdin":true,"tty":true,"securityContext":{"capabilities":{"add":["NET_ADMIN","NET_RAW"]}}}]}}' \
  -- bash
```

---

## Cenários de Uso

### Debug de DNS
```bash
kubectl exec -it netshoot -- bash
nslookup kubernetes.default
dig nginx-service.default.svc.cluster.local
```

### Debug de Service
```bash
kubectl exec -it netshoot -- bash
curl http://nginx-service
nc -zv nginx-service 80
```

### Debug de NetworkPolicy
```bash
kubectl exec -it netshoot -- bash
curl http://api.production.svc.cluster.local
```

### Captura de Tráfego
```bash
kubectl exec -it netshoot -- bash
tcpdump -i eth0 -n port 80
```

### Teste de Performance
```bash
# Servidor
kubectl run iperf-server --image=nicolaka/netshoot -- iperf3 -s

# Cliente
kubectl exec -it netshoot -- iperf3 -c iperf-server
```

