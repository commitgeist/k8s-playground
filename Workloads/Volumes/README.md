# Volumes no Kubernetes
**Visão Geral sobre os Volumes**:No Kubernetes, volumes são unidades de armazenamento que permitem que dados persistam além do ciclo de vida de um pod individual, facilitando a gestão de dados de maneira eficiente e flexível. Volumes em Kubernetes podem ser configurados de várias maneiras, dependendo do tipo de armazenamento e das necessidades específicas da aplicação. Aqui está uma rápida explicação sobre Persistent Volumes (PV) e Persistent Volume Claims (PVC), além de sua relação hierárquica:

**Persistent Volume (PV)**:
Um Persistent Volume (PV) é uma peça de armazenamento no cluster que foi provisionada por um administrador ou dinamicamente pelo Kubernetes usando Storage Classes. Ele é independente do ciclo de vida dos pods que consomem o armazenamento PV. Essencialmente, um PV é uma representação de um recurso de armazenamento real em uma rede, em um cluster, ou na nuvem. PVs suportam vários tipos de armazenamento, como discos locais, NFS, volumes na nuvem, etc.

**Persistent Volume Claim (PVC)**:
Um Persistent Volume Claim (PVC) é uma solicitação de armazenamento por parte do usuário. Ele permite que um usuário solicite um armazenamento de tamanho específico e certos modos de acesso (como leitura e escrita) sem precisar conhecer os detalhes complexos do ambiente de armazenamento subjacente. Um PVC especifica tamanho, e em alguns casos, o desempenho do armazenamento necessário para um pod.

**Hierarquia e Relacionamento**:
A hierarquia e o relacionamento entre PV e PVC podem ser entendidos da seguinte maneira
    
- Provisionamento Um administrador cria um PV no cluster ou um PV é dinamicamente provisionado através de uma Storage Class. O PV representa um recurso de armazenamento específico.
    
- Reivindicação: Quando um usuário (ou um pod) necessita de armazenamento, ele cria um PVC especificando os requisitos de armazenamento. O Kubernetes então faz a ligação (binding) do PVC com um PV compatível.

- Uso: Uma vez que um PVC é ligado a um PV, o armazenamento representado pelo PV é reservado para o uso do PVC. O pod pode então montar o PVC como um volume para armazenar e gerenciar dados.

<br/>

**Ciclo de Vida**: 
- O ciclo de vida do PVC está intimamente ligado ao pod que o utiliza, mas o ciclo de vida do PV é gerenciado independentemente, permitindo a reutilização do armazenamento.

<br/>

**Pontos de atenção**:
 
 - Persistent Volumes (PVs)
PVs são recursos de cluster não associados a um namespace específico. Eles são criados e gerenciados em nível de cluster pelo administrador do cluster ou dinamicamente pelo Kubernetes através de StorageClasses. Isso significa que um PV é acessível em todo o cluster e não está confinado a um namespace específico. Essa característica permite que os PVs sejam reutilizados por diferentes usuários e aplicações em diferentes namespaces, de acordo com as políticas de acesso definidas.

- Persistent Volume Claims (PVCs)
PVCs são recursos associados a um namespace específico. Eles são criados por usuários em um namespace para solicitar armazenamento de um tamanho e acesso específicos, conforme definido em um PV. O Kubernetes então vincula um PVC a um PV compatível no nível do cluster. Como os PVCs são específicos do namespace, eles só podem acessar PVs que estejam disponíveis cluster-wide, mas a vinculação acontece dentro do contexto do namespace do PVC.
Hierarquia e Funcionamento