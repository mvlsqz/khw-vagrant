# Generando la configuracion para encriptación
Kubernetes guarda una gran variedad de informacion, que incluye el estado del cluster,
configuración de las aplicaciones y contraseñas. Kubernetes encripta todo esto en transito

## Generamos la llave
```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```
` mkdir secure`

## Generamos el archivo de configuración
```bash
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
