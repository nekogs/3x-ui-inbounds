#!/usr/bin/env bash
# =============================================================================
# xui-recipes.sh — standalone installer of 3x-ui / x-ui proxy inbounds
# =============================================================================
# Download, run, type the panel credentials -> the script creates a standard
# set of Xray "recipes" (VLESS / VMess / Trojan / Shadowsocks / Hysteria2 /
# TUIC / HTTP) on that panel through its REST API.
#
# Credentials are never written to disk: host, port, WebBasePath and API token
# live only in shell variables for the duration of the run.
#
# Secrets are generated fresh on every run:
#   * REALITY X25519 keypairs  (one unique keypair per REALITY inbound)
#   * client UUIDs / passwords / Hysteria auth tokens / SS-2022 PSKs
#   * KCP seed, salamander obfuscation passwords
#
# Dependencies: bash, curl, openssl, GNU grep (-P). No jq, no python.
#
# Usage:
#   ./xui-recipes.sh                       # prompt for creds, create everything
#   XUI_ONLY="VLESS-TCP-REALITY-01" ./xui-recipes.sh   # only the named recipe(s)
#   XUI_INSECURE=1 ./xui-recipes.sh        # skip TLS verification (self-signed)
# =============================================================================

set -u
[ "${XUI_DEBUG:-0}" = "1" ] && set -x

PROG="xui-recipes"

# ---- connection state (never persisted) -------------------------------------
BASE=""
TOKEN=""

# ---- certificate paths (filled from the panel API) --------------------------
CERT_FILE="/root/cert/ip/fullchain.pem"
CERT_KEY="/root/cert/ip/privkey.pem"

# Prompt helper. When the script is piped (curl ... | bash) stdin is the script
# itself, so interactive read would get EOF from the pipe. Read user answers
# from the controlling terminal instead; fall back to stdin when there is none.
ask() {  # ask [-s] "prompt" var
  local silent=0 prompt="" var
  [ "$1" = "-s" ] && { silent=1; shift; }
  prompt="$1"; var="$2"
  if : 2>/dev/null < /dev/tty; then            # real terminal exists
    if [ "$silent" = 1 ]; then
      IFS= read -rs "$var" < /dev/tty
    else
      IFS= read -rp "$prompt" "$var" < /dev/tty
    fi
  else                                          # no tty: fall back to stdin
    if [ "$silent" = 1 ]; then
      IFS= read -rs "$var"
    else
      IFS= read -rp "$prompt" "$var"
    fi
  fi
}

log()  { printf '%s\n' "$*"; }
ok()   { printf '[ok] %s\n' "$*"; }
warn() { printf '[!]  %s\n' "$*" >&2; }
die()  { warn "$*"; exit 1; }

# -----------------------------------------------------------------------------
# dependencies
# -----------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

check_deps() {
  local miss=0 d
  for d in bash curl openssl grep sed; do
    have "$d" || { warn "missing required command: $d"; miss=1; }
  done
  [ "$miss" -eq 0 ] || die "dependencies not satisfied"
}

# -----------------------------------------------------------------------------
# random generators (openssl only)
# -----------------------------------------------------------------------------
rand_hex() { openssl rand -hex "$1" | tr -d '\r\n'; }

rand_uuid() {
  rand_hex 16 | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/'
}

# url-safe base64, no padding (matches Python's urlsafe_b64encode().rstrip("="))
rand_b64url() {
  openssl rand -base64 "$1" | tr '+/' '-_' | tr -d '\r\n='
}

# standard base64 WITH padding (needed for SS-2022 PSK)
rand_b64() {
  openssl rand -base64 "$1" | tr -d '\r\n'
}

# echo "priv_b64url pub_b64url" — raw 32-byte X25519, base64url WITHOUT padding.
# This is exactly the format `xray x25519` prints and what Xray 26.x accepts
# for realitySettings.privateKey / settings.publicKey (43 chars, no '=').
gen_reality_keys() {
  local pem priv pub
  pem=$(openssl genpkey -algorithm X25519 2>/dev/null) || die "openssl: X25519 unsupported"
  priv=$(printf '%s\n' "$pem" | openssl pkey -outform DER 2>/dev/null | tail -c 32 \
           | base64 | tr '+/' '-_' | tr -d '\r\n=')
  pub=$( printf '%s\n' "$pem" | openssl pkey -pubout -outform DER 2>/dev/null | tail -c 32 \
           | base64 | tr '+/' '-_' | tr -d '\r\n=')
  [ -n "$priv" ] && [ -n "$pub" ] || die "could not derive X25519 keypair"
  printf '%s %s' "$priv" "$pub"
}

# -----------------------------------------------------------------------------
# HTTP
# -----------------------------------------------------------------------------
CURL_TLS=""
[ "${XUI_INSECURE:-0}" = "1" ] && CURL_TLS="-k"

# api METHOD PATH [JSON] -> prints response body, warns on non-200
api() {
  local method="$1" path="$2" data="${3:-}" raw code body attempt
  for attempt in 1 2 3; do
    if [ -n "$data" ]; then
      raw=$(curl -sS $CURL_TLS -m 45 -w $'\n%{http_code}' -X "$method" \
        -H "Authorization: Bearer $TOKEN" \
        -H 'Content-Type: application/json' \
        --data-binary "$data" "$BASE$path" 2>/dev/null)
    else
      raw=$(curl -sS $CURL_TLS -m 45 -w $'\n%{http_code}' -X "$method" \
        -H "Authorization: Bearer $TOKEN" "$BASE$path" 2>/dev/null)
    fi
    code=${raw##*$'\n'}
    body=${raw%$'\n'*}
    # retry on empty body or non-2xx (typical for flaky TLS / schannel drops)
    case "$code" in
      2??) [ -n "$body" ] && break ;;
      *)   [ "$attempt" -lt 3 ] && sleep 2 ;;
    esac
  done
  [ "$code" = "200" ] || warn "HTTP ${code:-none} on $method $path"
  printf '%s' "$body"
}

