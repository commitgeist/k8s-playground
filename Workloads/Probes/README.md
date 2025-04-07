# Oque são Probes no Kubernetes ?

As probes do Kubernetes são mecanismos essenciais para verificar o estado de um pod e garantir que suas aplicações estejam funcionando conforme esperado.


**Liveness**:  A Liveness Probe é usada para verificar se um pod está vivo. Ela determina se a aplicação dentro do pod está funcionando corretamente. Se a Liveness Probe falhar, o kubelet irá matar o container e o container será reiniciado de acordo com a política de reinício do pod.


**Startup**: A Startup Probe é utilizada para determinar quando um container de aplicação foi iniciado com sucesso. Ela é útil especialmente para containers que demoram mais para iniciar, garantindo que o Kubernetes não mate o container antes que ele esteja rodando efetivamente.


**Readiness**: A Readiness Probe é usada para saber quando um pod está pronto para receber tráfego. O Kubernetes garante que o tráfego não seja enviado a um pod até que a Readiness Probe tenha sido bem-sucedida. Se um pod não estiver pronto, ele será removido do serviço de balanceamento de carga.



## livenessProbe

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
      - image: nginx:1.19.2
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: 0.25
            memory: 128Mi
        livenessProbe: # Aqui é onde vamos adicionar a nossa livenessProbe
          tcpSocket: # Aqui vamos utilizar o tcpSocket, onde vamos se conectar ao container através do protocolo TCP
            port: 80 # Qual porta TCP vamos utilizar para se conectar ao container
          initialDelaySeconds: 10 # Quantos segundos vamos esperar para executar a primeira verificação
          periodSeconds: 10 # A cada quantos segundos vamos executar a verificação
          timeoutSeconds: 5 # Quantos segundos vamos esperar para considerar que a verificação falhou
          failureThreshold: 3 # Quantos falhas consecutivas vamos aceitar antes de reiniciar o container

```


Com isso temos algumas coisas novas, e utilizamos apenas uma probe que é a livenessProbe.

O que declaramos com a regra acima é que queremos testar se o Pod está respondendo através do protocolo TCP, através da opção tcpSocket, na porta 80 que foi definida pela opção port. E também definimos que queremos esperar 10 segundos para executar a primeira verificação utilizando initialDelaySeconds e por conta da periodSecondsfalamos que queremos que a cada 10 segundos seja realizada a verificação. Caso a verificação falhe, vamos esperar 5 segundos, por conta da timeoutSeconds, para tentar novamente, e como utilizamos o failureThreshold, se falhar mais 3 vezes, vamos reiniciar o Pod.

Ficou mais claro? Vamos para mais um exemplo.

Vamos imaginar que agora não queremos mais utilizar o tcpSocket, mas sim o httpGet para tentar acessar um endpoint dentro do nosso Pod.


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
      - image: nginx:1.19.2
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: 0.25
            memory: 128Mi
        livenessProbe: # Aqui é onde vamos adicionar a nossa livenessProbe
          httpGet: # Aqui vamos utilizar o httpGet, onde vamos se conectar ao container através do protocolo HTTP
            path: / # Qual o endpoint que vamos utilizar para se conectar ao container
            port: 80 # Qual porta TCP vamos utilizar para se conectar ao container
          initialDelaySeconds: 10 # Quantos segundos vamos esperar para executar a primeira verificação
          periodSeconds: 10 # A cada quantos segundos vamos executar a verificação
          timeoutSeconds: 5 # Quantos segundos vamos esperar para considerar que a verificação falhou
          failureThreshold: 3 # Quantos falhas consecutivas vamos aceitar antes de reiniciar o container

```

Perceba que agora somente mudamos algumas coisas, apesar de seguir com o mesmo objetivo, que é verificar se o Nginx está respondendo corretamente, mudamos como iremos testar isso. Agora estamos utilizando o httpGet para testar se o Nginx está respondendo corretamente através do protocolo HTTP, e para isso, estamos utilizando o endpoint / e a porta 80.

O que temos de novo aqui é a opção path, que é o endpoint que vamos utilizar para testar se o Nginx está respondendo corretamente, e claro, a httpGet é a forma como iremos realizar o nosso teste, através do protocolo HTTP.



## Readiness Probe

A readinessProbe é uma forma de o Kubernetes verificar se o seu container está pronto para receber tráfego, se ele está pronto para receber requisições vindas de fora.

Essa é a nossa probe de leitura, ela fica verificando se o nosso container está pronto para receber requisições, e se estiver pronto, ele irá receber requisições, caso contrário, ele não irá receber requisições, pois será removido do endpoint do serviço, fazendo com que o tráfego não chegue até ele.

Ainda iremos ver o que é service e endpoint, mas por enquanto, basta saber que o endpoint é o endereço que o nosso service irá usar para acessar o nosso Pod. Mas vamos ter um dia inteiro para falar sobre service e endpoint, então, relaxa.

 

Voltando ao assunto, a nossa probe da vez irá garantir que o nosso Podestá saudável para receber requisições.

Vamos para um exemplo para ficar mais claro.

Para o nosso exemplo, vamos criar um arquivo chamado nginx-readiness.yaml e vamos colocar o seguinte conteúdo:


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
      - image: nginx:1.19.2
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: 0.25
            memory: 128Mi
        readinessProbe: # Onde definimos a nossa probe de leitura
          httpGet: # O tipo de teste que iremos executar, neste caso, iremos executar um teste HTTP
            path: / # O caminho que iremos testar
            port: 80 # A porta que iremos testar
          initialDelaySeconds: 10 # O tempo que iremos esperar para executar a primeira vez a probe
          periodSeconds: 10 # De quanto em quanto tempo iremos executar a probe
          timeoutSeconds: 5 # O tempo que iremos esperar para considerar que a probe falhou
          successThreshold: 2 # O número de vezes que a probe precisa passar para considerar que o container está pronto
          failureThreshold: 3 # O número de vezes que a probe precisa falhar para considerar que o container não está pronto

```