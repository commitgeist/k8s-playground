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