# -----------------------------------------------------------------------------
# panel health gate (per-recipe xray crash detection)
# -----------------------------------------------------------------------------
# panel_xray_state -> prints current xray state ("running"/"stop"/"error").
# returns 0 when /server/status is reachable, 2 otherwise. A non-"running" value
# means an inbound we just added crashed/restarted xray into a bad config.
panel_xray_state() {
  local body state
  body=$(api GET "/panel/api/server/status")
  case "$body" in
    *'"success":true'*|*'"success": true'*) : ;;
    *) return 2 ;;
  esac
  state=$(json_str "$body" state)   # the only "state" field in this response is xray.state
  printf '%s' "$state"
}

# disable_inbound <id> -> POST setEnable {"enable":false}; best effort, no output.
disable_inbound() { api POST "/panel/api/inbounds/setEnable/$1" '{"enable":false}' >/dev/null; }

# wait_xray_running [max_attempts] [sleep_secs] -> 0 if xray returns to running, else 1.
# setEnable triggers an xray restart; poll until it recovers so the next recipe
# starts from a clean slate instead of being falsely reported as broken.
wait_xray_running() {
  local max="${1:-10}" sleep_s="${2:-2}" i state rc
  for ((i=0; i<max; i++)); do
    state=$(panel_xray_state); rc=$?
    [ "$rc" -eq 0 ] && [ "$state" = "running" ] && return 0
    sleep "$sleep_s"
  done
  return 1
}

# set_client_flow <flow> -> POST bulkAdjust {emails:[...], flow:<flow>} for every
# existing client. Panel applies vision only to inbounds that support it (TCP/
# REALITY); XHTTP/gRPC/KCP get flowIneligible and are left without flow, so a
# single shared VLESS client attached to mixed transports does not break the
# non-TCP ones (see 3x-ui issue #4578). Reports per-client status from the API's
# skipped[] list: an email present there with reason "flow not supported on inbound"
# means flow was NOT applied; any other outcome counts as applied.
set_client_flow() {
  local flow="$1" n_c c emails_json resp adj skipped reason i
  n_c=${#C_EMAIL[@]}
  [ "$n_c" -gt 0 ] || return 0

  # build JSON array of all client emails
  local sep=""
  emails_json="["
  for ((c=0; c<n_c; c++)); do
    emails_json="${emails_json}${sep}\"${C_EMAIL[$c]}\""; sep=","
  done
  emails_json="${emails_json}]"

  resp=$(api POST "/panel/api/clients/bulkAdjust" "{\"emails\":$emails_json,\"flow\":\"$flow\"}")
  adj=$(json_num "$resp" adjusted)
  ok "bulk flow '$flow' for ${n_c} client(s): adjusted=${adj:-0}"

  # parse skipped[] -> build a lookup of emails that were NOT given the flow
  declare -A not_applied=()
  local obj i reason
  while IFS= read -r obj; do
    [ -n "$obj" ] || continue
    i=$(printf '%s' "$obj" | grep -o '"email":"[^"]*"' | head -1 | sed 's/"email":"//; s/"$//')
    reason=$(printf '%s' "$obj" | grep -o '"reason":"[^"]*"' | head -1 | sed 's/"reason":"//; s/"$//')
    if [ -n "$i" ] && printf '%s' "$reason" | grep -qi "flow not supported"; then
      not_applied["$i"]=1
    fi
  done < <(printf '%s' "$resp" | grep -o '{[^{}]*}')

  # per-client status
  for ((c=0; c<n_c; c++)); do
    local email="${C_EMAIL[$c]}"
    if [ -n "${not_applied[$email]:-}" ]; then
      warn "flow '$flow' NOT applied to $email (no supporting inbound)"
    else
      ok "flow '$flow' set for $email"
    fi
  done
}

# -----------------------------------------------------------------------------
C_EMAIL=(); C_SUBID=(); C_UUID=(); C_PASS=(); C_AUTH=()

# extract first occurrence of a JSON string field from a chunk (POSIX tools only)
json_str() { # $1=chunk $2=field  (always succeeds, prints '' when absent)
  printf '%s' "$1" | tr ',' '\n' \
    | grep -m1 "\"$2\"" \
    | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true
}

# numeric field
json_num() { # $1=chunk $2=field  (always succeeds, prints '' when absent)
  printf '%s' "$1" | tr ',' '\n' \
    | grep -m1 "\"$2\"" \
    | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/' || true
}

# modern (3x-ui v3) panels
MODERN=0
VLESS_ENC=0     # VLESS: enable ML-KEM post-quantum encryption (decryption/encryption)
VLESS_NO_FLOW=0 # VLESS: disable XTLS flow (only mKCP)
VLESS_TCP=0     # VLESS: transport is raw TCP (Vision flow is valid)
SEED_ID=""      # temporary inbound used to anchor the first client on v3
SEED_PORT=19998

# v3 requires a client to be attached to >=1 inbound. Create a throwaway empty
# VLESS inbound as the anchor, then create the client on it with locally-generated
# credentials (uuid for VLESS/VMess, password for Trojan/SS/TUIC, auth for
# Hysteria). Inbounds are created empty and the client is attached to them later.
ensure_client_v3() { # $1=email
  local email="$1" uuid pass auth seed_payload seed_resp resp
  uuid=$(rand_uuid); pass=$(rand_b64url 16); auth="a$(rand_b64url 12)"
  seed_payload=$(printf '{"enable":true,"remark":"zz-seed","listen":"","port":%s,"protocol":"vless","expiryTime":0,"total":0,"up":0,"down":0,"settings":{"clients":[],"decryption":"none"},"streamSettings":{"network":"tcp","tcpSettings":{"acceptProxyProtocol":false,"header":{"type":"none"}}},"sniffing":{"enabled":false},"tag":"zz-seed"}' "$SEED_PORT")
  seed_resp=$(api POST "/panel/api/inbounds/add" "$seed_payload")
  SEED_ID=$(json_num "$seed_resp" id)
  [ -n "$SEED_ID" ] || { warn "could not create a seed inbound"; return 1; }

  resp=$(api POST "/panel/api/clients/add" \
    "{\"client\":{\"email\":\"$email\",\"id\":\"$uuid\",\"password\":\"$pass\",\"auth\":\"$auth\",\"enable\":true},\"inboundIds\":[$SEED_ID]}")
  case "$resp" in
    *'"success":true'*|*'"success": true'*)
      C_EMAIL=("$email"); C_SUBID=(""); C_UUID=("$uuid"); C_PASS=("$pass"); C_AUTH=("$auth")
      return 0 ;;
    *) return 1 ;;
  esac
}

