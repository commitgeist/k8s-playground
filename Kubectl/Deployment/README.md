```bash
kubectl create deployment --image nginx --replicas 3 nginx-deployment --dry-run=client -o yaml > novo-deployment.yaml

```