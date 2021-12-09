# **controller-1**

# Servicio dns
El servicio dns es crucial para el funcionamiento del cluster, si bien los pods cuentan con una ip propia, seria muy complicado que los servicios funcionen de manera adecuada si tuvieran que localizar a cada POD por medio de la IP que se le asigno ya que los pods se crean y se destruyen automaticamente segun sea necesario, Coredns soluciona este problema de una manera optima generando un servicio de resolución de nombres interno para todos los objetos que corren en el cluster como los pods, deployments, servicios, etc.

## Instalando Coredns
```bash
git clone https://github.com/coredns/deployment.git

cd deployment/kubernetes
bash deploy.sh -i 10.32.0.10 > coredns.yaml
kubectl apply -f coredns.yaml
```

## Validamos
```bash
# esto deberia regresar una lista de pods coredns-*
kubectl get pods -n kube-system

# ejecutarmos un deployment usando busybox para revisar la resolucion de nombres
kubectl run busybox --image=busybox --command -- sleep 3600
kubectl get pods -l run=busybox
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

> Salida
```bash
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local

```

Siguiente [Load Balancer](10-configurando-loadbalancer.markdown)
