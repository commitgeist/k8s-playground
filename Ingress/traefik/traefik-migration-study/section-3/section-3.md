## Section 3 - Current Ingress - NGINX

10. Application deployment

```sh

cd application

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=python.rancher.devopsforlife.io/O=Local Dev"


kubectl create secret tls python-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n default


kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

```