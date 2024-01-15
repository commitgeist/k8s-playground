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