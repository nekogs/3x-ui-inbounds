# xui-recipes — راهنمای نصب اسکریپت مستقل برای inbound های پنل 3x-ui / x-ui

مجموعه‌ای استاندارد از "recipe"های Xray را از طریق REST API پنل می‌سازد.
روی **هر هاست لینوکسی** (لپ‌تاپ، VPS، CI) اجرا می‌شود — فقط به دسترسی شبکه به
پنل نیاز دارد، نه نصب *روی* سرور 3x-ui.

رمز عبور هرگز روی دیسک نوشته نمی‌شود: هاست، پورت، WebBasePath و توکن API فقط در
متغیرهای shell طول اجرای اسکریپت باقی می‌مانند. رمزها هر بار تازه تولید می‌شوند
(جفت‌کل X25519 REALITY، UUID کلاینت، رمز عبور، توکن احراز هویت Hysteria، PSK
SS-2022، KCP seed، رمزهای afisalamander).

## نصب و اجرا

تک‌خطی (مثل نصب‌کننده رسمی 3x-ui):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash
```

یا دانلود و اجرای محلی:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

سپد اطلاعات ورود پنل را وارد کنید.

## کاربرد

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash   # ساخت همه‌چیز
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # فقط recipeهای نام‌برده شده
XUI_INSECURE=1 ./xui-recipes.sh        # رد کردن تأیید TLS (self-signed)
```

## متغیرهای محیطی

| متغیر          | توضیح                                    | پیش‌فرض |
|----------------|-----------------------------------------|---------|
| `XUI_ONLY`     | لیست کاما-جداشده نام recipeها            | همه    |
| `XUI_INSECURE` | رد کردن تأیید گواه‌نامه TLS             | 0       |
| `XUI_DEBUG`    | فعال‌سازی tracing دیباگ (`set -x`)      | 0       |

## پیکربندی‌های ساخته‌شده

همه رمزها (کل، UUID، رمز عبور، توکن) محلی تولید می‌شوند و به جایی ارسال نمی‌شوند.

| recipe                          | پروتکل / ترانسپورت                        | توضیح                     |
|---------------------------------|------------------------------------------|---------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                    | Vision flow               |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (ماسک 443)         | پورت ماسک ثابت            |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                  |                           |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                |                           |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                 | بدون flow (mKCP)          |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                     |                           |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                     |                           |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (بدون امنیت ترانسپورت)     | بدون flow                 |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                |                           |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS          | رمزگذاری ML-KEM           |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                   |                           |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                       |                           |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS                  |                           |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                        |                           |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                       |                           |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS                |                           |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                      |                           |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                       |                           |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS                 |                           |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                   |                           |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                    |                           |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS (HTTP/3)           |                           |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP (chacha20-poly1305)    |                           |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP (blake3)          |                           |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP (basic auth)                  |                           |
| `TUIC-v5-h3`                    | TUIC v5 (HTTP/3)                         |                           |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM            | رمزگذاری پست‌کوانتومی     |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM           | رمزگذاری پست‌کوانتومی     |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM        | رمزگذاری پست‌کوانتومی     |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM              | رمزگذاری پست‌کوانتومی     |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM       | رمزگذاری پست‌کوانتومی     |

## مجوز

MIT
