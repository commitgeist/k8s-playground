#!/usr/bin/env bash
#
# Deleta o resource group criado pelo create.sh (mesmo teste de nodepool scale).
# Mantém as mesmas variáveis do create.sh pra apontar pro recurso certo.

set -euo pipefail

RG="rg-teste-nodepool-scale"
CLUSTER="aks-teste-scale"

# ----------------------------------------------------------------------
# 0. Confirmação da subscription
# ----------------------------------------------------------------------
echo "==> Subscription atual:"
az account show --query "{name:name, id:id}" -o table
echo ""

# ----------------------------------------------------------------------
# 1. Mostra o que existe antes de deletar
# ----------------------------------------------------------------------
if ! az group show --name "$RG" &>/dev/null; then
  echo "Resource group '$RG' não existe (ou já foi deletado). Nada a fazer."
  exit 0
fi

echo "==> Recursos atuais no resource group '$RG':"
az resource list --resource-group "$RG" --query "[].{Nome:name, Tipo:type, Local:location}" -o table
echo ""

echo "==> Node pools do cluster '$CLUSTER' (se existir):"
az aks nodepool list --resource-group "$RG" --cluster-name "$CLUSTER" \
  --query "[].{Nome:name, Modo:mode, Contagem:count, Estado:provisioningState}" \
  -o table 2>/dev/null || echo "    (cluster não encontrado ou já deletado)"
echo ""

# ----------------------------------------------------------------------
# 2. Confirmação e delete
# ----------------------------------------------------------------------
read -p "Deletar TODO o resource group '$RG'? (s/N) " confirm
[[ "$confirm" == "s" || "$confirm" == "S" ]] || { echo "Abortado."; exit 1; }

echo ""
echo "==> Deletando $RG (--no-wait, roda em background)..."
az group delete --name "$RG" --yes --no-wait
echo "    Solicitado. Acompanhe com: az group show --name $RG (some quando concluir)"
