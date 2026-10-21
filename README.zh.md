# xui-recipes — 3x-ui / x-ui 面板入站脚本独立安装器

## 说明

下载、运行脚本并读取面板凭据，通过 REST API 在面板上创建一套标准的 Xray
"recipe"（VLESS / VMess / Trojan / Shadowsocks / Hysteria2 / TUIC / HTTP）。

密码绝不会写入磁盘：主机名、端口、WebBasePath 和 API token 仅在脚本运行期间
保留在 shell 变量中。密钥每次运行时都会重新生成（REALITY X25519 密钥对、客户端
UUID、密码、Hysteria 认证令牌、SS-2022 PSK、KCP seed、salamander 混淆密码）。

## 依赖

bash、curl、openssl、GNU grep（-P）、sed。无需 jq 和 python。

## 安装

1. 将脚本复制到您的 3x-ui / x-ui 服务器：

   ```bash
   scp xui-recipes.sh root@your-server:/root/
   ssh root@your-server 'chmod +x /root/xui-recipes.sh'
   ```

2. 运行并输入面板凭据：

   ```bash
   ./xui-recipes.sh
   ```

## 用法

```bash
./xui-recipes.sh                       # 提示输入凭据，创建所有内容
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # 仅创建指定 recipe
XUI_INSECURE=1 ./xui-recipes.sh        # 跳过 TLS 验证（自签名）
```

## 环境变量

| 变量            | 说明                              | 默认值 |
|-----------------|-----------------------------------|--------|
| `XUI_ONLY`      | 逗号分隔的 recipe 名称列表         | 全部   |
| `XUI_INSECURE`  | 跳过 TLS 证书验证                 | 0      |
| `XUI_DEBUG`     | 启用调试跟踪（`set -x`）          | 0      |

## 许可证

MIT
