# Kubernetes Fundamentals

## Setup environment

Activate Ansible environment

```bash
pyenv activate ansible;
export ANSIBLE_CONFIG=./ansible.cfg;
```

Load the AWS profile to use for the dynamic inventory

```bash
export AWS_PROFILE=conatest
```

## Install dependencies

### `cfssl`

> CFSSL is CloudFlare's PKI/TLS swiss army knife. It is both a command line tool and an HTTP API server for signing, verifying, and bundling TLS certificates. It requires Go 1.12+ to build.
> ...
> CFSSL consists of:
> - a set of packages useful for building custom TLS PKI tools
> - the `cfssl` program, which is the canonical command line utility using the CFSSL packages.
> - the `multirootca` program, which is a certificate authority server that can use multiple signing keys.
> - the `mkbundle` program is used to build certificate pool bundles.
> - the `cfssljson` program, which takes the JSON output from the `cfssl` and `multirootca` programs and writes certificates, keys, CSRs, and bundles to disk.
> 
> [Source](https://github.com/cloudflare/cfssl)

**Mac**

```
brew install cfssl
```

**Linux**

```
wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

chmod +x cfssl_linux-amd64 cfssljson_linux-amd64

sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl

sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

## Provisioning a CA and Generating TLS Certificates

We need to generate:

- Certificate Authority
  - `ca-config.json`
  - `ca-csr.json`
  - `ca-key.pem`
  - `ca.pem`
- Client and Server Certificates
  - `admin-csr.json`
  - `admin-key.pem`
  - `admin.pem`
- The Kubelet Client Certificates
  - `{{ private_dns_name }}-csr.json`
  - `{{ private_dns_name }}-key.pem`
  - `{{ private_dns_name }}.pem`
- The Controller Manager Client Certificate
  - `kube-controller-manager-csr.json`
  - `kube-controller-manager-key.pem`
  - `kube-controller-manager.pem`
- The Kube Proxy Client Certificate
  - `kube-proxy-csr.json`
  - `kube-proxy-key.pem`
  - `kube-proxy.pem`
- The Scheduler Client Certificate
  - `kube-scheduler-csr.json`
  - `kube-scheduler-key.pem`
  - `kube-scheduler.pem`
- The Kubernetes API Server Certificate
  - `kubernetes-csr.json`
  - `kubernetes-key.pem`
  - `kubernetes.pem`

##  How do certificates work?

A digital certificate is a form of identification, that provides information about the identity of an entity.

It is issued by a CA, or Certification Authority.

### Public Key Infraestructure

PKI consist of protocols, standards and services, that allows users to authenticate each other using digital certificates that are issued by a CA. The X.509, PKI X.509 and Public Key Cryptography Standards are the building blocks of a PKI System.

![Standard Digital Certificate Form](https://sites.google.com/site/amitsciscozone/_/rsrc/1468881655481/home/security/digital-certificates-explained/Digital%20Certificate%20Format.PNG)

### How can we obtain a digital certficate?

1. Generate a Key Pair
2. User A requests the certificate of the CA.
3. CA responds with its CA certificate including its Public Key.
4. After gathering information, User A requests the certificat which has User-A's identity and Public Key.
5. The CA verifies the identity of User A.
6. The CA issues a certificate for User A.

### What is TLS?

TLS, based on SSL, provides data encryption, data integrity, and authentication.

TLS allows to send messages that can be changed, and that can't be read by third parties. To do this, we need to encrypt and sign the message. Both of this processes requires keys.


