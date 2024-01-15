# O que são Annotations do Kubernetes?
As Annotations no Kubernetes são usadas para adicionar metadados arbitrários aos objetos do Kubernetes, como pods, services, deployments, etc. Esses metadados podem ser usados por ferramentas e bibliotecas de terceiros, ou simplesmente para armazenar informações adicionais para fins de diagnóstico ou organizacionais.

## Características Chave:
Não Identificáveis: Diferentemente dos Labels, as Annotations não são usadas para identificar e selecionar objetos.
Flexibilidade: Podem incluir dados grandes ou estruturados, como URLs, JSON, ou blobs de dados.

##

**Características Chave:**
Não Identificáveis: 
-  Diferentemente dos Labels, as Annotations não são usadas para identificar e selecionar objetos.
Flexibilidade: Podem incluir dados grandes ou estruturados, como URLs, JSON, ou blobs de dados.


<hr/>

# Criando e Usando Annotations
```yaml
metadata:
  annotations:
    chave: "valor"
    exemplo.com/annotation: "alguma informação"

```

Em fim,as  annotations são ferramentas poderosas para adicionar metadados não identificáveis aos objetos do Kubernetes. Seu uso correto pode facilitar a automação, o monitoramento e a gestão de informações adicionais. Contudo, é essencial gerenciá-las com cuidado para garantir a segurança e a eficiência do sistema.