# extract the VLESS/VMess uuid from a client chunk: prefer `uuid`, fall back to `id`
client_uuid() { # $1=chunk
  local u
  u=$(json_str "$1" uuid)
  [ -n "$u" ] || u=$(json_str "$1" id)
  printf '%s' "$u"
}

fetch_clients() {
  local body chunk e u
  body=$(api GET "/panel/api/clients/list")

  case "$body" in
    *'"success":true'*|*'"success": true'*) : ;;
    *) warn "cannot list clients — falling back to one generated client"; body="";;
  esac

  if [ -n "$body" ]; then
    while IFS= read -r chunk; do
      [ -n "$chunk" ] || continue
      e=$(json_str "$chunk" email)
      [ -n "$e" ] || continue
      # v3 standalone clients carry a top-level `uuid`; v2 embeds them per-inbound
      [ -n "$(json_str "$chunk" uuid)" ] && MODERN=1
      C_EMAIL+=("$e")
      C_SUBID+=("$(json_str "$chunk" subId)")
      C_UUID+=("$( client_uuid "$chunk")")
      C_PASS+=("$( json_str "$chunk" password)")
      C_AUTH+=("$( json_str "$chunk" auth)")
    done < <(printf '%s\n' "$body" | sed 's/},{/}\n{/g')
  fi

  if [ "${#C_EMAIL[@]}" -eq 0 ]; then
    warn "no clients on the panel — creating one via /clients/add"
    if ensure_client_v3 "test@email.com"; then
      MODERN=1
    fi
  fi

  if [ "${#C_EMAIL[@]}" -eq 0 ]; then
    # older panel with no /clients/add -> local generated client, inline secrets
    MODERN=0
    warn "could not create a client via API — using a local generated client"
    [ "${XUI_DEBUG:-0}" = "1" ] && printf '[debug] clients/list after add:\n%s\n' "$body" >&2
    C_EMAIL=("test@email.com")
    C_SUBID=("test-$(rand_hex 4)")
    C_UUID=("$(rand_uuid)")
    C_PASS=("$(rand_b64url 16)")
    C_AUTH=("a$(rand_b64url 12)")
    ok "generated client: ${C_EMAIL[*]}"
  else
    ok "using ${#C_EMAIL[@]} client(s): ${C_EMAIL[*]}${MODERN:+ (v3: secrets are server-side)}"
  fi

  # on v3 panels, settings.clients[] must be bare {id,email,subId}
  [ "$MODERN" = "1" ] && MINC=1
}

# -----------------------------------------------------------------------------
# settings.clients[] per protocol
# -----------------------------------------------------------------------------
# full client object — mirrors what the panel itself stores in settings.clients[]
# (some panel builds strictly validate these fields; missing `id`/`enable` => "request body failed validation")
client_obj() { # $1=proto $2=email $3=subId $4=uuid $5=password $6=auth [$7=method]
  local proto="$1" e="$2" su="$3" u="$4" p="$5" a="$6" m="${7:-}"
  local flow="" extra=""
  # Vision flow is only valid on raw TCP (+TLS/REALITY) or with ML-KEM encryption;
  # non-TCP transports without ML-KEM must leave flow empty.
  if [ "$proto" = "vless" ] && [ "${VLESS_NO_FLOW:-0}" != "1" ]; then
    if [ "${VLESS_ENC:-0}" = "1" ] || [ "${VLESS_TCP:-0}" = "1" ]; then
      flow="xtls-rprx-vision"
    fi
  fi
  case "$proto" in
    ss|ss2022) extra="\"method\":\"$m\"," ;;
    vmess)     extra="\"alterId\":0," ;;
  esac
  # NOTE: keep this MINIMAL. Panels with strict body validation reject
  # unknown/extra client fields ("request body failed validation"), but every
  # protocol needs `id` (uuid), `email` and `subId` to bind the client.
  #
  # MINC=1 -> "v3 unified-client" form: the panel stores password/auth on the
  # client record, so settings.clients[] must NOT carry password/auth/username.
  # vless/vmess already work this way; for trojan/hysteria/ss/http/tuic some
  # builds reject those fields outright.
  if [ "${MINC:-0}" = "1" ]; then
    case "$proto" in
      vless) printf '{"id":"%s","flow":"%s","email":"%s","subId":"%s"}' "$u" "$flow" "$e" "$su" ;;
      vmess) printf '{"id":"%s","alterId":0,"email":"%s","subId":"%s"}' "$u" "$e" "$su" ;;
      *)     printf '{"id":"%s","email":"%s","subId":"%s"}' "$u" "$e" "$su" ;;
    esac
    return 0
  fi

  case "$proto" in
    vless)  printf '{"id":"%s","flow":"%s","email":"%s","subId":"%s"}' "$u" "$flow" "$e" "$su" ;;
    vmess)  printf '{"id":"%s","alterId":0,"email":"%s","subId":"%s"}' "$u" "$e" "$su" ;;
    trojan) printf '{"id":"%s","password":"%s","email":"%s","subId":"%s"}' "$u" "$p" "$e" "$su" ;;
    hysteria) printf '{"id":"%s","password":"%s","auth":"%s","email":"%s","subId":"%s"}' "$u" "$p" "$a" "$e" "$su" ;;
    tuic)   printf '{"id":"%s","password":"%s","email":"%s","subId":"%s"}' "$u" "$p" "$e" "$su" ;;
    ss|ss2022) printf '{"id":"%s","password":"%s","email":"%s","subId":"%s"}' "$u" "$p" "$e" "$su" ;;
    *)      printf '{"id":"%s","email":"%s","subId":"%s"}' "$u" "$e" "$su" ;;
  esac
}

