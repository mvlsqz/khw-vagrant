# Kubeconfigs para autenticación

## IP publica de kubernetes

En este implementación vamos a utilizar un nodo externo como ip publica
```bash
KUBERNETES_PUBLIC_ADDRESS=192.168.5.11
```
` mkdir kubeconfigs`

### Kubeconfig para los clientes kubelet

```bash
for instance in worker-1 worker-2 worker-3; do
  kubectl config set-cluster kubernetes-cluster \
    --certificate-authority=ca/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kubeconfigs/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=workers/${instance}.pem \
    --client-key=workers/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster \
    --user=system:node:${instance} \
    --kubeconfig=kubeconfigs/${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/${instance}.kubeconfig
done

```

### Kubeconfig para kube-proxy
```bash
{
  kubectl config set-cluster kubernetes-cluster \
    --certificate-authority=ca/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy/kube-proxy.pem \
    --client-key=kube-proxy/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster \
    --user=system:kube-proxy \
    --kubeconfig=kubeconfigs/kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/kube-proxy.kubeconfig
}

```

### Kubeconfig para kube-controller-managere

```bash
{
  kubectl config set-cluster kubernetes-cluster \
    --certificate-authority=ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager/kube-controller-manager.pem \
    --client-key=kube-controller-manager/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster \
    --user=system:kube-controller-manager \
    --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/kube-controller-manager.kubeconfig
}

```

### Kubeconfig para kube-scheduler
```bash
{
  kubectl config set-cluster kubernetes-cluster \
    --certificate-authority=ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler/kube-scheduler.pem \
    --client-key=kube-scheduler/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster \
    --user=system:kube-scheduler \
    --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/kube-scheduler.kubeconfig
}
```

### Kubeconfigs para el usuario Admin
```bash
{
  kubectl config set-cluster kubernetes-cluster \
    --certificate-authority=ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfigs/admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin/admin.pem \
    --client-key=admin/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfigs/admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster \
    --user=admin \
    --kubeconfig=kubeconfigs/admin.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfigs/admin.kubeconfig
}

```
