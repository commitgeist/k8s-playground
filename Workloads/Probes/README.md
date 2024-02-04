# Oque são Probes no Kubernetes ?

As probes do Kubernetes são mecanismos essenciais para verificar o estado de um pod e garantir que suas aplicações estejam funcionando conforme esperado.


**Liveness**:  A Liveness Probe é usada para verificar se um pod está vivo. Ela determina se a aplicação dentro do pod está funcionando corretamente. Se a Liveness Probe falhar, o kubelet irá matar o container e o container será reiniciado de acordo com a política de reinício do pod.


**Startup**: A Startup Probe é utilizada para determinar quando um container de aplicação foi iniciado com sucesso. Ela é útil especialmente para containers que demoram mais para iniciar, garantindo que o Kubernetes não mate o container antes que ele esteja rodando efetivamente.


**Readiness**: A Readiness Probe é usada para saber quando um pod está pronto para receber tráfego. O Kubernetes garante que o tráfego não seja enviado a um pod até que a Readiness Probe tenha sido bem-sucedida. Se um pod não estiver pronto, ele será removido do serviço de balanceamento de carga.