clients_json() {
  local proto="$1" i n out="" sep="" e su u p a
  # v3: clients are standalone and attached afterwards — inbounds carry none
  [ "$MODERN" = "1" ] && { printf '[]'; return 0; }
  n=${#C_EMAIL[@]}
  for ((i=0; i<n; i++)); do
    e="${C_EMAIL[$i]}"; su="${C_SUBID[$i]}"; u="${C_UUID[$i]}"; p="${C_PASS[$i]}"; a="${C_AUTH[$i]}"
    [ -n "$u" ] || u=$(rand_uuid)
    [ -n "$p" ] || p=$(rand_b64url 16)
    [ -n "$a" ] || a="a$(rand_b64url 12)"
    out+="${sep}$(client_obj "$proto" "$e" "$su" "$u" "$p" "$a")"
    sep=","
  done
  printf '[%s]' "$out"
}

# decoded byte length of a base64 string (prints 0 on failure).
# Handles both standard and url-safe base64 (the '-'/'_' chars) and re-adds
# padding — `openssl enc -base64 -d` rejects url-safe input and would return 0,
# which made SS-2022 pick aes-256 (32-byte) for a 16-byte key -> "bad key".
b64len() { # $1=b64
  [ -n "${1:-}" ] || { printf '0'; return 0; }
  local s="$1"
  s=${s//-/+}; s=${s//_/\/}                                  # url-safe -> standard
  case $(( ${#s} % 4 )) in 2) s="${s}==" ;; 3) s="${s}=" ;; esac   # re-add padding
  printf '%s' "$s" | openssl enc -base64 -d -A 2>/dev/null | wc -c | tr -d ' '
}

# shadowsocks clients.
# For SS-2022 the panel takes each client's PSK from its own client record, so we
# must reuse the client's existing password when its length matches the cipher
# key size, otherwise Xray refuses to start ("shadowsocks_2022: bad key").
ss_clients_json() {
  local method="$1" shared="$2" kind="$3" keylen="${4:-0}" i n out="" sep="" e su psk
  # v3: clients are standalone and attached afterwards — inbounds carry none
  [ "$MODERN" = "1" ] && { printf '[]'; return 0; }
  n=${#C_EMAIL[@]}
  for ((i=0; i<n; i++)); do
    e="${C_EMAIL[$i]}"; su="${C_SUBID[$i]}"
    case "$method" in
      2022-*)
        psk="${C_PASS[$i]:-}"
        [ "$(b64len "$psk")" = "$keylen" ] || psk=$(rand_b64 "$keylen")
        ;;
      *) psk="$shared" ;;
    esac
    out+="${sep}$(client_obj "$kind" "$e" "$su" "${C_UUID[$i]:-$(rand_uuid)}" "$psk" "${C_AUTH[$i]:-a$(rand_b64url 12)}" "$method")"
    sep=","
  done
  printf '[%s]' "$out"
}

# -----------------------------------------------------------------------------
# settings object per protocol
# -----------------------------------------------------------------------------
settings_json() {
  local proto="$1" priv pub
  case "$proto" in
    vless)
      if [ "${VLESS_ENC:-0}" = "1" ]; then
        # ML-KEM post-quantum encryption: decryption = X25519 private key,
        # encryption = matching public key (both base64url, 43 chars). Matches
        # `xray vlessenc` (X25519 auth) output.
        read -r priv pub < <(gen_reality_keys)
        printf '{"clients":%s,"decryption":"mlkem768x25519plus.native.600s.%s","encryption":"mlkem768x25519plus.native.0rtt.%s"}' \
          "$(clients_json vless)" "$priv" "$pub"
      else
        printf '{"clients":%s,"decryption":"none"}' "$(clients_json vless)"
      fi
      ;;
    vmess|trojan)
      printf '{"clients":%s}' "$(clients_json "$proto")" ;;
    hysteria)
      printf '{"clients":%s,"version":2}' "$(clients_json hysteria)" ;;
    hy2)
      printf '{"clients":%s,"version":2,"auth":{"type":"password","password":"%s"},"obfs":{"type":"salamander","password":"%s"}}' \
        "$(clients_json hysteria)" "$(rand_b64url 16)" "$(rand_b64url 16)" ;;
    tuic)
      printf '{"clients":%s,"server":{"alpn":["h3"],"authentication_timeout":3,"certificate":"%s","congestion_control":"bbr","log_level":"info","max_idle_time":15,"max_udp_relay_packet_size":1500,"private_key":"%s","sni":"","udp_relay_mode":"native","zero_rtt_handshake":true}}' \
        "$(clients_json tuic)" "$CERT_FILE" "$CERT_KEY" ;;
    shadowsocks-legacy)
      local shared; shared=$(rand_b64url 16)
      printf '{"method":"chacha20-ietf-poly1305","password":"%s","network":"tcp,udp","ivCheck":true,"clients":%s}' \
        "$shared" "$(ss_clients_json chacha20-ietf-poly1305 "$shared" ss 0)" ;;
    shadowsocks-2022)
      # pick the cipher that matches the PSK length the panel's clients already have
      local kl method keylen
      kl=$(b64len "${C_PASS[0]:-}")
      case "$kl" in
        16) method="2022-blake3-aes-128-gcm"; keylen=16 ;;
        *)  method="2022-blake3-aes-256-gcm"; keylen=32; kl=32 ;;
      esac
      printf '{"method":"%s","password":"%s","clients":%s}' \
        "$method" "$(rand_b64 "$keylen")" \
        "$(ss_clients_json "$method" "" ss2022 "$keylen")" ;;
    *) die "settings_json: unsupported protocol $proto" ;;
  esac
}

# -----------------------------------------------------------------------------
# streamSettings templates
# -----------------------------------------------------------------------------
cert_array() {
  printf '[{"ocspStapling":0,"oneTimeLoading":false,"usage":"encipherment","buildChain":false,"certificateFile":"%s","keyFile":"%s","useFile":true}]' \
    "$CERT_FILE" "$CERT_KEY"
}

