## Section 4 - New Ingress - Traefik

11. Traefik installation

Folder Traefik

Acess traefik with 

https://traefik.rancher.devopsforlife.io/dashboard/


12. HAProxy Setup - Load Balancer


## HAProxy


```sh

aws ec2 run-instances --image-id "ami-0bbdd8c17ed981ef9" --instance-type "t3.small" --key-name "devopsv2" --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"SnapshotId":"snap-044c7fd1c01a7978c","VolumeSize":30,"VolumeType":"gp2"}}' --network-interfaces '{"SubnetId":"subnet-029d881ddd31e011e","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-052f9c8242d7b5617"]}' --credit-specification '{"CpuCredits":"unlimited"}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=haproxy}]' 'ResourceType=volume,Tags=[{Key=Name,Value=haproxy-volume}]'


# SSH into the machine
ssh -i devopsv2.pem ubuntu@44.215.111.149

# DOCKER 28.0 
# https://support.scc.suse.com/s/kb/360040967512?language=en_US

curl https://releases.rancher.com/install-docker/28.0.sh | sh

sudo usermod -aG docker $USER
newgrp docker
groups


# Folder haproxy


# Instalar kubectl and kubeconfig
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# baixe o validador
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

# Valide

echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# kubectl: OK


sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client


kubectl get nodes --selector='node-role.kubernetes.io/worker' -o jsonpath='{range .items[?(@.status.conditions[-1].status=="True")]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
```


