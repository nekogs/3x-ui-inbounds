<p dir="auto"><a href="/README.md">English</a> | <a href="/README.fa.md">فارسی</a> | <a href="/README.ar_EG.md">العربية</a> | <a href="/README.zh.md">中文</a> | <a href="/README.es.md">Español</a> | <a href="/README.ru.md">Русский</a> | <a href="/README.tr_TR.md">Türkçe</a></p>

# xui-recipes — Генератор inbounds (прокси) для <a href="https://github.com/MHSanaei/3x-ui" target="_blank">3x-ui</a> панели

Создаёт стандартный набор Inbounds «рецептов» Xray на вашей панели через её REST API.
Запускается на **любом Linux-хосте** (ноутбук, VPS, CI) — нужен только сетевой
доступ к панели, устанавливать непосредственно на сервере 3x-ui не обязательно.

> [!IMPORTANT]
> Перед установкой включите API-доступ к панели. Токен создаёт штатный скрипт
> установки 3x-ui (x-ui). Подробнее — ниже в разделе «Перед установкой».

## Перед установкой

Вам потребуется включить API-доступ к панели. Для этого используйте токен, который
создаёт 3x-ui (x-ui) скрипт в процессе установки.

**API Token:**

```
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

После откройте:

```
#Access URL#/panel/api-docs
```

Нажмите **Authorize** → вставьте токен в поле `bearerAuth` (`http`, `Bearer`) → нажмите **Authorize**.

> [!WARNING]
> После подключения доступа по API панель может не открываться в том же окне
> браузера. Для решения проблемы сбросьте кеш либо откройте вкладку в режиме
> инкогнито.

## Установка и запуск

Одной строкой (как у официального установщика 3x-ui):

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash
```

Или скачать и запустить локально:

```bash
curl -Ls -o xui-recipes.sh https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh
chmod +x xui-recipes.sh
./xui-recipes.sh
```

Затем введите учётные данные панели.

## Использование

```bash
curl -Ls https://raw.githubusercontent.com/nekogs/xui-recipes/main/xui-recipes.sh | bash   # создать всё
XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # только указанные рецепты
XUI_INSECURE=1 ./xui-recipes.sh        # пропустить проверку TLS (self-signed)
```

## Переменные окружения

| Переменная     | Описание                                    | По умолчанию |
|----------------|---------------------------------------------|---------------|
| `XUI_ONLY`     | Список названий рецептов через запятую      | все           |
| `XUI_INSECURE` | Пропустить проверку TLS-сертификата         | 0             |
| `XUI_DEBUG`    | Включить отладочный трейсинг (`set -x`)     | 0             |

## Создаемые конфигурации

Все секреты (ключи, UUID, пароли, токены) генерируются локально и никуда не отправляются.

| Recipe                          | Протокол / транспорт                        | Примечание                  |
|---------------------------------|---------------------------------------------|-----------------------------|
| `VLESS-TCP-REALITY-01`          | VLESS + TCP + REALITY                       | Vision flow                 |
| `VLESS-TCP-REALITY-443-01`      | VLESS + TCP + REALITY (маскировка 443)       | фиксированный порт маскировки |
| `VLESS-WSS-TLS-01`              | VLESS + WebSocket + TLS                     |                             |
| `VLESS-HUPG-TLS-01`             | VLESS + HTTPUpgrade + TLS                   |                             |
| `VLESS-XHTTP2-REALITY-01`       | VLESS + XHTTP2 + REALITY                    | без flow (mKCP)             |
| `VLESS-XHTTP2-TLS-01`           | VLESS + XHTTP2 + TLS                        |                             |
| `VLESS-XHTTP3-TLS-01`           | VLESS + XHTTP3 + TLS                        |                             |
| `VLESS-KCP-NONE-01`             | VLESS + mKCP (без защиты транспорта)         | без flow                    |
| `VLESS-TCP-XTLS-Vision-01`      | VLESS + TCP + XTLS Vision                   |                             |
| `VLESS-TCP-XTLS-Vision-TLS-01`  | VLESS + TCP + XTLS Vision + TLS             | шифрование ML-KEM           |
| `VLESS-gRPC-Reality-01`         | VLESS + gRPC + REALITY                      |                             |
| `VLESS-gRPC-TLS-01`             | VLESS + gRPC + TLS                          |                             |
| `VMESS-WSS-TLS-01`              | VMess + WebSocket + TLS                     |                             |
| `VMESS-TCP-TLS-01`              | VMess + TCP + TLS                           |                             |
| `VMESS-gRPC-TLS-01`             | VMess + gRPC + TLS                          |                             |
| `VMESS-HTTPU-TLS-01`            | VMess + HTTPUpgrade + TLS                   |                             |
| `VMESS-XHTTP-TLS-01`            | VMess + XHTTP + TLS                         |                             |
| `TROJAN-TCP-TLS-01`             | Trojan + TCP + TLS                          |                             |
| `TROJAN-WSS-TLS-01`             | Trojan + WebSocket + TLS                    |                             |
| `TROJAN-TCP-REALITY-01`         | Trojan + TCP + REALITY                      |                             |
| `HYSTERIA-UDP-TLS-01`           | Hysteria2 + UDP + TLS                       |                             |
| `HY2-UDP-TLS-h3`                | Hysteria2 + UDP + TLS (HTTP/3)              |                             |
| `SS-TCP-CHACHA-01`              | Shadowsocks + TCP (chacha20-poly1305)       |                             |
| `SS2022-TCP-BLAKE-01`           | Shadowsocks 2022 + TCP (blake3)             |                             |
| `HTTP-TCP-BASIC-01`             | HTTP + TCP (basic auth)                     |                             |
| `TUIC-v5-h3`                    | TUIC v5 (HTTP/3)                            |                             |
| `VLESS-XHTTP2-MLKEM-TLS-01`     | VLESS + XHTTP2 + TLS + ML-KEM               | постквантовое шифрование    |
| `VLESS-TCP-MLKEM-REALITY-01`    | VLESS + TCP + REALITY + ML-KEM              | постквантовое шифрование    |
| `VLESS-XHTTP2-MLKEM-REALITY-01` | VLESS + XHTTP2 + REALITY + ML-KEM           | постквантовое шифрование    |
| `VLESS-gRPC-MLKEM-TLS-01`       | VLESS + gRPC + TLS + ML-KEM                 | постквантовое шифрование    |
| `VLESS-HUPG-MLKEM-TLS-01`       | VLESS + HTTPUpgrade + TLS + ML-KEM          | постквантовое шифрование    |

## Примечания

Учётные данные никогда не пишутся на диск: host, порт, WebBasePath и API-токен
хранятся только в переменных shell во время работы скрипта. Секреты генерируются
заново каждый раз (ключи X25519 REALITY, UUID клиентов, пароли, токены аутентификации
Hysteria, PSK SS-2022, KCP seed, пароли obfuscation salamander).

Данный скрипт написан с использованием AI-агента, отладка и тестирование проведены вручную.

## Поддержать автора

Автор скрипта — политический заключённый в РФ. Если у вас есть возможность подкинуть
на дошик — буду благодарен!

|           | Адрес                                                                 |
|-----------|-----------------------------------------------------------------------|
| 💵 USDT (ERC-20) | `0x23c23dc5ed6888d9287da95cba454d4889241202` |
| ₿ BTC      | `bc1q7x2ez0atrtgq0qc5n3phszud0d3geuqvzhhhtu` |

## Лицензия

MIT
