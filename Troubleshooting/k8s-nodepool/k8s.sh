#!/usr/bin/env bash
#
# Teste: criar system node pool com 3 nós e reduzir para 1
# Objetivo: validar se a redução de contagem do system pool funciona
#           antes de executar no cluster real do cliente.
#
# Custo: cluster pequeno, ~1h de teste = centavos. O script limpa tudo no fim.
# Pré-requisitos: az cli logado (az login) e subscription correta selecionada.

set -euo pipefail

# ----------------------------------------------------------------------
# Variáveis (ajuste se quiser)
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
echo "==> [1/6] Criando resource group $RG em $LOCATION..."
az group create --name "$RG" --location "$LOCATION" -o none

# ----------------------------------------------------------------------
# 2. Cluster com o system pool default JÁ com 3 nós
#    (nodepool-name define o nome do system pool inicial)
# ----------------------------------------------------------------------
echo ""
echo "==> [2/6] Criando cluster $CLUSTER com system pool '$SYS_POOL' (3 nós)..."
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
echo "==> [3/6] Adicionando user pool '$USER_POOL' (1 nó)..."
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
echo "==> [4/6] Estado dos node pools ANTES da redução:"
az aks nodepool list \
  --resource-group "$RG" \
  --cluster-name "$CLUSTER" \
  --query "[].{Nome:name, Modo:mode, Contagem:count, Estado:provisioningState}" \
  -o table

# ----------------------------------------------------------------------
# 5. O TESTE: reduzir o system pool de 3 para 1
# ----------------------------------------------------------------------
echo ""
echo "==> [5/6] TESTE PRINCIPAL: reduzindo o system pool '$SYS_POOL' de 3 para 1 nó..."
echo ""

if az aks nodepool scale \
    --resource-group "$RG" \
    --cluster-name "$CLUSTER" \
    --name "$SYS_POOL" \
    --node-count 1 \
    -o none; then
  echo ""
  echo "    >>> RESULTADO: SUCESSO. A redução para 1 nó funcionou."
else
  echo ""
  echo "    >>> RESULTADO: FALHOU. A redução para 1 nó retornou erro (ver acima)."
fi

echo ""
echo "    Estado dos node pools DEPOIS da redução:"
az aks nodepool list \
  --resource-group "$RG" \
  --cluster-name "$CLUSTER" \
  --query "[].{Nome:name, Modo:mode, Contagem:count, Estado:provisioningState}" \
  -o table

# ----------------------------------------------------------------------
# 6. Limpeza
# ----------------------------------------------------------------------
echo ""
echo "==> [6/6] Teste concluído."
read -p "Deletar o resource group de teste ($RG) agora? (s/N) " cleanup
if [[ "$cleanup" == "s" || "$cleanup" == "S" ]]; then
  echo "    Deletando $RG em background (--no-wait)..."
  az group delete --name "$RG" --yes --no-wait
  echo "    Solicitado. A remoção continua em background."
else
  echo "    Mantido. Pra limpar depois, rode:"
  echo "    az group delete --name $RG --yes --no-wait"
fi

echo ""
echo "Fim."