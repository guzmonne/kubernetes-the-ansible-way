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

