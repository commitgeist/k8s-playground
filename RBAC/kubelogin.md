# 🚀 AKS + Entra ID (Azure AD) – Problema comum com Kubelogin

## 🔹 O problema

Ao tentar aplicar um manifest ou se conectar a um cluster AKS integrado com Entra ID, pode aparecer o seguinte erro:

```bash
error: error validating "aks-entraid.yaml": error validating data: failed to download openapi: Get "https://<cluster-url>/openapi/v2?timeout=32s": getting credentials: exec: executable kubelogin not found

It looks like you are trying to use a client-go credential plugin that is not installed.

kubelogin is not installed which is required to connect to AAD enabled cluster.
```

Esse erro acontece porque o cluster AKS está **integrado ao Azure AD (Entra ID)** e exige o plugin **`kubelogin`** para validar tokens de autenticação.  
Como o `kubelogin` **não está disponível nos repositórios `apt`**, ele precisa ser instalado manualmente.

---

## 🔹 Solução

### 1. Instalar o `kubelogin`

Método 1 – via Azure CLI (recomendado):
```bash
az aks install-cli
```

Método 2 – baixando do GitHub Releases:
```bash
curl -LO https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
unzip kubelogin-linux-amd64.zip
sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
kubelogin --version
```

Método 3 – via Homebrew (Linux/macOS):
```bash
brew install Azure/kubelogin/kubelogin
```

---

### 2. Converter o kubeconfig

Depois de instalar, é preciso converter o kubeconfig para usar o `kubelogin`:

```bash
kubelogin convert-kubeconfig -l azurecli
```

Isso instrui o `kubectl` a usar o token da sessão do Azure CLI (`az login`) como autenticação.

---

### 3. Testar a conexão

```bash
kubectl get nodes
```

Se funcionar, significa que o `kubelogin` está corretamente configurado.

---

## 🔹 E se o AKS **não tiver integração com Entra ID**?

- Em clusters **sem integração AAD**, o acesso funciona normalmente apenas com:  
  ```bash
  az aks get-credentials --resource-group <RG> --name <ClusterName>
  kubectl get nodes
  ```

- Nesse caso, o `kubelogin` **não é necessário**. O Azure CLI gerencia as credenciais diretamente no kubeconfig.  

- Portanto:
  - **Com Entra ID habilitado** → precisa do `kubelogin`.  
  - **Sem Entra ID** → não muda nada, basta usar `az aks get-credentials`.  

---

## 🔹 Resumo

1. **Erro `kubelogin not found`** aparece em clusters AKS com integração Entra ID.  
2. Resolver instalando o `kubelogin` (via `az aks install-cli` ou GitHub Releases).  
3. Converter o kubeconfig com `kubelogin convert-kubeconfig -l azurecli`.  
4. Em clusters **sem AAD**, o fluxo não muda → `az aks get-credentials` já funciona.
