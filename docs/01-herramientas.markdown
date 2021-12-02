# Herramientas

```bash
curl -L -o cfssljson https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssljson_1.6.1_linux_amd64
curl -L -o cfssl https://github.com/cloudflare/cfssl/releases/download/v1.6.1/cfssl_1.6.1_linux_amd64
chmod u+x cfssl cfssljson
sudo mv cfssl cfssljson /usr/local/bin
```

# Pre configuraciones
```bash
sudo modprobe br_netfilter

echo "
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/k8s.conf

sysctl --system
```
