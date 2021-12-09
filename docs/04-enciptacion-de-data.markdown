# Generando la configuracion para encriptación
Kubernetes guarda una gran variedad de informacion, que incluye el estado del cluster, configuración de las aplicaciones y contraseñas. Kubernetes encripta todo esto en transito para lo cual necesita una llave para encriptar estos datos

## Generamos la llave
```bash

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
 mkdir secure

cat > secure/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

**Siguiente** [Cluster ETCD](05-configurando-cluster-etcd.markdown)
