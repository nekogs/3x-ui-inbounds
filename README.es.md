# xui-recipes — Instalador independiente de inbounds para el panel 3x-ui / x-ui

Crea un conjunto estándar de "recetas" de Xray a través de su API REST. Se ejecuta en
**cualquier host con Linux** (portátil, VPS, CI): solo necesita acceso a la red al panel,
no estar instalado *en* el servidor 3x-ui.

Las contraseñas nunca se escriben en disco: host, puerto, WebBasePath y token de API solo
viven en variables de shell durante la ejecución. Las claves se generan cada vez (pares de
claves X25519 REALITY, UUID de cliente, contraseñas, tokens de autenticación Hysteria, PSK
SS-2022, KCP seed, contraseñas de ofuscación salamander).

## Instalación y ejecución

Un solo comando (igual que el instalador oficial de 3x-ui):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash
```

O descargar y ejecutar localmente:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

Luego introduzca las credenciales del panel.

## Uso

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash   # crear todo
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # solo las recetas indicadas
XUI_INSECURE=1 ./xui-recipes.sh        # omitir verificación TLS (autofirmado)
```

## Variables de entorno

| Variable       | Descripción                                    | Predeterminado |
|----------------|------------------------------------------------|----------------|
| `XUI_ONLY`     | Lista de nombres de recetas separados por comas| Todas          |
| `XUI_INSECURE` | Omitir verificación de certificado TLS         | 0              |
| `XUI_DEBUG`    | Activar seguimiento de depuración (`set -x`)   | 0              |

## Configuraciones creadas

Todas las claves (claves, UUID, contraseñas, tokens) se generan localmente y no se envían a ningún tercero.

| Recipe                          | Protocolo / transporte                         | Notas                     |
|---------------------------------|------------------------------------------------|---------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                          | Vision flow               |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (disfraz 443)            | puerto de disfraz fijo    |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                        |                           |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                      |                           |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                       | sin flow (mKCP)           |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                           |                           |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                           |                           |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (sin seguridad de transporte)      | sin flow                  |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                      |                           |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS                | cifrado ML-KEM            |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                         |                           |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                             |                           |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS                        |                           |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                              |                           |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                             |                           |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS                      |                           |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                            |                           |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                             |                           |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS                       |                           |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                         |                           |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                          |                           |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS (HTTP/3)                 |                           |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP (chacha20-poly1305)          |                           |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP (blake3)                |                           |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP (basic auth)                        |                           |
| `TUIC-v5-h3`                    | TUIC v5 (HTTP/3)                               |                           |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM                  | cifrado post-cuántico     |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM                 | cifrado post-cuántico     |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM              | cifrado post-cuántico     |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM                    | cifrado post-cuántico     |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM             | cifrado post-cuántico     |

## Licencia

MIT
