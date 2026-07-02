#!/usr/bin/env bash
#
# Teste: criar system node pool com 3 nós e reduzir para 1
# Objetivo: validar se a redução de contagem do system pool funciona
#           antes de executar no cluster real do cliente.
#
# Custo: cluster pequeno, ~1h de teste = centavos.
# Pré-requisitos: az cli logado (az login) e subscription correta selecionada.
#
# OBS: este script NÃO deleta nada no final. A exclusão é manual,
#      via ./delete.sh (mesmas variáveis abaixo).

set -euo pipefail

# ----------------------------------------------------------------------
# Variáveis (ajuste se quiser) — mantenha iguais em create.sh e delete.sh
# ----------------------------------------------------------------------
RG="rg-teste-nodepool-scale"
LOCATION="eastus2"
CLUSTER="aks-teste-scale"
SYS_POOL="sysnp01"        # system pool que vamos criar com 3 e reduzir p/ 1
USER_POOL="userpool01"    # user pool "chinelo"
VM_SIZE="Standard_B2s"    # 2 vCPU / 4GB - mais barato que roda AKS
K8S_VERSION=""            # vazio = deixa o AKS escolher a versão default

# ----------------------------------------------------------------------
# 0. Confirmação da subscription
# ----------------------------------------------------------------------
echo "==> Subscription atual:"
az account show --query "{name:name, id:id}" -o table
echo ""
read -p "Continuar com esta subscription? (s/N) " confirm
[[ "$confirm" == "s" || "$confirm" == "S" ]] || { echo "Abortado."; exit 1; }

# ----------------------------------------------------------------------
# 1. Resource group
# ----------------------------------------------------------------------
echo ""
echo "==> [1/5] Criando resource group $RG em $LOCATION..."
az group create --name "$RG" --location "$LOCATION" -o none

# ----------------------------------------------------------------------
# 2. Cluster com o system pool default JÁ com 3 nós
#    (nodepool-name define o nome do system pool inicial)
# ----------------------------------------------------------------------
echo ""
echo "==> [2/5] Criando cluster $CLUSTER com system pool '$SYS_POOL' (3 nós)..."
echo "    Isso leva ~5 min."
VERSION_FLAG=()
[[ -n "$K8S_VERSION" ]] && VERSION_FLAG=(--kubernetes-version "$K8S_VERSION")

az aks create \
  --resource-group "$RG" \
  --name "$CLUSTER" \
  --location "$LOCATION" \
  --nodepool-name "$SYS_POOL" \
  --node-count 3 \
  --node-vm-size "$VM_SIZE" \
  --load-balancer-sku standard \
  --generate-ssh-keys \
  --no-wait \
  "${VERSION_FLAG[@]}"

echo "    Aguardando o cluster ficar pronto..."
az aks wait --resource-group "$RG" --name "$CLUSTER" --created --interval 30 --timeout 1200

# ----------------------------------------------------------------------
# 3. Adiciona um user pool "chinelo" (1 nó)
# ----------------------------------------------------------------------
echo ""
echo "==> [3/5] Adicionando user pool '$USER_POOL' (1 nó)..."
az aks nodepool add \
  --resource-group "$RG" \
  --cluster-name "$CLUSTER" \
  --name "$USER_POOL" \
  --mode User \
  --node-count 1 \
  --node-vm-size "$VM_SIZE" \
  -o none

# ----------------------------------------------------------------------
# 4. Estado ANTES da redução
# ----------------------------------------------------------------------
echo ""
echo "==> [4/5] Estado dos node pools ANTES da redução:"
az aks nodepool list \
  --resource-group "$RG" \
  --cluster-name "$CLUSTER" \
  --query "[].{Nome:name, Modo:mode, Contagem:count, Estado:provisioningState}" \
  -o table

# ----------------------------------------------------------------------
# 5. Cluster pronto para o teste manual de scale
# ----------------------------------------------------------------------
echo ""
echo "==> [5/5] Cluster pronto."
echo ""
echo "    Pra rodar o teste manualmente (reduzir system pool de 3 para 1):"
echo "    az aks nodepool scale --resource-group $RG --cluster-name $CLUSTER --name $SYS_POOL --node-count 1"
echo ""
echo "    Pra conferir o estado dos node pools depois:"
echo "    az aks nodepool list --resource-group $RG --cluster-name $CLUSTER -o table"
echo ""
echo "    Quando terminar, delete os recursos manualmente com:"
echo "    ./delete.sh"
echo ""
echo "Fim."
