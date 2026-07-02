## Section 2 - Infra deployment



7. Rancher deployment

Ubuntu 22
Docker 28
Rancher v2.12.2
Kubernetes v1.33.4+rke2r1


```sh
aws ec2 run-instances --image-id "ami-0bbdd8c17ed981ef9" --instance-type "t3.large" --key-name "devopsv2" --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"SnapshotId":"snap-044c7fd1c01a7978c","VolumeSize":30,"VolumeType":"gp2"}}' --network-interfaces '{"SubnetId":"subnet-029d881ddd31e011e","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-052f9c8242d7b5617"]}' --credit-specification '{"CpuCredits":"unlimited"}' --instance-market-options '{"MarketType":"spot","SpotOptions":{"InstanceInterruptionBehavior":"terminate","MaxPrice":"0.04","SpotInstanceType":"one-time"}}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancher}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancher-volume}]'




aws ec2 run-instances --image-id "ami-0bbdd8c17ed981ef9" --instance-type "t3.large" --key-name "devopsv2" --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"SnapshotId":"snap-044c7fd1c01a7978c","VolumeSize":30,"VolumeType":"gp2"}}' --network-interfaces '{"SubnetId":"subnet-029d881ddd31e011e","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-052f9c8242d7b5617"]}' --credit-specification '{"CpuCredits":"unlimited"}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "1" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancher}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancher-volume}]'



# SSH into the machine
ssh -i devopsv2.pem ubuntu@3.237.99.170

# DOCKER 28.0 
# https://support.scc.suse.com/s/kb/360040967512?language=en_US

curl https://releases.rancher.com/install-docker/28.0.sh | sh

sudo usermod -aG docker $USER
newgrp docker
groups

docker ps

# Test it
# docker run hello-world

# sudo systemctl restart docker
# sudo service docker restart


# https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/other-installation-methods/rancher-on-a-single-node-with-docker

# https://github.com/rancher/rancher/releases

# Rancher - Rancher v2.12.2 
docker run -d --restart=unless-stopped \
      -p 80:80 -p 443:443 \
      -v /opt/rancher:/var/lib/rancher \
      --privileged \
      rancher/rancher:v2.12.2
```




8. Kubernetes deployment


**K8S Machine**

```sh
aws ec2 run-instances --image-id "ami-0bbdd8c17ed981ef9" --instance-type "t3.xlarge" --key-name "devopsv2" --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"SnapshotId":"snap-044c7fd1c01a7978c","VolumeSize":50,"VolumeType":"gp2"}}' --network-interfaces '{"SubnetId":"subnet-029d881ddd31e011e","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-052f9c8242d7b5617"]}' --credit-specification '{"CpuCredits":"unlimited"}' --instance-market-options '{"MarketType":"spot","SpotOptions":{"InstanceInterruptionBehavior":"terminate","MaxPrice":"0.10","SpotInstanceType":"one-time"}}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "3" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s-volume}]'



aws ec2 run-instances --image-id "ami-0bbdd8c17ed981ef9" --instance-type "t3.xlarge" --key-name "devopsv2" --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"SnapshotId":"snap-044c7fd1c01a7978c","VolumeSize":50,"VolumeType":"gp2"}}' --network-interfaces '{"SubnetId":"subnet-029d881ddd31e011e","AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["sg-052f9c8242d7b5617"]}' --credit-specification '{"CpuCredits":"unlimited"}' --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":false,"EnableResourceNameDnsAAAARecord":false}' --count "2" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s-volume}]' 

```

Client Version: v1.33.1
Kustomize Version: v5.6.0
Server Version: v1.33.4+rke2r1


```sh

ssh -i devopsv2.pem ubuntu@3.237.67.87
# ssh -i devopsv2.pem ubuntu@3.238.191.109
# ssh -i devopsv2.pem ubuntu@44.192.117.123

# Kubernetes  v1.33.4
# Insecure

curl --insecure -fL https://44.200.158.141/system-agent-install.sh | sudo  sh -s - --server https://44.200.158.141 --label 'cattle.io/os=linux' --token mx9schb99w4rsmtk4qf5f2nrw89rpbhbl7tdj8stjcq7jbb6hwrw9c --ca-checksum 360e174ca1a34afe2332be57b39d92b43860728d1104ce70bdb0c6b8ad915f2c --etcd --controlplane --worker

```


9. DNS setup




