Referencia geral: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

**Definição do Deployment**: O que é um Deployment?
No Kubernetes um Deployment é um objeto que representa uma aplicação. Ele é responsável por gerenciar os Pods que compõem uma aplicação. Um Deployment é uma abstração que nos permite atualizar os Pods e também fazer o rollback para uma versão anterior caso algo dê errado.

Quando criamos um Deployment é possível definir o número de réplicas que queremos que ele tenha. O Deployment irá garantir que o número de Pods que ele está gerenciando seja o mesmo que o número de réplicas definido. Se um Pod morrer, o Deployment irá criar um novo Pod para substituí-lo. Isso ajuda demais na disponibilidade da aplicação.

Um Deployment é declarativo, ou seja, nós definimos o estado desejado e o Deployment irá fazer o que for necessário para que o estado atual seja igual ao estado desejado.

Quando criamos um Deployment, nós automaticamente estamos criando um ReplicaSet. O ReplicaSet é um objeto que é responsável por gerenciar os Pods para o Deployment, já o Deployment é responsável por gerenciar os ReplicaSets.Como eu disse, um ReplicaSet é um objeto que é criado automaticamente pelo Deployment, mas nós podemos criar um ReplicaSet manualmente caso necessário. Nós vamos falar mais sobre isso no próximo dia, hoje o foco é o Deployment.

**Criando deployments**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-deployment
    strategy: {}
  template:
    metadata:
      labels:
        app: nginx-deployment
  spec:
    containers:
    - image: viniciuspoa2/techday_weproc:main
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 80
```

Comando:
```bash
kubectl create -f deployment.yaml -n tools
```
Ou:
```bash
kubectl apply -f deployment.yaml -n tools
```

Lembrando que a diferença entre o create e o apply é que o apply consegue atualizar o recurso, e o create de fato apenas cria. Ao executar o create com o recurso já criado, teremos um erro informando que o recurso já existe no cluster.

Outro ponto importante é que, qualquer recurso que estejamos criando, caso não passarmos o namespace, por padrão será criado no namespace default.

**Dry-run: Exportando yaml do deployment existente**:
```bash
    kubectl create deployment --image nginx --replicas 3 nginx-deployment --dry-run=client -o yaml > novo-deployment.yaml
```


**Estratégia de update de deployments**:
Podemos implementar estratégia de atualização dos deployments. Seguindo o padrão strategy nos manifestos deployment.


referência 1: https://www.kubermatic.com/blog/introduction-to-deployment-strategies/
referência 2: https://blog.container-solutions.com/kubernetes-deployment-strategies

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: techday_weproc
spec:
  selector:
    matchLabels:
      app: techday_weproc
  strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1 # Pode ter até 1 pod a mais do que eu pedi no arquivo - 11 Pods
    maxUnavailable: 0 # Vai atualizar de 2 em 2
  template:
    metadata:
      labels:
        app: techday_weproc
    spec:
      containers:
      - name: myapp
        image: viniciuspoa2/techday_weproc:main
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```



**Estratégia Recreate**:
O recreate pod acabar recriando todo o ambiente de uma vez só.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: techday_weproc
spec:
  selector:
    matchLabels:
      app: techday_weproc
  strategy:
  type: Recrate
  template:
    metadata:
      labels:
        app: techday_weproc
    spec:
      containers:
      - name: myapp
        image: viniciuspoa2/techday_weproc:main
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
```

**Rollout e Rollback**
Exp:
```bash
  kubectl rollout history <resource-name> -n <namespace-name>
```
Real:
```bash
  kubectl rollout history deployment blogapp -n tools
```
Executando o Rollback:

Exp:
```bash
kubectl rollout undo deployment/deployment-name -n namespace-name
```
Real:
```bash
kubectl rollout undo deployment/blogapp -n tools --to-revsion=[number-revsion]
```


Pegando status do rollout após executa-lo:
```bash
 kubectl rollout status resource-name resource -n namespace-name
```

 O comando acima é usado para visualizar o histórico de rollouts (implantações) de um recurso, como um deployment, no Kubernetes. Este comando lista todas as revisões feitas no recurso especificado dentro do namespace dado, incluindo informações como o número da revisão, a data da mudança, e os detalhes sobre a mudança (como a atualização da imagem do container, por exemplo). Isso é muito útil para compreender a cronologia de mudanças feitas em um recurso e identificar qual versão específica você pode querer reverter usando o comando undo.

Ambos os comandos são ferramentas essenciais para a gestão de deployments no Kubernetes, proporcionando controle e flexibilidade para lidar com atualizações e possíveis problemas que podem surgir durante o ciclo de vida dos aplicativos.
