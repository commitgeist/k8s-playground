**ReplicaSet**
Uma coisa é super importante de saber, quando estamos criando um Deployment no Kubernetes, automaticamente estamos criando além do Deployment um ReplicaSet e esse ReplicaSet é quem vai criar os Pods que estão dentro do Deployment.

**Criação de ReplicaSet**
É possível criar um ReplicaSet sem um Deployment, mas não é uma boa prática, pois o ReplicaSet não tem a capacidade de fazer o gerenciamento de versões dos Pods e também não tem a capacidade de fazer o gerenciamento de RollingUpdate dos Pods.


```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # modifique o número de replicas de acordo com o seu caso
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v3

```


```bash
kubectl scale deployment nginx-deployment --replicas=3
```