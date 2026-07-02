
Create a file named haproxy.cfg on your EC2 instance (e.g., in /etc/haproxy/).

10.0.1.38
10.0.1.28
10.0.1.219


```sh
sudo mkdir -p /etc/haproxy
vi /etc/haproxy/haproxy.cfg
```

```cfg
global
    log /dev/log    daemon
    maxconn 2048

defaults
    log global
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

# --- HTTP (Port 80) Entrypoint ---
frontend http-in
    bind *:80
    mode tcp
    default_backend traefik-web

backend traefik-web
    mode tcp
    balance roundrobin # Load balancing across worker nodes
    # Replace <NODE_1_IP> and <NODE_2_IP> with your actual Kubernetes Node IPs
    server node1 10.0.1.214:30080 check
    #server node2 10.0.1.28:30080 check
    #server node3 10.0.1.219:30080 check

# --- HTTPS (Port 443) Entrypoint ---
frontend https-in
    bind *:443
    mode tcp
    default_backend traefik-websecure

backend traefik-websecure
    mode tcp
    balance roundrobin
    # Replace <NODE_1_IP> and <NODE_2_IP> with your actual Kubernetes Node IPs
    server node1 10.0.1.214:30443 check
    #server node2 10.0.1.28:30443 check
    #server node3 10.0.1.219:30443 check

```


- mode tcp: Used because HAProxy is simply forwarding the raw TCP connection (including SSL/TLS) without inspecting the HTTP headers. This preserves the TLS connection all the way to Traefik.

- balance roundrobin: Ensures traffic is evenly distributed between your Kubernetes worker nodes for redundancy.

- check: Enables health checking to automatically remove a Kubernetes node from the pool if Traefik becomes unreachable on that NodePort.


# Deploy the HAProxy container

```sh

sudo docker run -d \
  --restart=always \
  --name haproxy-proxy \
  -v /etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  -p 80:80 \
  -p 443:443 \
  haproxy:latest

```

- -v /etc/haproxy/haproxy.cfg	This is the path to your configuration file on the EC2 instance's filesystem (the file you created in Step 1).
- :/usr/local/etc/haproxy/haproxy.cfg	This is the path inside the HAProxy container where it expects to find its configuration.
- :ro	Sets the volume mount to read-only, which is a good security practice.
- -p 80:80	Maps the EC2 instance's port 80 to the container's port 80.
- -p 443:443	Maps the EC2 instance's port 443 to the container's port 443.


```sh

sudo docker restart haproxy-proxy

```












