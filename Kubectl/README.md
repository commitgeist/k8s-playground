Referências: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

## Instalando no Ubuntu

```bash
#!/usr/bin/bash

[ $(uname -m) = arch64 ] && curl -LO ./kubectl curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
[ $(uname -m) = ax86_64 ] && curl -LO ./kubectl curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/arm64/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
# and then append (or prepend) ~/.local/bin to $PATH

```

## Configuração do autocomplete
```yaml
# install bash-completion
sudo apt-get install bash-completion

# Add the completion script to your .bashrc file
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Apply changes
source ~/.bashrc
```


## Criando pod com imagem do Nginx

```bash
kubectl run --image nginx --port 80
```

## Acessando
```bash
kubectl exec -ti ebonygalorepod
```

## Conhecendo o Dry-run
Referência: https://foxutech.medium.com/how-to-create-and-change-the-kubernetes-yaml-using-dry-run-and-edit-5975d77e8df2


O comando abaixo fará com que seja criado um arquivo .yaml com todas as intruções de criação desse tipo de objeto
```bash
kubectl create deployment --image=nginx --dry-run=client -o yaml
```


### Listagem simples dos pods
```bash
#Obtendo 1 pod
kubectl get pod ebonygalorepod

# Obtendo o pod por namespace
kubectl get pods -n namespace-nome
```
## List all pods in ps output format with more information (such as node name)
  ```bash
    kubectl get pods -o wide
  ```


## Descrevendo dados de um POD
```bash
kubectl describe pod nome-pod -n namespace-nome
```

### Conhecendo o Kubectl run, attach, kubectl exec

Attatch
https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_attach/

```bash
#  O attach anexa a um processo que já está em execução dentro de um contêiner existente.
kubectl attach POD -c CONTAINER
```

### Kubectl exec
https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_exec/
```bash
# O exec executa um comando dentro do container
kubectl exec POD [-c CONTAINER] -- COMMAND [args...]

```
### O Run executa o container dentro do Pod

```bash
kubectl run pod --image image-name
```
## Criando pod
```bash
  # Temos 2 comandos para criar pods
  # Temos o kubectl create
  # E o Kuectl apply
  # Mas a diferença entre um e outro, é que o create apenas cria, e o apply valida se já existe o pod, e se existir ele atualiza.
```