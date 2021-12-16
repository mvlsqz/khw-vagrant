# Configurando Load Balancer
Vamos a utilizar haproxy ingress controller como balanceador de carga/ingress controller, para el uso de haproxy podemos consultar la [documentación](https://haproxy-ingress.github.io/) y [ejemplos](https://haproxy-ingress.github.io/)


# Instalación y configuración

```bash
# Instalamos haproxy
sudo add-apt-repository -y ppa:vbernat/haproxy-2.4
sudo apt update
sudo apt install -y haproxy

# Configuramos para que pueda capturar puertos privilegiados
sudo setcap cap_net_bind_service=+ep /usr/sbin/haproxy

# Descargamos e instalamos el ingress controller
wget https://github.com/haproxytech/kubernetes-ingress/releases/download/v1.6.2/haproxy-ingress-controller_1.6.2_Linux_x86_64.tar.gz 1> /dev/null 2> /dev/null
mkdir ingress-controller
tar -xzvf haproxy-ingress-controller_1.6.2_Linux_x86_64.tar.gz -C ./ingress-controller
sudo cp ./ingress-controller/haproxy-ingress-controller /usr/local/bin/
```

## Configuramos el servicio

```
PKG_MGR=$( command -v yum || command -v apt-get )

[[ -d /usr/lib/systemd/system/ ]] && SYSTEMD_LIB=/usr/lib/systemd/system || SYSTEMD_LIB=/etc/systemd/system 

mkdir /etc/haproxy/ingress-controller

cat <<EOF | sudo tee /etc/haproxy/ingress-controller/before.sh
#!/bin/bash -xe
/bin/mkdir -p /tmp/haproxy-ingress/etc/
/usr/bin/wget https://raw.githubusercontent.com/haproxytech/kubernetes-ingress/master/fs/usr/local/etc/haproxy/haproxy.cfg -P /tmp/haproxy-ingress/etc/
EOF

chmod +x /etc/haproxy/ingress-controller/before.sh 

cat <<EOF | sudo tee ${SYSTEMD_LIB}/haproxy-ingress.service  
[Unit]
Description="HAProxy Kubernetes Ingress Controller"
Documentation=https://www.haproxy.com/
Requires=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStartPre=/etc/haproxy/ingress-controller/before.sh
ExecStart=/usr/local/bin/haproxy-ingress-controller --external --configmap=default/haproxy-kubernetes-ingress --program=/usr/sbin/haproxy --disable-ipv6 --ipv4-bind-address=0.0.0.0 --http-bind-port=80 &
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

```

### Comunicación con el cluster
Para lograr comunicarnos con el cluster de manera nativa, copiamos el archivo kubeconfig del node controler al nodo load balancer y ejecutamos los comandos siguientes:
```bash
sudo su -
mkdir -p ~/.kube
cp -a /home/vagrant/admin.kubeconfig ~/.kube/config

chown root:root -R ~/.kube/config 
```

# Implementamos la comunicación BGP con los nodos del cluster
Para implementar la comunicación BGP vamos a utilizar BIRD en el el nodo loadbalancer y establecer las rutas para que el ingress controller pueda llegar a los pods en los workers

```bash
sudo add-apt-repository -y ppa:cz.nic-labs/bird
sudo apt update
sudo apt install bird

# configuramos bird
cat <<EOF | sudo tee /etc/bird/bird.conf 
router id 192.168.5.30;
log syslog all;
# worker-1
protocol bgp worker1 {
    local 192.168.5.30 as 64512;
    neighbor 192.168.5.21 as 64512;
    direct;
    import filter {
        if ( net ~ [ 10.200.0.0/16{16,26} ] ) then accept;
    }; 
    export none;
}
# worker-2
protocol bgp worker2 {
    local 192.168.5.30 as 64512;
    neighbor 192.168.5.22 as 64512;
    direct;
    import filter {
        if ( net ~ [ 10.200.0.0/16{16,26} ] ) then accept;
    };
    export none;
}
protocol kernel {
    scan time 60;
    export all;
}
protocol device {
    scan time 60;
}
EOF

sudo systemct enable --now bird

apt install traceroute

sudo birdc show protocols
sudo birdc show route protocol worker1
sudo birdc show route protocol worker2
sudo route -n
sudo traceroute IP_POD
ping IP_POD

```

# **ejecutar en controller-1**
Para que nuestro ingress controller funcione de manera adecuada, debemos el configmap por default definido en la configuración de la unidad de systemd

Este configmap es utilizado por haproxy para configurar el ingress controller

```bash
kubectl create configmaps haproxy-kubernetes-ingress

```

En este punto nuestro load balancer ya deberia ser capaz de ver los pods y servicios que estan corriendo en el cluster, se podria probar alguno de los ejemplos en la documentación de haproxy para validar la funcionalidad
