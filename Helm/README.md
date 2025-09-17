# 1. O que é o Helm?  
Helm é o **gerenciador de pacotes do Kubernetes**.  
Pensa nele como o `apt` ou `yum` do Linux: em vez de escrever dezenas de YAMLs, tu instala **um pacote chamado Chart** que já contém todos os manifests.

👉 **Benefícios para DevOps:**
- Menos YAML manual.  
- Atualizações simples com `upgrade`.  
- Rollback fácil se algo quebrar.  
- Padronização entre dev, QA e prod.  

---

## 2. Conceitos básicos

| Conceito  | O que é |
|-----------|---------|
| **Chart** | O pacote do Helm, com templates YAML + variáveis. |
| **Release** | Instância instalada de um chart (pode ter várias no mesmo cluster). |
| **Repo** | Onde ficam os charts (ArtifactHub, Bitnami, repositório interno). |
| **Values.yaml** | Arquivo com variáveis que personalizam o chart. |

---

## 3. Instalação

```bash
# Linux/Mac
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows (via Chocolatey)
choco install kubernetes-helm
```

Verificar:
```bash
helm version
```

Adicionar repositório oficial:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

ou 

## Instalando diferente

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
---

## 4. Primeiro deploy com Helm

### Exemplo: NGINX
```bash
helm install meu-nginx bitnami/nginx
```

Ver releases:
```bash
helm list -A
```

Testar no navegador:
```bash
kubectl port-forward svc/meu-nginx 8080:80
```
→ acessar http://localhost:8080  

---

## 5. Trabalhando com `values.yaml`

O `values.yaml` é onde tu personaliza o chart.

Exemplo (`values-prod.yaml`):
```yaml
replicaCount: 3
image:
  repository: nginx
  tag: 1.25.0
service:
  type: ClusterIP
  port: 80
```

Instalar usando ele:
```bash
helm install meu-nginx bitnami/nginx -f values-prod.yaml
```

---

## 6. Criando teu próprio Chart

Criar chart base:
```bash
helm create meuapp
```

Estrutura:
```
meuapp/
├── Chart.yaml
├── values.yaml
└── templates/
```

Exemplo `deployment.yaml` dentro de `templates/`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

Instalar:
```bash
helm install meuapp ./meuapp
```

---

## 7. Operações do dia a dia

```bash
# Atualizar release
helm upgrade meuapp ./meuapp -f values-prod.yaml

# Ver histórico
helm history meuapp

# Rollback (voltar para versão anterior)
helm rollback meuapp 1

# Desinstalar
helm uninstall meuapp
```

---

## 8. Boas práticas (DevOps real)

- **Separar configs por ambiente:**  
  `values-dev.yaml`, `values-qa.yaml`, `values-prod.yaml`.  
- **Não salvar secrets em values.yaml.**  
  → Usar **Azure Key Vault CSI Driver** ou Secrets do K8s.  
- **Lint antes de aplicar:**  
  ```bash
  helm lint ./meuapp
  ```  
- **Scannear charts:**  
  ```bash
  trivy config ./meuapp
  ```

---

## 9. Helm no CI/CD

### Exemplo no **Azure DevOps**
```yaml
- task: HelmInstaller@1
  inputs:
    helmVersionToInstall: 'latest'

- task: HelmDeploy@0
  inputs:
    connectionType: 'Kubernetes Service Connection'
    namespace: 'default'
    command: 'upgrade'
    chartType: 'FilePath'
    chartPath: 'charts/meuapp'
    releaseName: 'meuapp'
    valueFile: 'values-prod.yaml'
```

### Exemplo no **GitHub Actions**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/setup-helm@v3
      - run: helm upgrade --install meuapp ./charts/meuapp -f values-prod.yaml
```

---

## 10. Avançando com Helm

- **Subcharts:** dependências (ex.: app + Redis).  
- **Helmfile:** gerenciar várias releases em diferentes ambientes.  
- **GitOps:** usar ArgoCD para aplicar charts versionados no Git.  
- **Políticas:** validar com Kyverno/OPA antes do deploy.  

---

## 11. Exercícios práticos 📝

1. Instalar Redis usando `bitnami/redis`.  
2. Criar um chart chamado `meu-api` que roda um container simples (`nginx` ou `httpd`).  
3. Criar 3 `values.yaml`: dev, qa, prod, mudando só `replicaCount` e `image.tag`.  
4. Subir no Git e usar um pipeline para deploy automático no AKS.  

---

## 12. Referências

- [📚 Docs oficiais do Helm](https://helm.sh/docs/)  
- [🔍 ArtifactHub – charts prontos](https://artifacthub.io/)  
- [🛠️ Helmfile](https://github.com/roboll/helmfile)  
- [🔒 Trivy para Helm](https://aquasecurity.github.io/trivy/latest/docs/helm/)  

---

## 🎯 Conclusão

Com Helm, tu:
- Ganha **velocidade** (deploy rápido).  
- Garante **padrão** (mesmo chart → vários ambientes).  
- Facilita **rollback**.  
- Integra com **CI/CD e segurança**.  

👉 Agora é praticar: começa instalando apps prontos (Redis, PostgreSQL, NGINX) e depois cria teus próprios charts.  


