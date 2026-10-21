# xui-recipes

Standalone installer of 3x-ui / x-ui proxy inbounds.

## Description

Downloads, runs, and reads panel credentials to create a standard set of Xray
"recipes" (VLESS / VMess / Trojan / Shadowsocks / Hysteria2 / TUIC / HTTP) on
the panel through its REST API.

Credentials are never written to disk: host, port, WebBasePath and API token
live only in shell variables for the duration of the run. Secrets are generated
fresh on every run (REALITY X25519 keypairs, client UUIDs, passwords, Hysteria
auth tokens, SS-2022 PSKs, KCP seed, salamander obfuscation passwords).

## Dependencies

bash, curl, openssl, GNU grep (-P), sed. No jq, no python.

## Installation

1. Copy the script to your 3x-ui / x-ui server:

   ```bash
   scp xui-recipes.sh root@your-server:/root/
   ssh root@your-server 'chmod +x /root/xui-recipes.sh'
   ```

2. Run it and enter the panel credentials when prompted:

   ```bash
   ./xui-recipes.sh
   ```

## Usage

```bash
./xui-recipes.sh                       # prompt for creds, create everything
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # only the named recipe(s)
XUI_INSECURE=1 ./xui-recipes.sh        # skip TLS verification (self-signed)
```

## Environment variables

| Variable      | Description                          | Default |
|---------------|--------------------------------------|---------|
| `XUI_ONLY`    | Comma-separated list of recipe names | all     |
| `XUI_INSECURE`| Skip TLS certificate verification    | 0       |
| `XUI_DEBUG`   | Enable debug tracing (`set -x`)      | 0       |

## License

MIT
