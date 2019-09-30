# Bootstrap an `etcd` cluster

This commands where created from the [etcd site](https://play.etcd.io/install).

## Install `cfssl` on Linux

```bash
rm -f /tmp/cfssl* && rm -rf /tmp/certs && mkdir -p /tmp/certs

curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /tmp/cfssl
chmod +x /tmp/cfssl
sudo mv /tmp/cfssl /usr/local/bin/cfssl

curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /tmp/cfssljson
chmod +x /tmp/cfssljson
sudo mv /tmp/cfssljson /usr/local/bin/cfssljson

/usr/local/bin/cfssl version
/usr/local/bin/cfssljson -h

mkdir -p /tmp/certs
```

## Generate self-signed root CA certificate

We will use this root CA to generate other TLS assets for validating client-to-server and peer-to-peer communication. Unique certificates are less convenient to generate and deploy, but they do provide stronger security assurances and the most portable installation experience across multiple cloud-based and on-premises Kubernetes deployments.

To create the CA we need to specify some details:

- Organization
- Organization Unit
- City
- State
- Country
- Key Algorithm (rsa)
- Key Size (2048)
- Key Expiration (87000 hour)
- Common Name

```bash
cat > /tmp/certs/etcd-root-ca-csr.json <<EOF
{
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "O": "CONATEL S.A.",
      "OU": "kubernetes-fundamentals",
      "L": "Montevideo",
      "ST": "Montevideo",
      "C": "UY"
    }
  ],
  "CN": "etcd-root-ca.pem"
}
EOF

cfssl gencert \
  --initca=true \
  /tmp/certs/etcd-root-ca-csr.json |\
cfssljson --bare /tmp/certs/etcd-root-ca

# verify
openssl x509 -in /tmp/certs/etcd-root-ca.pem -text -noout

# cert-generation configuration
cat > /tmp/certs/etcd-gencert.json <<EOF
{
  "signing": {
    "default": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
    }
  }
}
EOF
```

Results:

```bash
# CSR configuration
/tmp/certs/etcd-root-ca-csr.json
# CSR
/tmp/certs/etcd-root-ca.csr
# self-signed root CA public key
/tmp/certs/etcd-root-ca.pem
# self-signed root CA private key
/tmp/certs/etcd-root-ca-key.pem
# cert-generation configuration for other TLS assets
/tmp/certs/etcd-gencert.json
```

## Generate local-issued certificates with private keys

```bash
cat > /tmp/certs/etcd-node-ca-csr.json <<EOF
{
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "O": "CONATEL S.A.",
      "OU": "kubernetes-fundamentals",
      "L": "Montevideo",
      "ST": "Montevideo",
      "C": "UY"
    }
  ],
  "CN": "etcd-node",
  "hosts": [
    "127.0.0.1",
    "localhost",
    "10.240.1.171",
    "10.240.0.38",
    "10.240.2.208"
  ]
}
EOF

cfssl gencert \
  --ca /tmp/certs/etcd-root-ca.pem \
  --ca-key /tmp/certs/etcd-root-ca-key.pem \
  --config /tmp/certs/etcd-gencert.json \
  /tmp/certs/etcd-node-ca-csr.json |\
cfssljson --bare /tmp/certs/etcd-node

# verify
openssl x509 -in /tmp/certs/etcd-node.pem -text -noout
```

Result:

```bash
/etc/etcd/etcd-node-ca-csr.json
/etc/etcd/etcd-node.csr
/etc/etcd/etcd-node-key.pem
/etc/etcd/etcd-node.pem
```

Transfer certs to all machines

```bash
# Create the remote /etc/etcd folder
ssh -oStrictHostKeyChecking=no ubuntu@10.240.1.171 'sudo mkdir -p /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.0.38 'sudo mkdir -p /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.2.208 'sudo mkdir -p /etc/etcd'
# Copy the certidficates from the bastion
scp /tmp/certs/etcd* ubuntu@10.240.1.171:/home/ubuntu
scp /tmp/certs/etcd* ubuntu@10.240.0.38:/home/ubuntu
scp /tmp/certs/etcd* ubuntu@10.240.2.208:/home/ubuntu
# Move the certificates to the /etc/etcd folder
ssh -oStrictHostKeyChecking=no ubuntu@10.240.1.171 'sudo mv /home/ubuntu/etcd* /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.0.38 'sudo mv /home/ubuntu/etcd* /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.2.208 'sudo mv /home/ubuntu/etcd* /etc/etcd'
```

## Install etcd

On Linux

```bash
ETCD_VER=v3.3.8

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/coreos/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo rm -rf /usr/local/bin/etcd && sudo rm -rf /usr/local/bin/etcdctl

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /usr/local/bin --strip-components=1

/usr/local/bin/etcd --version
ETCDCTL_API=3 /usr/local/bin/etcdctl version

sudo mkdir -p /var/lib/etcd
```

## Run with Bare metal, VM

Attention:

- Make sure etcd process has write access to this directory `sudo mkdir -p /var/lib/etcd`.
- Remove this directory if the cluster is new; keep if restarting etcd `sudo rm -rf /var/lib/etcd`. 

```bash
sudo mv etcd* /etc/etcd
```

### etcd node 1

```bash
sudo /usr/local/bin/etcd --name etcd-node-1 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.1.171:2379 \
  --advertise-client-urls https://10.240.1.171:2379 \
  --listen-peer-urls https://10.240.1.171:2380 \
  --initial-advertise-peer-urls https://10.240.1.171:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem
```

### etcd node 2

```bash
sudo /usr/local/bin/etcd --name etcd-node-2 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.0.38:2379 \
  --advertise-client-urls https://10.240.0.38:2379 \
  --listen-peer-urls https://10.240.0.38:2380 \
  --initial-advertise-peer-urls https://10.240.0.38:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem
```

### etcd node 3

```bash
sudo /usr/local/bin/etcd --name etcd-node-3 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.2.208:2379 \
  --advertise-client-urls https://10.240.2.208:2379 \
  --listen-peer-urls https://10.240.2.208:2380 \
  --initial-advertise-peer-urls https://10.240.2.208:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem
```

Check status:

```bash
ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints 10.240.1.171:2379,10.240.0.38:2379,10.240.2.208:2379 \
  --cacert /etc/etcd/etcd-root-ca.pem \
  --cert /etc/etcd/etcd-node.pem \
  --key /etc/etcd/etcd-node-key.pem \
  endpoint health
```

## Run with systemd

Attention:

- Make sure etcd process has write access to this directory.
- Remove this directory if the cluster is new; keep if restarting etcd `rm -rf /var/lib/etcd`. 

### etcd node 1

Write service file for etcd 

```bash
cat > /tmp/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/var/lib/etcd/etcd --name etcd-node-1 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.1.171:2379 \
  --advertise-client-urls https://10.240.1.171:2379 \
  --listen-peer-urls https://10.240.1.171:2380 \
  --initial-advertise-peer-urls https://10.240.1.171:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/etcd.service /etc/systemd/system/etcd.service
```

### etcd node 2

Write service file for etcd 

```bash
cat > /tmp/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/var/lib/etcd/etcd --name etcd-node-2 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.0.38:2379 \
  --advertise-client-urls https://10.240.0.38:2379 \
  --listen-peer-urls https://10.240.0.38:2380 \
  --initial-advertise-peer-urls https://10.240.0.38:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/etcd.service /etc/systemd/system/etcd.service
```

### etcd node 3

Write service file for etcd 

```bash
cat > /tmp/etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos/etcd
Conflicts=etcd.service
Conflicts=etcd2.service

[Service]
Type=notify
Restart=always
RestartSec=5s
LimitNOFILE=40000
TimeoutStartSec=0

ExecStart=/var/lib/etcd/etcd --name etcd-node-3 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.2.208:2379 \
  --advertise-client-urls https://10.240.2.208:2379 \
  --listen-peer-urls https://10.240.2.208:2380 \
  --initial-advertise-peer-urls https://10.240.2.208:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --cert-file /etc/etcd/etcd-node.pem \
  --key-file /etc/etcd/etcd-node-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/etcd-root-ca.pem \
  --peer-cert-file /etc/etcd/etcd-node.pem \
  --peer-key-file /etc/etcd/etcd-node-key.pem

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/etcd.service /etc/systemd/system/etcd.service
```

### Start the service

```bash
sudo systemctl daemon-reload
sudo systemctl cat etcd.service
sudo systemctl enable etcd.service
sudo systemctl start etcd.service
```

### Get logs from service

```bash
sudo systemctl status etcd.service -l --no-pager
sudo journalctl -u etcd.service -l --no-pager|less
sudo journalctl -f -u etcd.service
```

### Stop service

```bash
sudo systemctl stop etcd-node.service
sudo systemctl disable etcd-node.service
```

### Check status

```bash
ETCDCTL_API=3 /var/lib/etcd/etcdctl \
  --endpoints 10.240.1.171:2379,10.240.0.38:2379,10.240.2.208:2379 \
  --cacert /etc/etcd/etcd-root-ca.pem \
  --cert /etc/etcd/etcd-node.pem \
  --key /etc/etcd/etcd-node-key.pem \
  endpoint health
```

## Kubernetes the hardway certificates

Create the certificate authority.

```bash
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

openssl x509 -in ca.pem -text -noout
```

Now we create the kubernetes certificate.

```bash
KUBERNETES_PUBLIC_DOMAIN="*.kubernetes.conatest.click"
KUBERNETES_PRIVATE_DOMAIN="*.internal.kubernetes.conatest.click"
KUBERNETES_MASTER_PRIVATE_IPS="10.240.1.171,10.240.0.38,10.240.2.208"
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_DOMAIN},${KUBERNETES_PRIVATE_DOMAIN},${KUBERNETES_MASTER_PRIVATE_IPS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

openssl x509 -in kubernetes.pem -text -noout
```

Copy the certificates to the remote masters

```bash
# Create the remote /etc/etcd folder
ssh -oStrictHostKeyChecking=no ubuntu@10.240.1.171 'mkdir -p /home/ubuntu/certs'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.0.38 'mkdir -p /home/ubuntu/certs'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.2.208 'mkdir -p /home/ubuntu/certs'
# Copy the certidficates from the bastion
scp ~/certs/* ubuntu@10.240.1.171:/home/ubuntu/certs
scp ~/certs/* ubuntu@10.240.0.38:/home/ubuntu/certs
scp ~/certs/* ubuntu@10.240.2.208:/home/ubuntu/certs
# Move the certificates to the /etc/etcd folder
ssh -oStrictHostKeyChecking=no ubuntu@10.240.1.171 'sudo mv /home/ubuntu/certs/* /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.0.38 'sudo mv /home/ubuntu/certs/* /etc/etcd'
ssh -oStrictHostKeyChecking=no ubuntu@10.240.2.208 'sudo mv /home/ubuntu/certs/* /etc/etcd'
```

Now we run `etcd` with this certificates.

### etcd node 1

```bash
sudo /usr/local/bin/etcd --name etcd-node-1 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.1.171:2379 \
  --advertise-client-urls https://10.240.1.171:2379 \
  --listen-peer-urls https://10.240.1.171:2380 \
  --initial-advertise-peer-urls https://10.240.1.171:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/ca.pem \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem
```

### etcd node 2

```bash
sudo /usr/local/bin/etcd --name etcd-node-2 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.0.38:2379 \
  --advertise-client-urls https://10.240.0.38:2379 \
  --listen-peer-urls https://10.240.0.38:2380 \
  --initial-advertise-peer-urls https://10.240.0.38:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/ca.pem \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem
```

### etcd node 3

```bash
sudo /usr/local/bin/etcd --name etcd-node-3 \
  --data-dir /var/lib/etcd \
  --listen-client-urls https://10.240.2.208:2379 \
  --advertise-client-urls https://10.240.2.208:2379 \
  --listen-peer-urls https://10.240.2.208:2380 \
  --initial-advertise-peer-urls https://10.240.2.208:2380 \
  --initial-cluster etcd-node-1=https://10.240.1.171:2380,etcd-node-2=https://10.240.0.38:2380,etcd-node-3=https://10.240.2.208:2380 \
  --initial-cluster-token etcd-cluster-token \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file /etc/etcd/ca.pem \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem
```

Check status:

```bash
ETCDCTL_API=3 /usr/local/bin/etcdctl \
  --endpoints 10.240.1.171:2379,10.240.0.38:2379,10.240.2.208:2379 \
  --cacert /etc/etcd/ca.pem \
  --cert /etc/etcd/kubernetes.pem \
  --key /etc/etcd/kubernetes-key.pem \
  endpoint health
```