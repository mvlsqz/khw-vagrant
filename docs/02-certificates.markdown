# **controller-1**
Para poder configurar el cluster necesitamos generar un [PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure) usando un set de herramientas de CloudFare, y con esto configurar un CA para generar los certificados TLS para los siguientes componentes, etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelets, y kube-proxy.

# CA, TLS

Generamos el archivo de configuración para el CA, el certificado y la llave privada.
```bash
{

mkdir ca

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "24000h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "24000h"
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
      "C": "GT",
      "L": "Guatemala",
      "O": "Kubernetes",
      "OU": "GT",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

mv ca*.pem ca
}
```

## Certificados para el cliente Admin

```bash
mkdir admin

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "system:masters",
      "OU": "Kubernetes cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

mv admin*.pem admin
```
## Certificados para los clientes kubelet

```bash
mkdir workers

x=1
for instance in worker-1 worker-2 worker-3; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "system:nodes",
      "OU": "Kubernetes cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

NODE=$((x++))
INTERNAL_IP="192.168.5.2${NODE}"

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done

mv worker*.pem workers
```

## Certificados para el Controller Manager

```bash
mkdir kube-controller-manager


cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes Cluster",
      "ST": "GT"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

mv kube-controller-manager*.pem kube-controller-manager
```

## Certificados para Kube Proxy
```bash
mkdir kube-proxy

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "system:node-proxier",
      "OU": "Kubernetes Cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

mv kube-proxy*.pem kube-proxy
```

## Certificados para Kube Scheduler
```bash
mkdir kube-scheduler

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes Cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

mv kube-scheduler*.pem kube-scheduler
```

## Certificados para Kubernetes API Server

```bash
mkdir kube-apiserver
# nodo load balancer
KUBERNETES_PUBLIC_ADDRESS=192.168.5.31
KUBERNETES_DEFAULT_ADDRESSES=10.32.0.1,192.168.5.11,127.0.0.1
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
      "C": "GT",
      "L": "Guatemala",
      "O": "Kubernetes",
      "OU": "Kubernetes Cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -hostname=${KUBERNETES_DEFAULT_ADDRESSES},${KUBERNETES_PUBLIC_ADDRESS},${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

mv kubernetes*.pem kube-apiserver
```

## Certificados para Service Account
```bash
mkdir service-account

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "GT",
      "L": "Guatemala",
      "O": "Kubernetes",
      "OU": "Kubernetes Cluster",
      "ST": "Guatemala"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca/ca.pem \
  -ca-key=ca/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

mv service-account*.pem service-account
```

**Siguiente** [kubeconfigs](03-configs-para-autenticacion.markdown)
