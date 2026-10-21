# xui-recipes — Instalador independiente de inbounds para el panel 3x-ui / x-ui

## Descripción

Descarga, ejecuta y lee las credenciales del panel para crear un conjunto estándar
de "recetas" de Xray (VLESS / VMess / Trojan / Shadowsocks / Hysteria2 / TUIC / HTTP)
a través de su API REST.

Las contraseñas nunca se escriben en disco: host, puerto, WebBasePath y token de API
solo viven en variables de shell durante la duración de la ejecución. Las claves se
generan cada vez (pares de claves X25519 REALITY, UUID de cliente, contraseñas, tokens
de autenticación Hysteria, PSK SS-2022, KCP seed, contraseñas de ofuscación salamander).

## Dependencias

bash, curl, openssl, grep GNU (-P), sed. Sin jq ni python.

## Instalación

1. Copia el script a tu servidor 3x-ui / x-ui:

   ```bash
   scp xui-recipes.sh root@your-server:/root/
   ssh root@your-server 'chmod +x /root/xui-recipes.sh'
   ```

2. Ejecútalo e introduce las credenciales del panel:

   ```bash
   ./xui-recipes.sh
   ```

## Uso

```bash
./xui-recipes.sh                       # pedir credenciales, crear todo
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # solo las recetas indicadas
XUI_INSECURE=1 ./xui-recipes.sh        # omitir verificación TLS (autofirmado)
```

## Variables de entorno

| Variable       | Descripción                              | Predeterminado |
|----------------|------------------------------------------|----------------|
| `XUI_ONLY`     | Lista de nombres de recetas separados por comas | Todas      |
| `XUI_INSECURE` | Omitir verificación de certificado TLS   | 0              |
| `XUI_DEBUG`    | Activar seguimiento de depuración (`set -x`) | 0           |

## Licencia

MIT
