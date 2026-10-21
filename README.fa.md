# xui-recipes — راهنمای نصب اسکریپت مستقل برای inbound های پنل 3x-ui / x-ui

## توضیحات

اسکریپت را دانلود، اجرا و اطلاعات ورود پنل را می‌خواند تا مجموعه‌ای استاندارد از
"recipe"های Xray (VLESS / VMess / Trojan / Shadowsocks / Hysteria2 / TUIC / HTTP)
را از طریق REST API پنل بسازد.

رمز عبور هرگز روی دیسک نوشته نمی‌شود: هاست، پورت، WebBasePath و توکن API فقط در
متغیرهای shell طول اجرای اسکریپت باقی می‌مانند. رمزها هر بار تازه تولید می‌شوند
(جفت‌کل X25519 REALITY، UUID کلاینت، رمز عبور، توکن احراز هویت Hysteria، PSK
SS-2022، KCP seed، رمزهای afisalamander).

## پیش‌نیازها

bash، curl، openssl، grep نسخه GNU (-P)، sed. بدون jq و python.

## نصب

1. اسکریپت را به سرور 3x-ui / x-ui خود منتقل کنید:

   ```bash
   scp xui-recipes.sh root@your-server:/root/
   ssh root@your-server 'chmod +x /root/xui-recipes.sh'
   ```

2. آن را اجرا و اطلاعات ورود پنل را وارد کنید:

   ```bash
   ./xui-recipes.sh
   ```

## کاربرد

```bash
./xui-recipes.sh                       # پرسش اطلاعات ورود، ساخت همه چیز
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # فقط recipeهای نام‌برده شده
XUI_INSECURE=1 ./xui-recipes.sh        # رد کردن تأیید TLS (self-signed)
```

## متغیرهای محیطی

| متغیر          | توضیح                                    | پیش‌فرض |
|----------------|-----------------------------------------|---------|
| `XUI_ONLY`     | لیست کاما-جداشده نام recipeها            | همه    |
| `XUI_INSECURE` | رد کردن تأیید گواه‌نامه TLS             | 0       |
| `XUI_DEBUG`    | فعال‌سازی tracing دیباگ (`set -x`)      | 0       |

## مجوز

MIT
