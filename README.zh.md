<p dir="auto"><a href="/README.md">English</a> | <a href="/README.fa.md">فارسی</a> | <a href="/README.ar_EG.md">العربية</a> | <a href="/README.zh.md">中文</a> | <a href="/README.es.md">Español</a> | <a href="/README.ru.md">Русский</a> | <a href="/README.tr_TR.md">Türkçe</a></p>

# 3x-ui-inbounds — [3x-ui](https://github.com/MHSanaei/3x-ui) 面板的 Xray 入站（代理）生成器

通过 REST API 在您的面板上创建一套标准的 Xray "recipe"。可在**任意 Linux 主机**
（笔记本、VPS、CI）上运行——只需要能网络访问面板，无需安装在 3x-ui 服务器上。


> [!IMPORTANT]
> 安装需要 API Token，安装面板时会获得该令牌。
> 如果您没有保存 API Token，可以在运行 3x-ui 面板的服务器上执行以下命令生成新令牌：
> ```bash
> /usr/local/x-ui/x-ui setting -getApiToken -tokenName my-api-cli -tokenScope admin
> ```

## 安装与运行

一行命令（与官方 3x-ui 安装器相同风格）：

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash
```

或下载后本地运行：

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

然后输入面板凭据。

## 用法

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash   # 创建所有内容
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # 仅创建指定 recipe
XUI_INSECURE=1 ./xui-recipes.sh        # 跳过 TLS 验证（自签名）
```

## 环境变量

| 变量            | 说明                              | 默认值 |
|-----------------|-----------------------------------|--------|
| `XUI_ONLY`      | 逗号分隔的 recipe 名称列表         | 全部   |
| `XUI_INSECURE`  | 跳过 TLS 证书验证                 | 0      |
| `XUI_DEBUG`     | 启用调试跟踪（`set -x`）          | 0      |

## 创建的配置

所有密钥（密钥、UUID、密码、令牌）本地生成，不会发送到任何第三方。

| Recipe                          | 协议 / 传输                           | 说明                     |
|---------------------------------|---------------------------------------|--------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                 | Vision flow              |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY（伪装 443）      | 固定伪装端口             |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS               |                          |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS             |                          |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY              | 无 flow（mKCP）          |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                  |                          |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                  |                          |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP（无传输安全）            | 无 flow                  |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision             |                          |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS       | ML-KEM 加密              |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                |                          |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                    |                          |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS               |                          |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                     |                          |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                    |                          |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS             |                          |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                   |                          |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                    |                          |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS              |                          |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                |                          |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                 |                          |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS（HTTP/3）       |                          |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP（chacha20-poly1305）|                          |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP（blake3）      |                          |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP（basic auth）              |                          |
| `TUIC-v5-h3`                    | TUIC v5（HTTP/3）                     |                          |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM         | 后量子加密               |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM        | 后量子加密               |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM     | 后量子加密               |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM           | 后量子加密               |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM    | 后量子加密               |

## 说明

密码绝不会写入磁盘：主机名、端口、WebBasePath 和 API token 仅在脚本运行期间保留在
shell 变量中。密钥每次运行时都会重新生成（REALITY X25519 密钥对、客户端 UUID、密码、
Hysteria 认证令牌、SS-2022 PSK、KCP seed、salamander 混淆密码）。

本脚本使用 AI 智能体编写，调试和测试均为手动完成。

## 支持作者

脚本作者是俄罗斯的一名政治犯。如果您能赞助一些方便面，我将不胜感激！

|           | 地址                                                                 |
|-----------|-----------------------------------------------------------------------|
| 💵 USDT (ERC-20) | `0x23c23dc5ed6888d9287da95cba454d4889241202` |
| ₿ BTC      | `bc1q7x2ez0atrtgq0qc5n3phszud0d3geuqvzhhhtu` |

## 许可证

MIT
