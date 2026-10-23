<p dir="auto"><a href="/README.md">English</a> | <a href="/README.fa.md">فارسی</a> | <a href="/README.ar_EG.md">العربية</a> | <a href="/README.zh.md">中文</a> | <a href="/README.es.md">Español</a> | <a href="/README.ru.md">Русский</a> | <a href="/README.tr_TR.md">Türkçe</a></p>

# 3x-ui-inbounds — مولّد inbounds (بروكسي) Xray للوحة [3x-ui](https://github.com/MHSanaei/3x-ui)

ينشئ مجموعة قياسية من "وصفات" Xray على لوحتك من خلال واجهة REST API الخاصة بها.
يعمل على **أي جهاز لينكس** (حاسوب محمول، VPS، CI) — يحتاج فقط إلى وصول شبكي إلى
اللوحة، ولا يلزم تثبيته *على* خادم 3x-ui نفسه.

## التثبيت والتشغيل

بسطر واحد (بنفس أسلوب مثبّت 3x-ui الرسمي):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash
```

أو حمّل السكربت وشغّله محليًا:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

ثم أدخل بيانات اعتماد اللوحة.

## الاستخدام

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash   # إنشاء كل شيء
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # الوصفات المحددة فقط
XUI_INSECURE=1 ./xui-recipes.sh        # تخطي التحقق من TLS (شهادة موقعة ذاتيًا)
```

## متغيرات البيئة

| المتغير        | الوصف                                       | الافتراضي |
|----------------|---------------------------------------------|-----------|
| `XUI_ONLY`     | قائمة أسماء الوصفات مفصولة بفواصل           | الكل      |
| `XUI_INSECURE` | تخطي التحقق من شهادة TLS                    | 0         |
| `XUI_DEBUG`    | تفعيل تتبع التصحيح (`set -x`)               | 0         |

## التكوينات المنشأة

تُنشأ جميع الأسرار (المفاتيح، UUID، كلمات المرور، الرموز) محليًا ولا تُرسل إلى أي جهة خارجية.

| الوصفة                          | البروتوكول / النقل                          | ملاحظة                     |
|---------------------------------|---------------------------------------------|----------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                       | Vision flow               |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (تنكر 443)             | منفذ تنكر ثابت            |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                     |                           |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                   |                           |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                    | بدون flow (mKCP)          |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                        |                           |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                        |                           |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (بدون أمان النقل)              | بدون flow                 |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                   |                           |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS             | تشفير ML-KEM              |
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
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM               | تشفير ما بعد الكم          |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM              | تشفير ما بعد الكم          |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM           | تشفير ما بعد الكم          |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM                 | تشفير ما بعد الكم          |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM          | تشفير ما بعد الكم          |

## ملاحظات

لا تُكتب بيانات الاعتماد على القرص أبدًا: المضيف والمنفذ وWebBasePath ورمز API
تبقى فقط في متغيرات الصدفة طوال مدة التشغيل. تُنشأ الأسرار من جديد في كل مرة
(أزواج مفاتيح REALITY X25519، UUID للعملاء، كلمات المرور، رموز مصادقة Hysteria،
PSK لـ SS-2022، KCP seed، كلمات مرور التشويش salamander).

كُتب هذا السكربت بمساعدة وكيل ذكاء اصطناعي؛ تمت تصحيح الأخطاء والاختبار يدويًا.

## دعم المؤلف

مؤلف هذا السكربت سجين رأي في روسيا. إذا كانت لديك إمكانية المساهمة بثمن بعض
النودلز سريعة التحضير، فسأكون ممتنًا!

|           | العنوان                                                              |
|-----------|----------------------------------------------------------------------|
| 💵 USDT (ERC-20) | `0x23c23dc5ed6888d9287da95cba454d4889241202` |
| ₿ BTC      | `bc1q7x2ez0atrtgq0qc5n3phszud0d3geuqvzhhhtu` |

## الترخيص

MIT