tls_obj() { # $1 = alpn json
  printf '{"serverName":"","minVersion":"1.2","maxVersion":"1.3","cipherSuites":"TLS_CHACHA20_POLY1305_SHA256","rejectUnknownSni":false,"disableSystemRoot":false,"enableSessionResumption":false,"certificates":%s,"alpn":%s,"echServerKeys":"","settings":{"fingerprint":"chrome","echConfigList":"","pinnedPeerCertSha256":[],"verifyPeerCertByName":""}}' \
    "$(cert_array)" "$1"
}

st_tcp_plain() {
  printf '{"network":"tcp","tcpSettings":{"acceptProxyProtocol":false,"header":{"type":"none"}}}'
}

st_tcp_reality() {
  local priv pub
  read -r priv pub < <(gen_reality_keys)
  printf '{"network":"tcp","tcpSettings":{"acceptProxyProtocol":false,"header":{"type":"none"}},"security":"reality","realitySettings":{"show":false,"xver":0,"target":"www.amazon.com:443","serverNames":["www.amazon.com","www.google.com"],"privateKey":"%s","shortIds":["169f","e0e7a936"],"settings":{"publicKey":"%s","fingerprint":"chrome","serverName":"","spiderX":"/"}}}' \
    "$priv" "$pub"
}

st_wss_tls() { # $1=path
  printf '{"network":"ws","security":"tls","tlsSettings":%s,"wsSettings":{"acceptProxyProtocol":false,"path":"%s","host":"","headers":{},"heartbeatPeriod":0}}' \
    "$(tls_obj '["http/1.1"]')" "${1:-/}"
}

st_hupg_tls() { # $1=path
  printf '{"network":"httpupgrade","httpupgradeSettings":{"acceptProxyProtocol":false,"path":"%s","host":""},"security":"tls","tlsSettings":%s}' \
    "${1:-/}" "$(tls_obj '["h3","http/1.1","h2"]')"
}

st_xhttp_tls() { # $1=path $2=alpn
  printf '{"network":"xhttp","xhttpSettings":{"acceptProxyProtocol":false,"path":"%s","host":""},"security":"tls","tlsSettings":%s}' \
    "$1" "$(tls_obj "$2")"
}

st_xhttp_tls_h3() { # $1=path
  printf '{"network":"xhttp","xhttpSettings":{"acceptProxyProtocol":false,"path":"%s","host":"","alpn":["h3"]},"security":"tls","tlsSettings":%s}' \
    "$1" "$(tls_obj '["h3"]')"
}

st_xhttp_reality() { # $1=path
  local priv pub
  read -r priv pub < <(gen_reality_keys)
  printf '{"network":"xhttp","xhttpSettings":{"acceptProxyProtocol":false,"path":"%s","host":""},"security":"reality","realitySettings":{"show":false,"xver":0,"target":"www.amazon.com:443","serverNames":["www.amazon.com","www.google.com"],"privateKey":"%s","shortIds":["169f","e0e7a936"],"settings":{"publicKey":"%s","fingerprint":"chrome","serverName":"","spiderX":"/"}}}' \
    "$1" "$priv" "$pub"
}

st_kcp_none() {
  # Xray 26.x removed kcpSettings.header/seed/type/congestion/utpSize — mKCP
  # obfuscation now lives in streamSettings.finalmask (mkcp-legacy).
  printf '{"network":"kcp","kcpSettings":{"acceptProxyProtocol":false,"mtu":1350,"tti":20,"uplinkCapacity":100,"downlinkCapacity":200,"cwndMultiplier":1,"maxSendingWindow":2097152},"finalmask":{"udp":[{"type":"mkcp-legacy","settings":{"header":"","value":""}}]}}'
}

# 8 REALITY short IDs of varying byte length (1-8 bytes -> 2-16 hex chars)
gen_shortids() {
  local i out="" sep="" lens=(8 7 1 4 3 5 2 6)
  for i in 0 1 2 3 4 5 6 7; do
    out+="${sep}\"$(rand_hex "${lens[$i]}")\""
    sep=","
  done
  printf '[%s]' "$out"
}

st_trojan_reality() {
  local priv pub sids spider
  read -r priv pub < <(gen_reality_keys)
  sids=$(gen_shortids)
  spider="/$(rand_b64url 12)"
  printf '{"network":"tcp","tcpSettings":{"acceptProxyProtocol":false,"header":{"type":"none"}},"security":"reality","realitySettings":{"show":false,"xver":0,"target":"dl.google.com:443","serverNames":["ai.android","android.com","g.co","goo.gl","www.goo.gl","google-analytics.com","google.com","googlecommerce.com","urchin.com","youtu.be","youtube.com","music.youtube.com","youtubeeducation.com","youtubekids.com","yt.be","android.clients.google.com"],"privateKey":"%s","minClientVer":"","maxClientVer":"","maxTimediff":0,"shortIds":%s,"mldsa65Seed":"","settings":{"publicKey":"%s","fingerprint":"chrome","serverName":"","spiderX":"%s","mldsa65Verify":""}}}' \
    "$priv" "$sids" "$pub" "$spider"
}

st_grpc_tls() {
  printf '{"network":"grpc","grpcSettings":{"acceptProxyProtocol":false,"serviceName":"grpc","multiMode":false},"security":"tls","tlsSettings":%s}' \
    "$(tls_obj '["h2"]')"
}

st_grpc_reality() {
  local priv pub sids spider
  read -r priv pub < <(gen_reality_keys)
  sids=$(gen_shortids)
  spider="/$(rand_b64url 12)"
  printf '{"network":"grpc","grpcSettings":{"acceptProxyProtocol":false,"serviceName":"grpc","multiMode":false},"security":"reality","realitySettings":{"show":false,"xver":0,"target":"dl.google.com:443","serverNames":["ai.android","android.com","g.co","goo.gl","www.goo.gl","google-analytics.com","google.com","googlecommerce.com","urchin.com","youtu.be","youtube.com","music.youtube.com","youtubeeducation.com","youtubekids.com","yt.be","android.clients.google.com"],"privateKey":"%s","minClientVer":"","maxClientVer":"","maxTimediff":0,"shortIds":%s,"mldsa65Seed":"","settings":{"publicKey":"%s","fingerprint":"chrome","serverName":"","spiderX":"%s","mldsa65Verify":""}}}' \
    "$priv" "$sids" "$pub" "$spider"
}

