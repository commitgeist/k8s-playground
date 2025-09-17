# Service Principle - Identidade Gerenciada Microsoft

## 🎯 Objetivo
Aprender a criar e administrar **App Registrations** (Service Principals) usando **Azure CLI**, tanto para:
- **Gerenciar recursos do Azure** (VMs, Storage, AKS, etc.) via **RBAC**.
- **Consumir APIs do Microsoft Graph** (usuários, grupos, e-mail, Teams, O365).

---

## 🔹 1. Conceitos Fundamentais

- **App Registration** → Identidade de aplicação no Entra ID (Azure AD).  
- **Service Principal (SPN)** → Instância do App no tenant, usada para autenticação.  
- **RBAC (Role-Based Access Control)** → Permissões em recursos Azure (Reader, Contributor, etc.).  
- **API Permissions (Graph)** → Permissões para acessar dados do Entra ID / O365 via Microsoft Graph.

---

## 🔹 2. Pré-requisitos

- Azure CLI instalado (>= 2.60).  
- Conta com permissões adequadas:
  - **Owner/User Access Administrator** → para RBAC na subscription.  
  - **Global Administrator/Privileged Role Administrator** → para conceder permissões no Graph.  
- Extensão `jq` (para parse de JSON em exemplos).

---

## 🔹 3. Criando App Registration + RBAC no Azure

### 3.1 Criar um SPN com permissão em toda a subscription
```bash
SUBSCRIPTION_ID="<id-da-sua-sub>"
az ad sp create-for-rbac   --name "spn-devopsjr"   --role Contributor   --scopes /subscriptions/$SUBSCRIPTION_ID   --sdk-auth
```

### 3.2 Escopo apenas em um Resource Group
```bash
RG_NAME="rg-apps-dev"
az ad sp create-for-rbac   --name "spn-rg-apps"   --role Reader   --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME
```

### 3.3 Renovar ou criar novo secret
```bash
APP_ID="<appId-do-app>"
az ad app credential reset --id $APP_ID --append --years 1
```

---

## 🔹 4. App Registration + Microsoft Graph (O365, Entra ID)

### 4.1 Descobrir permissões disponíveis
```bash
az ad sp show   --id 00000003-0000-0000-c000-000000000000   --query "appRoles[].{Name:value, Id:id}" -o table
```

### 4.2 Adicionar permissões Graph
```bash
APP_ID="<appId>"
GRAPH_API="00000003-0000-0000-c000-000000000000"

# User.Read.All
az ad app permission add --id $APP_ID --api $GRAPH_API --api-permissions df021288-bdef-4463-88db-98f22de89214=Role

# Group.Read.All
az ad app permission add --id $APP_ID --api $GRAPH_API --api-permissions 5b567255-7703-4780-807c-7be8301ae99b=Role
```

### 4.3 Consentimento (Global Admin)
```bash
az ad app permission admin-consent --id $APP_ID
```

---

## 🔹 5. Rotação de Credenciais

### Listar secrets existentes
```bash
az ad app credential list --id $APP_ID -o table
```

### Deletar secret expirado
```bash
az ad app credential delete --id $APP_ID --key-id <KeyId>
```

### Criar secret novo
```bash
az ad app credential reset --id $APP_ID --append --years 1
```

### Script de automação
```bash
#!/bin/bash
APP_ID="<appId>"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

EXPIRED=$(az ad app credential list --id $APP_ID | jq -r '.[] | select(.endDateTime < "'$NOW'") | .keyId')

for ID in $EXPIRED; do
  echo "[INFO] Removendo secret expirado: $ID"
  az ad app credential delete --id $APP_ID --key-id $ID
done

echo "[INFO] Criando novo secret válido por 1 ano"
az ad app credential reset --id $APP_ID --append --years 1
```

---

## 🔹 6. Integração com Azure Key Vault
```bash
NEW_SECRET=$(az ad app credential reset --id $APP_ID --append --years 1 --query password -o tsv)
az keyvault secret set --vault-name "kv-devops" --name "spn-devopsjr-secret" --value "$NEW_SECRET"
```

---

## 🔹 7. Boas Práticas

- Use `--append` ao criar secret novo (não apaga os antigos).  
- Configure alertas de expiração no **Key Vault**.  
- Prefira **certificados** em vez de secrets, quando possível.  
- Documente quem usa cada App Registration.  
- Use **Managed Identity** quando disponível (não tem secret pra rotacionar).

---

## 🔹 8. Casos Reais de Uso

- **Terraform** → autenticação sem usuário humano.  
- **Pipelines (Azure DevOps/GitHub Actions)** → uso seguro com Key Vault.  
- **Rotação Automática** → evitar downtime por credenciais expiradas.  
- **Graph Automation** → automatizar operações no O365.

---