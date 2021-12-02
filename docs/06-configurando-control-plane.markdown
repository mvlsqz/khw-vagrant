# Configurando Control Plane

## Creamos el directorio base

```bash
sudo mkdir -p /etc/kubernetes/config/
```

## Descargamos los binarios necesarios
```bash
for binary in kube-apiserver kube-controller-manager kube-scheduler
do
 sudo curl -o /usr/local/bin/${binary} https://storage.googleapis.com/kubernetes-release/release/v1.22.4/bin/linux/amd64/${binary}
done
```

## Instalamos los binarios
```bash
{
  for binary in kube-apiserver kube-controller-manager kube-scheduler
  do
    sudo chmod +x /usr/local/bin/${binary}
  done

  [[ -d /usr/lib/systemd/system/ ]] && SYSTEMD_LIB=/usr/lib/systemd/system || SYSTEMD_LIB=/etc/systemd/system
}
```

## Configuramos kubernetes API server
```bash
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo cp ca/ca.pem ca/ca-key.pem kube-apiserver/kubernetes.pem kube-apiserver/kubernetes-key.pem \
    service-account/service-account.pem service-account/service-account-key.pem \
    secure/encryption-config.yaml /var/lib/kubernetes/
}
```

La interfaz de red interna se usara para contactar a los miembros del cluster
```bash
INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
KUBERNETES_PUBLIC_ADDRESS=192.168.5.11
```

### Creamos el servicio de systemd para API server

```bash
cat <<EOF | sudo tee ${SYSTEMD_LIB}/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://192.168.5.11:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --runtime-config='api/all=true' \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-account-signing-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-account-issuer=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Configuramos Kubernetes Controller Manager

```bash
sudo cp kubeconfigs/kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

### creamos la unidad de systemd para kube-controller-manager
```bash
cat <<EOF | sudo tee ${SYSTEMD_LIB}/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
## Configuracion de Kubernetes Scheduler

` sudo mv kubeconfigs/kube-scheduler.kubeconfig /var/lib/kubernetes/`

Creamos la confiuracion del  kube-scheduler

```bash
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

```

Creamos la unidad de systemd
```bash
cat <<EOF | sudo tee ${SYSTEMD_LIB}/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Iniciamos todos los servicios
```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}

```

## Validamos
```bash
kubectl get componentstatuses --kubeconfig kubeconfigs/admin.kubeconfig

```

## Configuracón RBAC para los clientes kubelet

```bash
cat <<EOF | kubectl apply --kubeconfig kubeconfigs/admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

Agregamos el rol `system:kube-apiserver-to-kubelet` al usuario kubernetes el cual sera usado por kubelet

```bash
cat <<EOF | kubectl apply --kubeconfig kubeconfigs/admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

```

## Verificamos de nuevo el cluster
` curl --cacert ca/ca.pem https://192.168.5.11:6443/version `