st_tcp_tls() { # $1=alpn json
  printf '{"network":"tcp","tcpSettings":{"acceptProxyProtocol":false,"header":{"type":"none"}},"security":"tls","tlsSettings":%s}' \
    "$(tls_obj "$1")"
}

st_ss_wss_no_tls() {
  printf '{"network":"ws","wsSettings":{"acceptProxyProtocol":false,"path":"/ss","host":"","headers":{},"heartbeatPeriod":0}}'
}

st_hysteria_finalmask() {
  printf '{"network":"hysteria","hysteriaSettings":{"version":2,"udpIdleTimeout":60},"security":"tls","tlsSettings":{"serverName":"","minVersion":"1.2","maxVersion":"1.3","cipherSuites":"","rejectUnknownSni":false,"disableSystemRoot":false,"enableSessionResumption":false,"certificates":%s,"alpn":["h3"],"echServerKeys":"","settings":{"echConfigList":"","pinnedPeerCertSha256":[],"verifyPeerCertByName":""}},"finalmask":{"udp":[{"type":"salamander","settings":{"password":"%s"}}]}}' \
    "$(cert_array)" "$(rand_b64url 16)"
}

st_hysteria_tls() {
  printf '{"network":"hysteria","hysteriaSettings":{"version":2,"udpIdleTimeout":60},"security":"tls","tlsSettings":%s}' \
    "$(tls_obj '["h3"]')"
}

st_tuic() {
  # TUIC v5 carries its full server config (cert/key/alpn/…) in settings.server
  # and has no streamSettings — the panel stores it as null.
  printf 'null'
}

# -----------------------------------------------------------------------------
# recipe table (parallel arrays, index-aligned — names may repeat)
# -----------------------------------------------------------------------------
R_NAME=(
  "VLESS-TCP-REALITY-01" "VLESS-WSS-TLS-01" "VLESS-HUPG-TLS-01" "VLESS-XHTTP2-REALITY-01"
  "VLESS-KCP-NONE-01" "VLESS-XHTTP2-TLS-01" "VLESS-XHTTP3-TLS-01" "VLESS-TCP-XTLS-Vision-01"
  "VLESS-TCP-REALITY-443-01" "VMESS-WSS-TLS-01" "VMESS-TCP-TLS-01" "TROJAN-TCP-TLS-01"
  "TROJAN-WSS-TLS-01" "TROJAN-TCP-REALITY-01" "VMESS-gRPC-TLS-01" "VMESS-HTTPU-TLS-01"
  "VMESS-XHTTP-TLS-01" "HYSTERIA-UDP-TLS-01" "VLESS-gRPC-Reality-01" "VLESS-gRPC-TLS-01"
  "SS-TCP-CHACHA-01" "SS2022-TCP-BLAKE-01" "HY2-UDP-TLS-h3"
  "TUIC-v5-h3" "VLESS-XHTTP2-MLKEM-TLS-01" "VLESS-TCP-MLKEM-REALITY-01" "VLESS-XHTTP2-MLKEM-REALITY-01"
  "VLESS-gRPC-MLKEM-TLS-01" "VLESS-HUPG-MLKEM-TLS-01" "VLESS-TCP-XTLS-Vision-TLS-01"
)
R_PROTO=(
  vless vless vless vless
  vless vless vless vless
  vless vmess vmess trojan
  trojan trojan vmess vmess
  vmess hysteria vless vless
  sl ss2022 hy2
  tuic vless vless vless
  vless vless vless
)
R_PORT=(
  20101 20102 20103 20104
  20105 20201 20202 20203
  443 20111 20112 20121
  20122 20213 20210 20212
  20214 20211 20132 20133
  20131 20170 20151
  20161 20221 20222 20223
  20224 20225 20226
)
R_STREAM=(
  "st_tcp_reality" "st_wss_tls /" "st_hupg_tls /" "st_xhttp_reality /xhttp-reality"
  "st_kcp_none" "st_xhttp_tls /xhttp2 [\"h2\",\"http/1.1\"]" "st_xhttp_tls_h3 /xhttp3" "st_tcp_reality"
  "st_tcp_reality" "st_wss_tls /vms" "st_tcp_tls [\"h3\",\"http/1.1\",\"h2\"]" "st_tcp_tls [\"h3\",\"http/1.1\"]"
  "st_wss_tls /trj" "st_trojan_reality" "st_grpc_tls" "st_hupg_tls /vmh"
  "st_xhttp_tls /vmx [\"h2\",\"http/1.1\"]" "st_hysteria_finalmask" "st_grpc_reality" "st_grpc_tls"
  "st_tcp_plain" "st_tcp_plain" "st_hysteria_tls"
  "st_tuic" "st_xhttp_tls /xhttp2-mlkem [\"h2\",\"http/1.1\"]" "st_tcp_reality" "st_xhttp_reality /xhttp-mlkem-reality"
  "st_grpc_tls" "st_hupg_tls /mlkem" "st_tcp_tls [\"h2\",\"http/1.1\"]"
)
# VLESS encryption per recipe: 1 = ML-KEM post-quantum (mlkem768x25519plus)
R_ENC=(
  0 0 0 0 1 0 0 0
  0 0 0 0 0 0 0 0
  0 0 0 0 0 0 0
  0 1 1 1 1 1 0
)

