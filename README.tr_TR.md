<p dir="auto"><a href="/README.md">English</a> | <a href="/README.fa.md">فارسی</a> | <a href="/README.ar_EG.md">العربية</a> | <a href="/README.zh.md">中文</a> | <a href="/README.es.md">Español</a> | <a href="/README.ru.md">Русский</a> | <a href="/README.tr_TR.md">Türkçe</a></p>

# 3x-ui-inbounds — [3x-ui](https://github.com/MHSanaei/3x-ui) paneli için Xray inbound (proxy) oluşturucu

Panelinizde REST API'si üzerinden standart bir Xray "tarif" inbound seti oluşturur.
**Herhangi bir Linux ana makinesinde** (dizüstü, VPS, CI) çalışır — panele ağ erişimi
yeterlidir, 3x-ui sunucusunun *üzerine* kurulması gerekmez.


> [!IMPORTANT]
> Kurulum için API token gerekir; bu token'ı paneli kurarken alırsınız.
> API token'ı kaydetmediyseniz, 3x-ui panelinin çalıştığı sunucuda aşağıdaki komutu
> çalıştırarak yeni bir token oluşturabilirsiniz:
> ```bash
> /usr/local/x-ui/x-ui setting -getApiToken -tokenName my-api-cli -tokenScope admin
> ```

## Kurulum ve çalıştırma

Tek satır (resmî 3x-ui yükleyicisiyle aynı biçimde):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash
```

Ya da indirip yerel olarak çalıştırın:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

Ardından panel giriş bilgilerini girin.

## Kullanım

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/3x-ui-inbounds/main/xui-recipes.sh | bash   # her şeyi oluştur
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # yalnızca belirtilen tarifler
XUI_INSECURE=1 ./xui-recipes.sh        # TLS doğrulamasını atla (self-signed)
```

## Ortam değişkenleri

| Değişken       | Açıklama                                        | Varsayılan |
|----------------|-------------------------------------------------|------------|
| `XUI_ONLY`     | Virgülle ayrılmış tarif adları listesi          | tümü       |
| `XUI_INSECURE` | TLS sertifikası doğrulamasını atla              | 0          |
| `XUI_DEBUG`    | Hata ayıklama izlemeyi etkinleştir (`set -x`)    | 0          |

## Oluşturulan yapılandırmalar

Tüm sırlar (anahtarlar, UUID'ler, parolalar, token'lar) yerel olarak üretilir ve hiçbir
üçüncü tarafa gönderilmez.

| Tarif                           | Protokol / taşıma                             | Not                        |
|---------------------------------|-----------------------------------------------|----------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                         | Vision flow               |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (443 kılığına girer)     | sabit kılık değiştirme portu|
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                       |                           |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                     |                           |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                      | flow yok (mKCP)           |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                          |                           |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                          |                           |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (taşıma güvenliği yok)           | flow yok                  |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                     |                           |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS               | ML-KEM şifreleme           |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                        |                           |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                            |                           |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS                       |                           |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                             |                           |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                            |                           |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS                     |                           |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                           |                           |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                            |                           |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS                      |                           |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                        |                           |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                         |                           |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS (HTTP/3)                |                           |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP (chacha20-poly1305)         |                           |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP (blake3)               |                           |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP (basic auth)                       |                           |
| `TUIC-v5-h3`                    | TUIC v5 (HTTP/3)                              |                           |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM                 | kuantum-sonrası şifreleme  |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM                | kuantum-sonrası şifreleme  |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM             | kuantum-sonrası şifreleme  |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM                   | kuantum-sonrası şifreleme  |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM            | kuantum-sonrası şifreleme  |

## Notlar

Giriş bilgileri asla diske yazılmaz: host, port, WebBasePath ve API token yalnızca
çalışma süresince shell değişkenlerinde tutulur. Sırlar her çalıştırmada yeniden
üretilir (REALITY X25519 anahtar çiftleri, istemci UUID'leri, parolalar, Hysteria
kimlik doğrulama token'ları, SS-2022 PSK'ları, KCP seed, salamander gizleme parolaları).

Bu betik bir yapay zekâ ajanı yardımıyla yazılmıştır; hata ayıklama ve testler elle yapılmıştır.

## Yazara destek

Betiklerin yazarı Rusya'da siyasi bir mahkûmdur. Hazır erişteneye katkıda
bulunabilecekseniz minnettar olurum!

|           | Adres                                                                |
|-----------|----------------------------------------------------------------------|
| 💵 USDT (ERC-20) | `0x23c23dc5ed6888d9287da95cba454d4889241202` |
| ₿ BTC      | `bc1q7x2ez0atrtgq0qc5n3phszud0d3geuqvzhhhtu` |

## Lisans

MIT
