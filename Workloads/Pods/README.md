# Mais sobre args em PODS

### Argumentos em yaml de POD
```href
https://yuminlee2.medium.com/kubernetes-command-and-arguments-in-pod-c3f1be61ba1a#:~:text=The%20command%20and%20args%20fields,corresponds%20to%20the%20CMD%20instruction. 
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: my-image
    command: ["echo", "Hello"]
    args: ["world"]

```

# Exemplo de POD multi-container
```href
https://www.mirantis.com/blog/multi-container-pods-and-container-communication-in-kubernetes/
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: multipod
    service: webservers
  name: multipod
spec:
  containers:
  - image: nginx
    name: girus-nginx
  - image: apache
  name: girus-buntu
dnsPolicy: ClusterFirst
restartPolicy: Always
```

# Pod Multi-container com mais detalhes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  labels:
    name: myapp
spec:
  containers:
  - name: webserver
    image: nginx:alpine 
      - sleep 
      - "1800"
  - name: apache-server
    image: hello-word
    resources:
        limits: # Limitando pod - Oque existe aqui é o limite que o pod consegue receber de recursos
          cpu: "0.5"
          memory: "128Mi"
        requests: 
          cpu: "0.5" # O requests garante que, no minimo meu pod tera o valor que estou passando aqui
          memory: "64Mi"
```


### Configurando volume empty-dir

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-volume
  labels:
    name: nginx-volume
spec:
  containers:
  - name: nginx-volume
    image: nginx
    volumeMounts:
    - mountPath: /nginxvolume
      name: primeiro-emptydir
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
      requests:
        cpu: "0.5"
        memory: "65Mi"
    dbsPolicy: ClusterFirst
    restartPolicy: Always
    volumes:
    - name: primeiro-emptydir
      emptyDir:
        sizeLimit: "256Mi"
    ports:
    - containerPort: 80

```


# Parar POD para analise da imagem interna
As vezes durante o troubleshooting precisamos que o container fique up para logarmos nele via POD, e analisar os arquivos do container. Dai oque podemos fazer é o seguinte.


1. Logs do pod
```bash
kubectl logs <nome-do-pod> -n <namespace>
```

2. Descrição do pod
```bash
kubectl describe pod -n <namespace>
```

Se o pod estiver reiniciando, você pode querer ver os logs de uma instância anterior do pod:

```bash
kubectl logs <nome-do-pod> -n <namespace> --previous
```
3.Acompanhar os Logs do Pod
Se o pod já estiver em um estado onde está executando algum processo (e não em um estado de erro como CrashLoopBackOff), você pode acompanhar os logs do container em tempo real:

```bash
kubectl logs -f <nome-do-pod>
```

Ou para um container específico dentro do pod:

```bash
kubectl logs -f <nome-do-pod> -c <nome-do-container>
```

4.Obtendo eventos do cluster(node) com kubectl get events
Este comando é útil para ver eventos no nível do cluster ou de um namespace específico. Isso pode incluir eventos relacionados à criação de pods, problemas de agendamento, etc.

```bash
kubectl get events
```

ou 

```bash
 kubectl events -n namespace-name --for pod/pod-name
```


5. Criar uma imagem para inspecionar o ambiente. A imagem abaixo faz um pause na execução do container, garantindo pelo menos 1 hora de execução.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-name
spec:
  containers:
  - name: container-name
    image: image-name
    command: ["sleep"]
    args: ["3600"] # Mantém o container em execução por uma hora
    resources:
      limits:
        memory: "300Mi"
        cpu: "1.0"
      requests:
        memory: "150Mi"
        cpu: "0.5"
  imagePullSecrets:
  - name: secret-name

```


```bash
kubectl exec -it pod-inspector -- /bin/sh
```