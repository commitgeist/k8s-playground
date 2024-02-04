**O DaemonSet**:
Já sabemos o que é um Pod, um Deployment e um ReplicaSet, mas agora é a hora de conhecermos mais um objeto do Kubernetes, o DaemonSet.

O DaemonSet é um objeto que garante que todos os nós do cluster executem uma réplica de um Pod, ou seja, ele garante que todos os nós do cluster executem uma cópia de um Pod.

O DaemonSet é muito útil para executar Pods que precisam ser executados em todos os nós do cluster, como por exemplo, um Pod que faz o monitoramento de logs, ou um Pod que faz o monitoramento de métricas.

Alguns casos de uso de DaemonSets são:

Execução de agentes de monitoramento, como o Prometheus Node Exporter ou o Fluentd.
Execução de um proxy de rede em todos os nós do cluster, como kube-proxy, Weave Net, Calico ou Flannel.
Execução de agentes de segurança em cada nó do cluster, como Falco ou Sysdig.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      # these tolerations are to have the daemonset runnable on control plane nodes
      # remove them if your control plane nodes should not run pods
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log


```


Eu deixei o arquivo comentado para facilitar o entendimento, agora vamos criar o DaemonSet utilizando o arquivo de manifesto.

```bash
kubectl apply -f node-exporter-daemonset.yaml
```
 

Agora vamos verificar se o DaemonSet foi criado.

 ```bash
kubectl get daemonset
 ```

Como podemos ver, o DaemonSet foi criado com sucesso.

NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   2         2         2       2            2           <none>          5m24s
 

Caso você queira verificar os Pods que o DaemonSet está gerenciando, basta executar o comando abaixo.

```bash
kubectl get pods -l app=node-exporter
```
 

Somente para lembrar, estamos utilizando o parâmetro -l para filtrar os Pods que possuem a label app=node-exporter, que é o caso do nosso DaemonSet.

Como podemos ver, o DaemonSet está gerenciando 2 Pods, um em cada nó do cluster.

NAME                  READY   STATUS    RESTARTS   AGE
node-exporter-k8wp9   1/1     Running   0          6m14s
node-exporter-q8zvw   1/1     Running   0          6m14s
 

Os nossos Pods do node-exporter foram criados com sucesso, agora vamos verificar se eles estão sendo executados em todos os nós do cluster.

```bash
kubectl get pods -o wide -l app=node-exporter
```
 

Com o comando acima, podemos ver em qual nó cada Pod está sendo executado.

NAME                                READY   STATUS    RESTARTS   AGE     IP               NODE                            NOMINATED NODE   READINESS GATES
node-exporter-k8wp9                 1/1     Running   0          3m49s   192.168.8.145    ip-192-168-8-145.ec2.internal   <none>           <none>
node-exporter-q8zvw                 1/1     Running   0          3m49s   192.168.55.68    ip-192-168-55-68.ec2.internal   <none>           <none>
 

Como podemos ver, os Pods do node-exporter estão sendo executados em todos os dois nós do cluster.

Para ver os detalhes do DaemonSet, basta executar o comando abaixo.

```bash
kubectl describe daemonset node-exporter
```
 

O comando acima vai retornar uma saída parecida com a abaixo.

Name:           node-exporter
Selector:       app=node-exporter
Node-Selector:  <none>
Labels:         <none>
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 2
Current Number of Nodes Scheduled: 2
Number of Nodes Scheduled with Up-to-date Pods: 2
Number of Nodes Scheduled with Available Pods: 2
Number of Nodes Misscheduled: 0
Pods Status:  2 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=node-exporter
  Containers:
   node-exporter:
    Image:        prom/node-exporter:latest
    Port:         9100/TCP
    Host Port:    9100/TCP
    Environment:  <none>
    Mounts:
      /host/proc from proc (ro)
      /host/sys from sys (ro)
  Volumes:
   proc:
    Type:          HostPath (bare host directory volume)
    Path:          /proc
    HostPathType:  
   sys:
    Type:          HostPath (bare host directory volume)
    Path:          /sys
    HostPathType:  
Events:
  Type    Reason            Age   From                  Message
  ----    ------            ----  ----                  -------
  Normal  SuccessfulCreate  9m6s  daemonset-controller  Created pod: node-exporter-q8zvw
  Normal  SuccessfulCreate  9m6s  daemonset-controller  Created pod: node-exporter-k8wp9
 

Na saída acima, podemos ver algumas informações bem importantes relacionadas ao DaemonSet, como por exemplo, o número de nós que o DaemonSet está gerenciando, o número de Pods que estão sendo executados em cada nó, etc.

