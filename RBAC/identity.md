# Managed Identity e Service Principal

## Criando AKS com Managed Identity

```sh
    az aks create -g myResourceGroup \
        -n myManagedCluster \
        --enable-managed-identity
```


## Criar identidade de Serviço

```sh
    az role assignment create \
    assignee $AKS_SERVICEPRINC_APP_ID \
     --scope $ACR_RESOURCE_ID \
     --role $SERVICE_ROLE
```

## Criar AKS com identitdade de Serviço

```sh
  az aks create \
    --resource-group myResourceGroup
    --name myAKSCluster
    --service-principal <app_id> \
    --client-secret <password>

```