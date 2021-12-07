```bash
cat <<EOF | tee global-bgp-peer.yaml
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: loadbalancer-bgp-peer
spec:
  peerIP: 192.168.5.30
  asNumber: 64512
EOF
```
