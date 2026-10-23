<p dir="auto"><a href="/README.md">English</a> | <a href="/README.fa.md">فارسی</a> | <a href="/README.ar_EG.md">العربية</a> | <a href="/README.zh.md">中文</a> | <a href="/README.es.md">Español</a> | <a href="/README.ru.md">Русский</a> | <a href="/README.tr_TR.md">Türkçe</a></p>

# 3x-ui-inbounds — Xray inbound (proxy) generator for the [3x-ui](https://github.com/MHSanaei/3x-ui) panel

Creates a standard set of Xray "recipe" inbounds on your panel through its REST API.
Runs on **any Linux host** (laptop, VPS, CI) — it only needs network access to the
panel, not to be installed *on* the 3x-ui server.


> [!IMPORTANT]
> Installation requires an API token, which you receive when installing the panel.
> If you did not save the API token, you can generate a new one by running the
> following command on the server with the 3x-ui panel:
> ```bash
> /usr/local/x-ui/x-ui setting -getApiToken -tokenName my-api-cli -tokenScope admin
> ```

## Installation & run

One-liner (same style as the official 3x-ui installer):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash
```

Or download and run locally:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

Then enter the panel credentials when prompted.

## Usage

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash   # create everything
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # only the named recipe(s)
XUI_INSECURE=1 ./xui-recipes.sh        # skip TLS verification (self-signed)
```

## Environment variables

| Variable      | Description                          | Default |
|---------------|--------------------------------------|---------|
| `XUI_ONLY`    | Comma-separated list of recipe names | all     |
| `XUI_INSECURE`| Skip TLS certificate verification    | 0       |
| `XUI_DEBUG`   | Enable debug tracing (`set -x`)      | 0       |

## Created configurations

All secrets (keys, UUIDs, passwords, tokens) are generated locally and never sent
to any third party.

| Recipe                          | Protocol / transport                        | Notes                     |
|---------------------------------|---------------------------------------------|---------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                       | Vision flow               |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (disguised as 443)     | fixed disguise port       |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                     |                           |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                   |                           |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                    | no flow (mKCP)            |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                        |                           |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                        |                           |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (no transport security)         | no flow                   |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                   |                           |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS             | ML-KEM encryption         |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                      |                           |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                          |                           |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS                     |                           |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                           |                           |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                          |                           |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS                   |                           |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                         |                           |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                          |                           |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS                    |                           |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                      |                           |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                       |                           |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS (HTTP/3)              |                           |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP (chacha20-poly1305)       |                           |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP (blake3)             |                           |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP (basic auth)                     |                           |
| `TUIC-v5-h3`                    | TUIC v5 (HTTP/3)                            |                           |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM               | post-quantum encryption   |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM              | post-quantum encryption   |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM           | post-quantum encryption   |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM                 | post-quantum encryption   |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM          | post-quantum encryption   |

## Notes

Credentials are never written to disk: host, port, WebBasePath and API token live
only in shell variables for the duration of the run. Secrets are generated fresh on
every run (REALITY X25519 keypairs, client UUIDs, passwords, Hysteria auth tokens,
SS-2022 PSKs, KCP seed, salamander obfuscation passwords).

This script was written using an AI agent; debugging and testing were done manually.

## Support the author

The script's author is a political prisoner in Russia. If you can spare something for
instant noodles, I'd be grateful!

|           | Address                                                                 |
|-----------|-----------------------------------------------------------------------|
| 💵 USDT (ERC-20) | `0x23c23dc5ed6888d9287da95cba454d4889241202` |
| ₿ BTC      | `bc1q7x2ez0atrtgq0qc5n3phszud0d3geuqvzhhhtu` |

## License

MIT
