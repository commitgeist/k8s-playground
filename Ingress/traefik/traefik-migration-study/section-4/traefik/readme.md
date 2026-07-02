
# Traefik install

https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml


Apenas adicionar o certificado no Traefik e fazer o diagrama da infraestrutura.


```sh

helm repo add traefik https://traefik.github.io/charts

helm repo update

kubectl create namespace traefik

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=traefik.rancher.devopsforlife.io"

kubectl create secret tls traefik-dashboard-cert \
  --cert=tls.crt \
  --key=tls.key \
  -n traefik

helm install traefik traefik/traefik \
  --namespace traefik \
  --values values.yaml

helm upgrade traefik traefik/traefik \
  --namespace traefik \
  --values values.yaml


# Access using
# https://traefik.rancher.devopsforlife.io/dashboard/
```




