# section-5 - Live Migration


13. DNS Setup

Configure  Route53 to point to the HAProxy Load Balancer machine



14. Traefik Dashboard

Access the Dashboard




15. Application NEW Ingress with Traefik

Apply the new ingress of the application

Folder application, apply the new ingress controller

```sh
kubectl apply -f ingress.yaml
```



16. HAProxy cluster automation


## Automation

- kubectl and kubeconfig: Ensure the kubectl tool is installed and your cluster's kubeconfig file is placed on the machine (e.g., at /home/ubuntu/.kube/config).

- Permissions: The user running the script and the cron job must have sudo or direct permissions to run docker restart.



```sh

# User ubuntu
# Pasta para o kubeonfig
mkdir -p ~/.kube



# Instalar kubectl and kubeconfig
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# baixe o validador
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

# Valide

echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# kubectl: OK


sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client


# Copy kubeconfig

kubectl get nodes --selector='node-role.kubernetes.io/worker' -o jsonpath='{range .items[?(@.status.conditions[-1].status=="True")]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'





# Editar o arquivo
sudo vi /usr/local/bin/update_haproxy.sh


sudo touch /var/log/haproxy_update.log

sudo chmod +x /usr/local/bin/update_haproxy.sh


```




```sh
#!/bin/bash

# --- Configuration ---
export KUBECONFIG="/home/ubuntu/.kube/config"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
HAPROXY_CONTAINER_NAME="haproxy-proxy"
HTTP_PORT="30080"
HTTPS_PORT="30443"

# Ensure kubectl is in path (useful for cron)
export PATH=$PATH:/usr/local/bin:/usr/bin

# --- Function to generate the HAProxy server list ---
generate_servers() {
    local PORT=$1
    local BACKEND_SERVERS=""
    local NODE_COUNT=0

    # CHECK: Changed to ExternalIP based on your comment. 
    # Switch back to "InternalIP" if HAProxy is on the same LAN as the nodes.
    NODE_IPS=$(kubectl get nodes --selector='node-role.kubernetes.io/worker' -o jsonpath='{range .items[?(@.status.conditions[-1].status=="True")]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}')

    # If no worker nodes found (common in single node clusters), try fetching all nodes
    if [ -z "$NODE_IPS" ]; then
         NODE_IPS=$(kubectl get nodes -o jsonpath='{range .items[?(@.status.conditions[-1].status=="True")]}{.status.addresses[?(@.type=="IntenralIP")].address}{"\n"}{end}')
    fi

    if [ -z "$NODE_IPS" ]; then
        echo "ERROR: No ready nodes found." >&2
        return 1
    fi

    for IP in $NODE_IPS; do
        NODE_COUNT=$((NODE_COUNT + 1))
        # Added 'check' and 'inter' for health checking
        BACKEND_SERVERS+="    server node${NODE_COUNT} ${IP}:${PORT} check inter 3000ms\n"
    done

    echo -e "$BACKEND_SERVERS"
}

# Generate parts first to catch errors before creating the template
SERVERS_HTTP=$(generate_servers $HTTP_PORT)
if [ $? -ne 0 ]; then exit 1; fi

SERVERS_HTTPS=$(generate_servers $HTTPS_PORT)
if [ $? -ne 0 ]; then exit 1; fi

# --- Core HAProxy Configuration Template ---
CONFIG_TEMPLATE=$(cat <<EOF
global
    log stdout format raw local0
    maxconn 2048

defaults
    log global
    mode tcp
    option tcplog
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

# --- HTTP (Port 80) Entrypoint ---
frontend http-in
    bind *:80
    default_backend traefik-web

backend traefik-web
    balance roundrobin
    option tcp-check
$SERVERS_HTTP

# --- HTTPS (Port 443) Entrypoint ---
frontend https-in
    bind *:443
    default_backend traefik-websecure

backend traefik-websecure
    balance roundrobin
    option tcp-check
$SERVERS_HTTPS
EOF
)

# --- Update and Reload ---

# 1. Compare the generated config with the current config
# We use a temporary file to compare cleanly
echo "$CONFIG_TEMPLATE" > /tmp/haproxy_new.cfg

if ! cmp -s /tmp/haproxy_new.cfg "$HAPROXY_CONFIG"; then
    echo "$(date): Configuration changed. Updating and Reloading."

    # 2. Validate config with HAProxy container before applying (Optional but recommended)
    # This requires mounting the tmp file or just trusting the generator. 
    # For now, we trust the generator and apply.
    
    mv /tmp/haproxy_new.cfg "$HAPROXY_CONFIG"

    # 3. SOFT RELOAD (Zero Downtime)
    # Sending SIGHUP tells HAProxy to reload config without dropping connections
    if sudo docker kill -s HUP "$HAPROXY_CONTAINER_NAME"; then
        echo "$(date): HAProxy reloaded successfully."
    else
        echo "$(date): ERROR - Failed to reload HAProxy container."
        exit 1
    fi
else
    echo "$(date): Configuration unchanged."
    rm /tmp/haproxy_new.cfg
fi

```

## Open the Crontab Editor:

```sh

crontab -e

```

## Add the Cron Entry: Add the following line to the end of the file. This tells the system to execute your script every 5 minutes:

```sh
# Test the script - add new machines or remove
sudo /usr/local/bin/update_haproxy.sh

sudo docker logs --tail 50 -f haproxy-proxy


# Runs the HAProxy update script every 5 minutes
*/5 * * * * /usr/local/bin/update_haproxy.sh >> /var/log/haproxy_update.log 2>&1


tail -f /var/log/haproxy_update.log

```


ADD new machines to the cluster and run the script, and validate that the new machines are there.





17. NGINX Removal

Remove the  rke2-ingress-nginx-controller from the kube-system namespace.
```sh
kubectl delete daemonset rke2-ingress-nginx-controller -n kube-system

# Delete related resources (optional, but good for cleanup)
kubectl delete service rke2-ingress-nginx-controller -n kube-system
kubectl delete service rke2-ingress-nginx-controller-hostport -n kube-system


kubectl delete validatingwebhookconfiguration rke2-ingress-nginx-admission


# 1. Delete the HelmChart resource (this instructs the controller to uninstall the chart)
kubectl delete helmchart rke2-ingress-nginx -n kube-system

# 2. (Optional) Delete the associated HelmChartConfig if one exists
kubectl delete helmchartconfig rke2-ingress-nginx -n kube-system
```