# Configurando ETCD
Kubernetes guarda el estado de todos sus componentes en una base de datos, esta base de datos es ETCD

### Instalación
```bash
ETCD_VER=v3.5.1

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-bin && mkdir -p /tmp/etcd-download-bin

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-bin --strip-components=1 
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

sudo mv /tmp/etcd-download-bin/etcd* /usr/local/bin/
```

### Configurando ETCD
```bash
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo chmod 700 /var/lib/etcd

  # usamos los certificados generados en el paso 02
  sudo cp ca/ca.pem kube-apiserver/kubernetes.pem kube-apiserver/kubernetes-key.pem /etc/etcd
}
```

ETCD va a escuchar en la ip primaria del servidor controller-1

```bash
INTERNAL_IP=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
```

Configuramos el nombre del nodo ETCD, este debe ser unico para poder configurar un cluster en el futuro
```bash
ETCD_NAME=$(hostname -s)
[[ -d /usr/lib/systemd/system/ ]] && SYSTEMD_LIB=/usr/lib/systemd/system || SYSTEMD_LIB=/etc/systemd/system
```

Creamos la unidad de systemd para manejar el cluster etcd
```bash
cat <<EOF | sudo tee ${SYSTEMD_LIB}/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-1=https://192.168.5.11:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Inicializamos el cluster
```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
```

## Verificamos
```bash
sudo ETCDCTL_API=3 /usr/local/bin/etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

```

**Siguiente** [Control Plane](06-configurando-control-plane.markdown)