# -----------------------------------------------------------------------------
# build the full inbound payload
# -----------------------------------------------------------------------------
build_payload() { # $1=index $2=port [$3=1 -> settings/streamSettings as JSON strings]
  local i="$1" port="$2" as_str="${3:-0}" name proto settings stream
  local -a sp args
  local fn
  name="${R_NAME[$i]}"
  proto="${R_PROTO[$i]}"

  # stream template: first word = function, rest = arguments
  read -r -a sp <<< "${R_STREAM[$i]}"
  fn="${sp[0]}"; args=("${sp[@]:1}")

  # per-recipe VLESS flags: ML-KEM encryption (R_ENC), XTLS-flow (off only on mKCP),
  # and TCP transport (Vision flow valid)
  VLESS_ENC="${R_ENC[$i]:-0}"
  VLESS_NO_FLOW=0
  VLESS_TCP=0
  [ "$proto" = "vless" ] && [ "$fn" = "st_kcp_none" ] && VLESS_NO_FLOW=1
  case "$fn" in
    st_tcp_reality|st_tcp_tls) VLESS_TCP=1 ;;
  esac

  case "$proto" in
    sl|ss)    settings=$(settings_json shadowsocks-legacy) ;;
    ss2022)   settings=$(settings_json shadowsocks-2022) ;;
    *)        settings=$(settings_json "$proto") ;;
  esac

  stream=$("$fn" ${args[@]+"${args[@]}"})

  if [ "$as_str" = "1" ]; then
    # some panel builds expect these two as JSON-encoded strings, not objects
    local es ss2
    es=${settings//\\/\\\\}; es=${es//\"/\\\"}
    ss2=${stream//\\/\\\\}; ss2=${ss2//\"/\\\"}
    printf '{"enable":true,"remark":"%s","listen":"","port":%s,"protocol":"%s","expiryTime":0,"total":0,"up":0,"down":0,"settings":"%s","streamSettings":"%s","sniffing":{"enabled":true,"destOverride":["http","tls"]},"tag":"in-%s-%s"}' \
      "$name" "$port" "$(proto_name "$proto")" "$es" "$ss2" "$port" "${proto:0:4}"
  else
    printf '{"enable":true,"remark":"%s","listen":"","port":%s,"protocol":"%s","expiryTime":0,"total":0,"up":0,"down":0,"settings":%s,"streamSettings":%s,"sniffing":{"enabled":true,"destOverride":["http","tls"]},"tag":"in-%s-%s"}' \
      "$name" "$port" "$(proto_name "$proto")" "$settings" "$stream" "$port" "${proto:0:4}"
  fi
}

proto_name() {
  case "$1" in
    sl|ss|ss2022) printf 'shadowsocks' ;;
    hy2)          printf 'hysteria' ;;
    *)            printf '%s' "$1" ;;
  esac
}

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
main() {
  check_deps

  log "=== $PROG — 3x-ui recipe installer (bash $BASH_VERSION) ==="
  log "Credentials are held in memory only; nothing is written to disk."
  echo

  local host port basepath token
  # non-interactive mode: all credentials may come from environment variables
  if [ -n "${XUI_HOST:-}" ] && [ -n "${XUI_PORT:-}" ] && [ -n "${XUI_TOKEN:-}" ] && [ -n "${XUI_BASEPATH:-}" ]; then
    host="${XUI_HOST}"; port="${XUI_PORT}"; basepath="${XUI_BASEPATH}"; token="${XUI_TOKEN}"
    log "Using credentials from XUI_HOST / XUI_PORT / XUI_BASEPATH / XUI_TOKEN"
  else
    ask "Panel host (IP or domain): " host;     [ -n "$host" ]     || die "host required"
    ask "Panel port: " port;                     [ -n "$port" ]     || die "port required"
    ask "WebBasePath (e.g. aBc123): " basepath;  [ -n "$basepath" ] || die "base path required"
    ask -s "API token: " token; echo;            [ -n "$token" ]    || die "token required"
  fi

  BASE="https://$host:$port/${basepath#/}"
  TOKEN="$token"

  # The panel's TLS cert usually matches its domain, not the bare IP the user
  # typed. Without -k every request fails with curl 60 / schannel SEC_E_WRONG_PRINCIPAL
  # before any recipe logic runs. Auto-enable insecure TLS for IP hosts unless
  # the user set XUI_INSECURE explicitly.
  if [ -z "${XUI_INSECURE:-}" ] && printf '%s' "$host" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    XUI_INSECURE=1
    CURL_TLS="-k"
    warn "host is an IP address — skipping TLS verification (cert is issued for a domain)"
  fi

  local probe
  probe=$(api GET "/panel/api/inbounds/list")
  case "$probe" in
    *'"success":true'*|*'"success": true'*) ok "connected to $BASE" ;;
    *) die "cannot reach the panel — check host / port / basePath / token" ;;
  esac

  # ---- certificate paths from the panel (do not hardcode) ----
  local cbody cf ck
  cbody=$(api GET "/panel/api/server/getWebCertFiles")
  cf=$(json_str "$cbody" webCertFile); [ -n "$cf" ] || cf=$(json_str "$cbody" certificateFile)
  ck=$(json_str "$cbody" webKeyFile);  [ -n "$ck" ] || ck=$(json_str "$cbody" keyFile)
  if [ -n "$cf" ] && [ -n "$ck" ]; then
    CERT_FILE="$cf"; CERT_KEY="$ck"
    ok "certificates: $CERT_FILE / $CERT_KEY"
  else
    warn "could not read certificate paths from the panel — TLS inbounds may fail to start"
  fi

  fetch_clients

  # ---- ports already in use ----
  local list frag p
  declare -a used=()
  declare -a CREATED_IDS=()
  list=$(api GET "/panel/api/inbounds/list")
  while IFS= read -r p; do
    [ -n "$p" ] && used+=("$p")
  done < <(printf '%s' "$list" | tr ',' '\n' \
             | grep '"port"' \
             | sed 's/.*"port"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/' \
             | grep -E '^[0-9]+$')

  # ---- selection ----
  local only="${XUI_ONLY:-}"
  [ -n "$only" ] && only=",${only// /},"   # -> ",NAME1,NAME2," for simple substring matching

  local total=${#R_NAME[@]} i name proto base_port port_free resp created=0 failed=0
  printf '\n%-28s %-12s %6s  %s\n' "RECIPE" "PROTOCOL" "PORT" "RESULT"
  printf '%s\n' "----------------------------------------------------------------------------"

  for ((i=0; i<total; i++)); do
    name="${R_NAME[$i]}"
    proto="${R_PROTO[$i]}"

    # v3 panels require bare {id,email,subId} clients; on v2 start each recipe
    # fresh so a failed recipe's MINC=1 fallback doesn't leak into later ones.
    [ "$MODERN" = "1" ] && MINC=1 || MINC=0

    if [ -n "$only" ]; then
      case "$only" in *",$name,"*) : ;; *) continue ;; esac
    fi

    base_port="${R_PORT[$i]}"
    # REALITY on 443 must keep its disguise port; if taken, skip rather than
    # silently moving to 444 (which breaks the www.amazon.com:443 masking).
    if [ "$base_port" = "443" ] && printf '%s\n' ${used[@]+"${used[@]}"} | grep -qx "443"; then
      warn "port 443 busy -> skipping REALITY recipe ($name)"
      continue
    fi
    port_free="$base_port"
    while printf '%s\n' ${used[@]+"${used[@]}"} | grep -qx "$port_free"; do
      port_free=$((port_free + 1))
    done
    used+=("$port_free")

    if [ "$port_free" != "$base_port" ]; then
      warn "port $base_port busy -> using $port_free ($name)"
    fi

    resp=$(api POST "/panel/api/inbounds/add" "$(build_payload "$i" "$port_free")")

    # Fallback 1: v3 unified-client panels reject password/auth/username inside
    # settings.clients[] -> retry with bare {id,email,subId} clients.
    # Fallback 2: some forks expect settings/streamSettings as JSON strings.
    case "$resp" in
      *'"success":true'*|*'"success": true'*) : ;;
      *)
        local resp2
        MINC=1 resp2=$(api POST "/panel/api/inbounds/add" "$(build_payload "$i" "$port_free")")
        case "$resp2" in
          *'"success":true'*|*'"success": true'*) resp="$resp2" ;;
          *)
            resp2=$(api POST "/panel/api/inbounds/add" "$(build_payload "$i" "$port_free" 1)")
            case "$resp2" in
              *'"success":true'*|*'"success": true'*) resp="$resp2" ;;
            esac
            ;;
        esac
        ;;
    esac

    case "$resp" in
      *'"success":true'*|*'"success": true'*)
        created=$((created + 1))
        local inbound_id
        inbound_id=$(json_num "$resp" id)
        CREATED_IDS+=("$inbound_id")
        printf '%-28s %-12s %6s  OK (id=%s)\n' \
          "$name" "$(proto_name "$proto")" "$port_free" "$inbound_id"

        # ---- health gate: did this inbound crash/restart xray into a bad config? ----
        local xr_state xr_rc
        xr_state=$(panel_xray_state); xr_rc=$?
        if [ "$xr_rc" -ne 0 ]; then
          # panel API itself is unreachable — leave the inbound as-is, warn loudly.
          warn "inbound $name (port $port_free): panel status unavailable ($xr_rc) — leaving enabled"
        elif [ "$xr_state" != "running" ]; then
          # this inbound broke xray: keep it on disk but disable it so the next
          # recipe starts from a clean slate. Do NOT delete it (user may inspect).
          disable_inbound "$inbound_id"
          printf '%-28s %-12s %6s  BROKEN: panel config — disabled inbound id=%s (xray state="%s")\n' \
            "$name" "$(proto_name "$proto")" "$port_free" "$inbound_id" "$xr_state"
          failed=$((failed + 1))
          # recover xray so subsequent recipes aren't falsely reported broken.
          if wait_xray_running; then ok "xray recovered to running after disabling $name"; fi
        else
          ok "xray healthy (state=running)"
        fi
        ;;
      *)
        failed=$((failed + 1))
        printf '%-28s %-12s %6s  FAIL: %s\n' \
          "$name" "$(proto_name "$proto")" "$port_free" \
          "$(json_str "$resp" msg)"
        if [ "${XUI_DEBUG:-0}" = "1" ]; then
          printf '     [debug] response: %s\n' "$resp" >&2
        fi
        ;;
    esac
  done

  printf '%s\n' "----------------------------------------------------------------------------"
  log "DONE: $created created, $failed failed"

  # on v3, attach every existing client to all inbounds we just created so they
  # show up in each client's subscription ("Attached inbounds"). v2 clients are
  # already embedded in their inbound settings, so no separate attach is needed.
  if [ "$MODERN" = "1" ] && [ "${#CREATED_IDS[@]}" -gt 0 ]; then
    ids=""
    for _id in "${CREATED_IDS[@]}"; do ids="${ids}${ids:+,}$_id"; done
    local c n_c
    n_c=${#C_EMAIL[@]}
    for ((c=0; c<n_c; c++)); do
      printf 'adding inbounds to client %s\n' "${C_EMAIL[$c]}"
      api POST "/panel/api/clients/${C_EMAIL[$c]}/attach" "{\"inboundIds\":[$ids]}" >/dev/null
    done
    ok "attached ${n_c} client(s) to ${#CREATED_IDS[@]} inbound(s)"
  fi

  # remove the temporary seed inbound used to anchor the v3 client
  if [ -n "$SEED_ID" ] && [[ "$SEED_ID" =~ ^[0-9]+$ ]]; then
    api POST "/panel/api/inbounds/del/$SEED_ID" >/dev/null
    ok "removed seed inbound id=$SEED_ID"
  else
    warn "seed inbound was not created or has invalid id, skipping cleanup"
  fi

  # ---- apply XTLS Vision flow to all clients (v3) ----
  # bulkAdjust sets flow per-inbound: vision goes only to inbounds that support
  # it (TCP/REALITY); XHTTP/gRPC/KCP are left without flow. Safe for a shared
  # VLESS client attached to mixed transports (3x-ui issue #4578).
  if [ "$MODERN" = "1" ] && [ "${#C_EMAIL[@]}" -gt 0 ]; then
    set_client_flow "xtls-rprx-vision"
  fi

  [ "$failed" -eq 0 ] || exit 1
}

main "$@"
