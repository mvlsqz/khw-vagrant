## **controller-1**

# Configuramos la autenticación para administrar el cluster

Para poder administrar nuestro cluster de manera sencilla vamos a configurar el kubeconfig para el usuario admin

```bash
cd
mkdir -p ~/.kube/
cp -a kubeconfigs/admin.kubeconfig ~/.kube/config

# comprobamos
kubectl get nodes -o wide
```

# Instalando un network plugin
Cuando los pods son programados para correr en un nodo estos reciben una dirección IP del rango establecido en el POD_CIDR, en este punto los los pods no pueden comunicarse con otros pods que esten corriendo en un nodo distinto, esto es debido a que no saben como llegar a estos (no hay rutas).

Para solucionar esto en nuestra instalación usaremos [calico](curl https://docs.projectcalico.org/manifests/calico.yaml -O)

## Instalamos calicoctl

```bash
curl -o kubectl-calico -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.21.1/calicoctl" 
chmod +x kubectl-calico
sudo mv kubectl-calico /usr/local/bin
```

## Descargamos el manifiesto para instalar calico

```bash
curl -L -O https://docs.projectcalico.org/manifests/tigera-operator.yaml
```

## Cargamos el operador en el cluster
```bash
kubectl apply tigera-operator.yaml
```

## configuramos calico para usar BGP
BGP es un protocolo de red que nos permite intercambiar información de las tablas de rutas entre bloques de red

IPIP es un metodo de encapsulamiento de red para transmision de información.

```bash
cat <<EOF | tee calico-installation.yaml 
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Enabled
      
    ipPools:
    - blockSize: 26
      cidr: 10.200.0.0/16
      encapsulation: IPIP
      natOutgoing: Enabled
      nodeSelector: all()
EOF

kubectl apply -f calico-installation.yaml

# comprobamos, deberiamos ver los nodos workers con su ip
kubectl calico get nodes -o wide
```

# Configuarmos el nodo `loadbalancer` como bgp peer para el ingress controller
Vamos a usar calico para compartir las tablas de rutas de los nodos kubernetes con el nodo loadbalancer y de esta forma poder alcanzar los servicios desplegados en el cluster de kubernetes

```bash
# la ip del nodo loadbalancer
LOADBALANCER_IP=192.168.5.30

# El ASN por default que configura calico
ASN_NUMBER=64512

```

```bash
cat <<EOF | tee loadbalancer-bgp-peer.yaml
---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: loadbalancer-ingress-peer
spec:
  peerIP: ${LOADBALANCER_IP}
  asNumber: ${ASN_NUMBER}
EOF

kubectl calico apply -f loadbalancer-bgp-peer.yaml
```

**Siguente**: [Configuración DNS](09-instalacion-dns.markdown)
