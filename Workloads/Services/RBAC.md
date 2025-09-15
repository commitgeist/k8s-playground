# RBAC no AKS (Azure Kubernetes Service)

## O que é RBAC?
RBAC (Role-Based Access Control) é o **Controle de Acesso Baseado em Funções**.  
Em vez de dar permissões diretamente para pessoas ou serviços, criamos **funções (roles)** com permissões definidas e ligamos usuários, grupos ou identidades a essas funções.

👉 Analogia:  
Num hospital, não importa **quem é a pessoa**, importa a **função**.  
- Médico: pode prescrever remédios.  
- Enfermeira: pode aplicar injeção.  
- Recepcionista: pode marcar consultas.  

Se o médico sair e outro entrar, não mudamos as permissões — só trocamos quem ocupa o cargo.

---

## RBAC dentro do AKS

### 1. Autenticação (Authentication) → Quem é você?
- O Kubernetes **não guarda usuário e senha**.  
- Ele delega para um **provedor de identidade**.  
- No AKS, usamos o **Azure AD (Entra ID)**.  
- Quando você acessa o cluster, o kube-apiserver valida seu token com o Azure AD.

Exemplo prático:  
```bash
az aks get-credentials --resource-group meuRG --name meuCluster
```
Isso baixa suas credenciais e configura o kubeconfig com um token do Azure AD.

---

### 2. Autorização (Authorization) → O que você pode fazer?
Depois de saber **quem é você**, o cluster precisa decidir **o que você pode fazer**.

- **Role**: permissões em um namespace específico (ex.: listar pods no `dev`).  
- **ClusterRole**: permissões no cluster inteiro (ex.: criar namespaces).  
- **RoleBinding**: liga uma Role a um usuário ou grupo.  
- **ClusterRoleBinding**: liga uma ClusterRole a um usuário ou grupo.

Exemplo prático:  
- Dev → listar pods em `namespace=dev`.  
- SRE → aplicar manifests em todos os namespaces.  
- Admin → pode até deletar o cluster.

---

### 3. Administração (Administration) → Como organizamos isso?
- Integramos o **RBAC do Kubernetes com RBAC do Azure AD**.  
- Criamos grupos no Azure AD como:  
  - `aks-dev-readers`  
  - `aks-sre-admins`  
  - `aks-ci-cd-pipeline`  

Assim, quando alguém entra na empresa:  
- Basta adicioná-lo no grupo certo no Azure AD.  
- O acesso no cluster é automático, sem precisar editar permissões no Kubernetes.

---

## Exemplo de Configuração

👉 **Role** (ler pods no namespace `dev`):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

👉 **RoleBinding** (ligar grupo Azure AD ao Role):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: dev
subjects:
- kind: Group
  name: "aks-dev-readers"   # grupo no Azure AD
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Resultado:  
Quem estiver no grupo **aks-dev-readers** consegue rodar:  
```bash
kubectl get pods -n dev
```
Mas não consegue criar ou deletar pods.

---

## Fluxo Resumido (AKS + RBAC)

1. **Você se autentica** no Azure AD → recebe um token.  
2. **Cluster valida o token** → confirma quem você é.  
3. **RBAC verifica permissões** → esse usuário/grupo pode executar essa ação?  
4. **Decisão final** → autorizado ✅ ou negado ❌.

---

## Boas práticas de administração
- Sempre use **grupos do Azure AD**, não usuários individuais.  
- Defina **níveis de acesso claros**:  
  - Dev → apenas no namespace da squad.  
  - Ops/SRE → permissões mais amplas.  
  - Admin → acesso total, mas com MFA obrigatório.  
