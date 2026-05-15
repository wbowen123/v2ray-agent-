#!/usr/bin/env bash

export LANG=en_US.UTF-8

SCRIPT_VERSION="v0.1.0"
PROJECT_ROOT="/etc/v2ray-agent/docker-agent"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
STATE_FILE="${PROJECT_ROOT}/runtime.env"
MANIFEST_FILE="${PROJECT_ROOT}/migration-manifest.txt"
USERS_FILE="${PROJECT_ROOT}/users.json"
SUBSCRIBE_SALT_FILE="${PROJECT_ROOT}/subscribe_local/subscribeSalt"
XRAY_CONFIG_FILE="${PROJECT_ROOT}/xray/conf/config.json"
SINGBOX_CONFIG_FILE="${PROJECT_ROOT}/sing-box/conf/config.json"
NGINX_SUBSCRIBE_FILE="${PROJECT_ROOT}/nginx/conf.d/subscribe.conf"
FAKE_SITE_DIR="${PROJECT_ROOT}/site"
SELF_TARGET="/etc/v2ray-agent/docker_v2ray_agent.sh"
REALITY_SCRIPT_TARGET="/etc/v2ray-agent/docker_reality.sh"
GITHUB_REPO_URL="https://github.com/wbowen123/v2ray-agent"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/wbowen123/v2ray-agent/master/docker_v2ray_agent.sh"

ALL_PROTOCOL_IDS=("0" "1" "3" "4" "6" "7" "8" "9" "10" "11" "12" "13")
ALL_PROTOCOL_NAMES=(
    "VLESS+TCP[TLS_Vision]"
    "VLESS+WS[TLS]"
    "VMess+WS[TLS]"
    "Trojan+TCP[TLS]"
    "Hysteria2"
    "VLESS+Reality+Vision"
    "VLESS+Reality+gRPC"
    "Tuic"
    "Naive"
    "VMess+TLS+HTTPUpgrade"
    "VLESS+Reality+XHTTP"
    "AnyTLS"
)

echoContent() {
    case "$1" in
    red)
        printf "\033[31m%b\033[0m\n" "$2"
        ;;
    skyBlue)
        printf "\033[1;36m%b\033[0m\n" "$2"
        ;;
    green)
        printf "\033[32m%b\033[0m\n" "$2"
        ;;
    white)
        printf "\033[37m%b\033[0m\n" "$2"
        ;;
    yellow)
        printf "\033[33m%b\033[0m\n" "$2"
        ;;
    magenta)
        printf "\033[35m%b\033[0m\n" "$2"
        ;;
    esac
}

normalizeYesNoInput() {
    local var_name=$1
    local var_value="${!var_name}"
    printf -v "${var_name}" '%s' "${var_value,,}"
}

commandExists() {
    command -v "$1" >/dev/null 2>&1
}

ensureRootLinux() {
    local osType
    osType="$(uname -s 2>/dev/null || true)"
    if [[ "${osType}" != "Linux" ]]; then
        echoContent red "本脚本需要在 Linux 环境运行（当前：${osType}）"
        exit 1
    fi
    if [[ "$(id -u)" != "0" ]]; then
        echoContent red "请使用 root 或 sudo 运行本脚本"
        exit 1
    fi
}

showHelp() {
    echoContent skyBlue "docker_v2ray_agent.sh - 八合一 Docker 版总控脚本"
    echoContent white ""
    echoContent white "用法:"
    echoContent white "  bash docker_v2ray_agent.sh"
    echoContent white ""
    echoContent white "说明:"
    echoContent white "  1. 该脚本负责 Docker 八合一版的菜单、目录、Compose 骨架和管理入口。"
    echoContent white "  2. 无域名 Reality 安装与管理委托给 docker_reality.sh。"
    echoContent white "  3. 会创建 vad / VAD 快捷方式。"
    exit 0
}

ensureProjectDirs() {
    mkdir -p "${PROJECT_ROOT}"
    mkdir -p "${PROJECT_ROOT}/compose"
    mkdir -p "${PROJECT_ROOT}/xray/conf"
    mkdir -p "${PROJECT_ROOT}/sing-box/conf/config"
    mkdir -p "${PROJECT_ROOT}/nginx/conf.d"
    mkdir -p "${FAKE_SITE_DIR}"
    mkdir -p "${PROJECT_ROOT}/subscribe_local/default"
    mkdir -p "${PROJECT_ROOT}/subscribe_local/clashMeta"
    mkdir -p "${PROJECT_ROOT}/subscribe_local/sing-box"
    mkdir -p "${PROJECT_ROOT}/subscribe/default"
    mkdir -p "${PROJECT_ROOT}/subscribe/clashMetaProfiles"
    mkdir -p "${PROJECT_ROOT}/subscribe/clashMeta"
    mkdir -p "${PROJECT_ROOT}/subscribe/sing-box_profiles"
    mkdir -p "${PROJECT_ROOT}/subscribe/sing-box"
    mkdir -p "${PROJECT_ROOT}/tls"
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/runtime"
}

loadState() {
    install_mode=""
    selected_protocol_ids=""
    selected_protocol_names=""
    core_stack="hybrid"
    stack_status="not_installed"
    state_created_at=""
    current_host=""
    subscribe_port=""
    subscribe_type="http"
    current_path=""
    xhttp_path=""
    tls_cert_file=""
    tls_key_file=""
    reality_server_name=""
    reality_target_port="443"
    reality_private_key=""
    reality_public_key=""
    reality_short_id="6ba85179e30d4fc2"
    vless_tcp_port=""
    vless_ws_port=""
    vmess_ws_port=""
    trojan_port=""
    hysteria2_port=""
    reality_vision_port=""
    reality_grpc_port=""
    tuic_port=""
    naive_port=""
    vmess_httpupgrade_port=""
    reality_xhttp_port=""
    anytls_port=""
    hysteria2_up_mbps="1000"
    hysteria2_down_mbps="1000"
    tuic_congestion_control="bbr"
    hysteria2_port_hopping="55000:60000"
    tuic_port_hopping="55000:60000"
    fake_site_title="Welcome"
    fake_site_mode="default"
    if [[ -f "${STATE_FILE}" ]]; then
        # shellcheck disable=SC1090
        source "${STATE_FILE}"
    fi
}

saveState() {
    local oldUmask
    oldUmask="$(umask)"
    umask 077
    cat >"${STATE_FILE}" <<EOF
install_mode="${install_mode}"
selected_protocol_ids="${selected_protocol_ids}"
selected_protocol_names="${selected_protocol_names}"
core_stack="${core_stack}"
stack_status="${stack_status}"
state_created_at="${state_created_at}"
current_host="${current_host}"
subscribe_port="${subscribe_port}"
subscribe_type="${subscribe_type}"
current_path="${current_path}"
xhttp_path="${xhttp_path}"
tls_cert_file="${tls_cert_file}"
tls_key_file="${tls_key_file}"
reality_server_name="${reality_server_name}"
reality_target_port="${reality_target_port}"
reality_private_key="${reality_private_key}"
reality_public_key="${reality_public_key}"
reality_short_id="${reality_short_id}"
vless_tcp_port="${vless_tcp_port}"
vless_ws_port="${vless_ws_port}"
vmess_ws_port="${vmess_ws_port}"
trojan_port="${trojan_port}"
hysteria2_port="${hysteria2_port}"
reality_vision_port="${reality_vision_port}"
reality_grpc_port="${reality_grpc_port}"
tuic_port="${tuic_port}"
naive_port="${naive_port}"
vmess_httpupgrade_port="${vmess_httpupgrade_port}"
reality_xhttp_port="${reality_xhttp_port}"
anytls_port="${anytls_port}"
hysteria2_up_mbps="${hysteria2_up_mbps}"
hysteria2_down_mbps="${hysteria2_down_mbps}"
tuic_congestion_control="${tuic_congestion_control}"
hysteria2_port_hopping="${hysteria2_port_hopping}"
tuic_port_hopping="${tuic_port_hopping}"
fake_site_title="${fake_site_title}"
fake_site_mode="${fake_site_mode}"
EOF
    umask "${oldUmask}"
}

joinSelectedProtocolNames() {
    local ids="$1"
    local joined=""
    local IFS=','
    local id
    read -r -a current_ids <<<"${ids}"
    local idx
    for id in "${current_ids[@]}"; do
        for idx in "${!ALL_PROTOCOL_IDS[@]}"; do
            if [[ "${ALL_PROTOCOL_IDS[$idx]}" == "${id}" ]]; then
                if [[ -n "${joined}" ]]; then
                    joined+=" "
                fi
                joined+="${ALL_PROTOCOL_NAMES[$idx]}"
                break
            fi
        done
    done
    printf '%s' "${joined}"
}

showInstallStatus() {
    loadState
    if [[ "${stack_status}" == "installed" || "${stack_status}" == "scaffolded" ]]; then
        echoContent green "核心: docker-hybrid[运行中/待迁移]"
        if [[ -n "${selected_protocol_names}" ]]; then
            echoContent green "已选协议: ${selected_protocol_names}"
        fi
    else
        echoContent yellow "当前尚未创建 Docker 八合一栈"
    fi
}

showContactInfo() {
    echoContent green "telegram:@wbowen"
    echoContent green "email:wbowengg@gmail.com"
}

showDockerStartHint() {
    echoContent green "安装后，运行以下命令可再次打开 Docker 管理菜单:\n\nvad"
    echoContent yellow "兼容命令：vad、VAD"
}

selfInstallShortcut() {
    local currentScript=""
    local shortcutCreated="false"
    currentScript="$0"

    mkdir -p /etc/v2ray-agent

    if [[ -f "${currentScript}" && "${currentScript}" != "${SELF_TARGET}" ]]; then
        if cp "${currentScript}" "${SELF_TARGET}" 2>/dev/null; then
            chmod 700 "${SELF_TARGET}"
        fi
    fi

    if [[ -f "${SELF_TARGET}" ]]; then
        if [[ -d "/usr/bin" ]]; then
            rm -f /usr/bin/vad /usr/bin/VAD
            ln -s "${SELF_TARGET}" /usr/bin/vad
            ln -s "${SELF_TARGET}" /usr/bin/VAD
            chmod 700 /usr/bin/vad /usr/bin/VAD
            shortcutCreated="true"
        fi
        if [[ -d "/usr/sbin" ]]; then
            rm -f /usr/sbin/vad /usr/sbin/VAD
            ln -s "${SELF_TARGET}" /usr/sbin/vad
            ln -s "${SELF_TARGET}" /usr/sbin/VAD
            chmod 700 /usr/sbin/vad /usr/sbin/VAD
            shortcutCreated="true"
        fi
    fi

    if [[ "${shortcutCreated}" == "true" ]]; then
        showDockerStartHint
    fi
}

ensureDockerEnvironment() {
    if ! commandExists docker; then
        echoContent red "未检测到 Docker，请先安装 Docker"
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        echoContent red "Docker 已安装但守护进程未运行，请先启动 Docker"
        exit 1
    fi
    if docker compose version >/dev/null 2>&1; then
        compose_command="docker compose"
        return 0
    fi
    if commandExists docker-compose; then
        compose_command="docker-compose"
        return 0
    fi
    echoContent red "未检测到 docker compose 插件或 docker-compose"
    exit 1
}

writeComposeScaffold() {
    cat >"${COMPOSE_FILE}" <<EOF
services:
  xray:
    image: ghcr.io/xtls/xray-core:26.5.9
    container_name: v2ray-agent-xray
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/xray/conf:/etc/xray:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${PROJECT_ROOT}/logs:/var/log/v2ray-agent
    command: ["run", "-confdir", "/etc/xray/"]

  sing-box:
    image: ghcr.io/sagernet/sing-box:latest
    container_name: v2ray-agent-sing-box
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/sing-box/conf:/etc/sing-box:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${PROJECT_ROOT}/logs:/var/log/v2ray-agent
    command: ["run", "-c", "/etc/sing-box/config.json"]

  nginx:
    image: nginx:alpine
    container_name: v2ray-agent-nginx
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/nginx/conf.d:/etc/nginx/conf.d:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${PROJECT_ROOT}/subscribe:/usr/share/nginx/html/subscribe:ro
      - ${PROJECT_ROOT}/logs:/var/log/nginx

networks:
  default:
    name: v2ray-agent-docker
EOF
}

writeMigrationManifest() {
    cat >"${MANIFEST_FILE}" <<EOF
docker_v2ray_agent.sh
版本: ${SCRIPT_VERSION}
项目目录: ${PROJECT_ROOT}
GitHub: ${GITHUB_REPO_URL}

当前目标:
1. 对齐 install.sh 的八合一菜单结构
2. 通过 Docker Compose 管理 xray、sing-box、nginx、订阅目录
3. 复用 docker_reality.sh 处理无域名 Reality 安装与管理

当前已完成:
- Docker 八合一总控菜单
- 状态文件 runtime.env
- Compose 骨架 docker-compose.yml
- 目录骨架 xray/sing-box/nginx/subscribe/tls/logs
- 快捷方式 vad / VAD
- 更新、卸载、Reality 子脚本接入

待迁移:
- install.sh 所有协议的 Docker 配置生成器
- 订阅链接和二维码生成
- 证书导入/申请及续期
- 账号增删、端口增删、CDN 与分流
- Hysteria2 / Tuic / AnyTLS / Naive 等完整运行配置
EOF
}

containsProtocol() {
    local target="$1"
    local token
    IFS=',' read -r -a __protocol_array <<<"${selected_protocol_ids}"
    for token in "${__protocol_array[@]}"; do
        if [[ "${token}" == "${target}" ]]; then
            return 0
        fi
    done
    return 1
}

initRandomPath() {
    local chars="abcdefghijklmnopqrstuvwxyz"
    local randomPath=""
    local _idx
    for _idx in 1 2 3 4; do
        randomPath+="${chars:RANDOM%${#chars}:1}"
    done
    printf '%s' "${randomPath}"
}

randomPort() {
    printf '%s' "$((RANDOM % 20001 + 10000))"
}

generateUUID() {
    if commandExists python3; then
        python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
        return 0
    fi
    cat /proc/sys/kernel/random/uuid
}

ensureUsersFile() {
    if [[ ! -f "${USERS_FILE}" ]]; then
        echo "[]" >"${USERS_FILE}"
    fi
}

getUserCount() {
    ensureUsersFile
    python3 - "${USERS_FILE}" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(len(data))
PY
}

createUserRecord() {
    local userEmail="$1"
    local userUUID="$2"
    ensureUsersFile
    python3 - "${USERS_FILE}" "${userEmail}" "${userUUID}" <<'PY'
import json, sys
path, email, uuid = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
data.append({
    "email": email,
    "uuid": uuid,
    "password": uuid,
    "tuic_password": uuid.replace('-', ''),
    "created_at": ""
})
with open(path, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
PY
}

removeUserRecord() {
    local userIndex="$1"
    ensureUsersFile
    python3 - "${USERS_FILE}" "${userIndex}" <<'PY'
import json, sys
path = sys.argv[1]
target = int(sys.argv[2]) - 1
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
if 0 <= target < len(data):
    del data[target]
with open(path, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
PY
}

listUsers() {
    ensureUsersFile
    python3 - "${USERS_FILE}" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
for idx, item in enumerate(data, 1):
    print(f"{idx}:{item.get('email','')},{item.get('uuid','')}")
PY
}

createInitialUserIfMissing() {
    if [[ "$(getUserCount)" == "0" ]]; then
        local initUUID
        local initEmail
        initUUID="$(generateUUID)"
        initEmail="${initUUID%%-*}"
        createUserRecord "${initEmail}" "${initUUID}"
    fi
}

getRealityTargetDomainPool() {
    cat <<EOF
prod.log.shortbread.aws.dev
www.microsoft.com
ts4.tc.mm.bing.net
www.hp.com
assets.cloudflare.com
www.bing.com
ipv6.6sc.co
www.gstatic.com
www.adobe.com
ts3.tc.mm.bing.net
www.japan.travel
www.aniplex.co.jp
www.caltech.edu
www.princeton.edu
www.columbia.edu
www.ucla.edu
www.asus.com
www.ibm.com
www.synology.com
www.vmware.com
EOF
}

getCurrentTimeMillis() {
    local currentMillis=
    currentMillis=$(date +%s%3N 2>/dev/null)
    if [[ "${currentMillis}" =~ ^[0-9]+$ ]]; then
        echo "${currentMillis}"
    else
        echo "$(( $(date +%s) * 1000 ))"
    fi
}

testRealityTargetDomains() {
    local targetDomain=
    while read -r targetDomain; do
        [[ -z "${targetDomain}" ]] && continue
        local targetHost="${targetDomain}"
        local targetPort="443"
        local startTime=
        local endTime=
        if [[ "${targetDomain}" == *":"* ]]; then
            targetHost=$(echo "${targetDomain}" | awk -F "[:]" '{print $1}')
            targetPort=$(echo "${targetDomain}" | awk -F "[:]" '{print $2}')
        fi
        startTime=$(getCurrentTimeMillis)
        if timeout 1 openssl s_client -connect "${targetHost}:${targetPort}" -servername "${targetHost}" </dev/null >/dev/null 2>&1; then
            endTime=$(getCurrentTimeMillis)
            echo "$((endTime - startTime))|${targetHost}|${targetPort}"
        fi
    done < <(getRealityTargetDomainPool) | sort -t '|' -k1,1n
}

readLocalTLS() {
    local tlsDomain=$1
    local certCandidate=
    local keyCandidate=
    local searchDir=
    local certCandidates=(
        "${PROJECT_ROOT}/tls/${tlsDomain}.crt"
        "${PROJECT_ROOT}/tls/${tlsDomain}.pem"
        "/etc/nginx/ssl/${tlsDomain}.pem"
        "/etc/nginx/ssl/${tlsDomain}.crt"
        "/etc/letsencrypt/live/${tlsDomain}/fullchain.pem"
        "/etc/letsencrypt/live/${tlsDomain}/cert.pem"
        "/etc/ssl/certs/${tlsDomain}.crt"
        "/etc/ssl/certs/${tlsDomain}.pem"
        "${PWD}/fullchain"
        "${PWD}/fullchain.pem"
        "${PWD}/cert.pem"
        "${PWD}/certificate.pem"
    )
    local keyCandidates=(
        "${PROJECT_ROOT}/tls/${tlsDomain}.key"
        "/etc/nginx/ssl/${tlsDomain}.key"
        "/etc/nginx/ssl/privkey.pem"
        "/etc/letsencrypt/live/${tlsDomain}/privkey.pem"
        "/etc/ssl/private/${tlsDomain}.key"
        "${PWD}/key"
        "${PWD}/privkey.pem"
        "${PWD}/private.key"
        "${PWD}/privatekey.pem"
    )

    localTLSFullchainFile=""
    localTLSKeyFile=""

    for certCandidate in "${certCandidates[@]}"; do
        if [[ -f "${certCandidate}" ]] && grep -q "BEGIN CERTIFICATE" "${certCandidate}"; then
            localTLSFullchainFile="${certCandidate}"
            break
        fi
    done

    for keyCandidate in "${keyCandidates[@]}"; do
        if [[ -f "${keyCandidate}" ]] && grep -q "BEGIN .*PRIVATE KEY" "${keyCandidate}"; then
            localTLSKeyFile="${keyCandidate}"
            break
        fi
    done

    if [[ -z "${localTLSFullchainFile}" || -z "${localTLSKeyFile}" ]]; then
        for searchDir in "${PWD}" "/etc" "/root" "/www" "/opt" "/usr/local"; do
            [[ ! -d "${searchDir}" ]] && continue
            if [[ -z "${localTLSFullchainFile}" ]]; then
                certCandidate=$(find "${searchDir}" -maxdepth 6 -type f \( -name "${tlsDomain}.crt" -o -name "${tlsDomain}.pem" -o -name "${tlsDomain}.cer" -o -name "fullchain.pem" -o -name "fullchain.cer" -o -name "cert.pem" -o -name "certificate.pem" \) 2>/dev/null | head -n 1)
                if [[ -n "${certCandidate}" ]] && grep -q "BEGIN CERTIFICATE" "${certCandidate}"; then
                    localTLSFullchainFile="${certCandidate}"
                fi
            fi
            if [[ -z "${localTLSKeyFile}" ]]; then
                keyCandidate=$(find "${searchDir}" -maxdepth 6 -type f \( -name "${tlsDomain}.key" -o -name "privkey.pem" -o -name "private.key" -o -name "privatekey.pem" \) 2>/dev/null | head -n 1)
                if [[ -n "${keyCandidate}" ]] && grep -q "BEGIN .*PRIVATE KEY" "${keyCandidate}"; then
                    localTLSKeyFile="${keyCandidate}"
                fi
            fi
        done
    fi
}

installLocalTLS() {
    local tlsDomain="$1"
    readLocalTLS "${tlsDomain}"
    if [[ -z "${localTLSFullchainFile}" || -z "${localTLSKeyFile}" ]]; then
        return 1
    fi
    if ! openssl x509 -in "${localTLSFullchainFile}" -noout >/dev/null 2>&1; then
        return 1
    fi
    if ! openssl pkey -in "${localTLSKeyFile}" -noout >/dev/null 2>&1; then
        return 1
    fi
    cp "${localTLSFullchainFile}" "${PROJECT_ROOT}/tls/${tlsDomain}.crt"
    cp "${localTLSKeyFile}" "${PROJECT_ROOT}/tls/${tlsDomain}.key"
    chmod 600 "${PROJECT_ROOT}/tls/${tlsDomain}.crt" "${PROJECT_ROOT}/tls/${tlsDomain}.key"
    tls_cert_file="${PROJECT_ROOT}/tls/${tlsDomain}.crt"
    tls_key_file="${PROJECT_ROOT}/tls/${tlsDomain}.key"
    echoContent green " ---> 本地证书导入成功"
    return 0
}

protocolSelectionRequiresTLS() {
    local tlsProtocol
    for tlsProtocol in 0 1 3 4 6 9 10 11 13; do
        if containsProtocol "${tlsProtocol}"; then
            return 0
        fi
    done
    return 1
}

protocolSelectionHasReality() {
    local realityProtocol
    for realityProtocol in 7 8 12; do
        if containsProtocol "${realityProtocol}"; then
            return 0
        fi
    done
    return 1
}

generateRealityKeypair() {
    local x25519Output=""
    x25519Output=$(docker run --rm ghcr.io/xtls/xray-core:26.5.9 x25519 2>/dev/null) || return 1
    reality_private_key=$(echo "${x25519Output}" | awk -F': ' '/PrivateKey|Private key/ {print $2; exit}')
    reality_public_key=$(echo "${x25519Output}" | awk -F': ' '/Password|Public key/ {print $2; exit}')
    [[ -n "${reality_private_key}" && -n "${reality_public_key}" ]]
}

promptRealityServerName() {
    local realityDomainTestStatus=""
    local useFastestRealityDomainStatus=""
    local realityCustomServerName=""
    local fastestRealityServerName=""
    local fastestRealityTargetPort="443"
    local selectRealityDomainIndex=""
    local selectedRealityDomain=""
    local count=0
    local randomIdx=0
    local realityDomainList=""
    local -a realityLatencyList=()
    local realityLatencyItem=""
    local realityLatencyIndex=1

    if [[ -n "${reality_server_name}" ]]; then
        return 0
    fi

    realityDomainList="$(getRealityTargetDomainPool | paste -sd ',')"
    echoContent skyBlue "\n================ 配置客户端可用的serverNames ===============\n"
    echoContent yellow "#注意事项"
    echoContent green "Reality目标可用域名列表：https://www.v2ray-agent.com/archives/1689439383686#heading-3\n"
    echoContent yellow "录入示例:addons.mozilla.org:443\n"
    echoContent yellow "可执行测速脚本，自动按延迟排序 20 个常用伪装域名\n"

    read -r -p "是否执行Reality伪装域名测速脚本？[回车默认y]:" realityDomainTestStatus
    if [[ -z "${realityDomainTestStatus}" ]]; then
        realityDomainTestStatus="y"
    fi
    normalizeYesNoInput realityDomainTestStatus

    if [[ "${realityDomainTestStatus}" == "y" ]]; then
        mapfile -t realityLatencyList < <(testRealityTargetDomains)
        if [[ ${#realityLatencyList[@]} -gt 0 ]]; then
            echoContent yellow "已按延迟从低到高排序如下："
            for realityLatencyItem in "${realityLatencyList[@]}"; do
                local realityLatency=
                local realityLatencyServerName=
                local realityLatencyPort=
                realityLatency=$(echo "${realityLatencyItem}" | awk -F "[|]" '{print $1}')
                realityLatencyServerName=$(echo "${realityLatencyItem}" | awk -F "[|]" '{print $2}')
                realityLatencyPort=$(echo "${realityLatencyItem}" | awk -F "[|]" '{print $3}')
                echoContent green " ${realityLatencyIndex}. ${realityLatencyServerName}:${realityLatencyPort} - ${realityLatency} ms"
                if [[ "${realityLatencyIndex}" == "1" ]]; then
                    fastestRealityServerName="${realityLatencyServerName}"
                    fastestRealityTargetPort="${realityLatencyPort}"
                fi
                ((realityLatencyIndex++))
            done
            read -r -p "是否按最快速度伪装？[回车默认y]:" useFastestRealityDomainStatus
            if [[ -z "${useFastestRealityDomainStatus}" ]]; then
                useFastestRealityDomainStatus="y"
            fi
            normalizeYesNoInput useFastestRealityDomainStatus
            if [[ "${useFastestRealityDomainStatus}" == "y" ]]; then
                reality_server_name="${fastestRealityServerName}"
                reality_target_port="${fastestRealityTargetPort}"
            else
                read -r -p "请输入要使用的编号，[回车]继续手动输入:" selectRealityDomainIndex
                if [[ -n "${selectRealityDomainIndex}" && "${selectRealityDomainIndex}" =~ ^[0-9]+$ ]] && [[ "${selectRealityDomainIndex}" -ge 1 ]] && [[ "${selectRealityDomainIndex}" -le ${#realityLatencyList[@]} ]]; then
                    selectedRealityDomain="${realityLatencyList[$((selectRealityDomainIndex - 1))]}"
                    reality_server_name=$(echo "${selectedRealityDomain}" | awk -F "[|]" '{print $2}')
                    reality_target_port=$(echo "${selectedRealityDomain}" | awk -F "[|]" '{print $3}')
                fi
            fi
        fi
    fi

    if [[ -n "${reality_server_name}" ]]; then
        read -r -p "请输入目标域名覆盖当前结果，[回车]直接使用当前结果:" realityCustomServerName
    else
        read -r -p "请输入目标域名，[回车]随机域名，默认端口443:" realityCustomServerName
    fi

    if [[ -n "${realityCustomServerName}" ]]; then
        reality_server_name="${realityCustomServerName}"
        reality_target_port="443"
    fi

    if [[ -z "${reality_server_name}" ]]; then
        count=$(echo "${realityDomainList}" | awk -F',' '{print NF}')
        randomIdx=$(((RANDOM % count) + 1))
        reality_server_name=$(echo "${realityDomainList}" | awk -F ',' -v randomIdx="${randomIdx}" '{print $randomIdx}')
        reality_target_port="443"
    fi

    if echo "${reality_server_name}" | grep -q ":"; then
        reality_target_port=$(echo "${reality_server_name}" | awk -F "[:]" '{print $2}')
        reality_server_name=$(echo "${reality_server_name}" | awk -F "[:]" '{print $1}')
    fi
}

assignDefaultPortsAndPaths() {
    [[ -z "${vless_tcp_port}" ]] && vless_tcp_port="$(randomPort)"
    [[ -z "${vless_ws_port}" ]] && vless_ws_port="$(randomPort)"
    [[ -z "${vmess_ws_port}" ]] && vmess_ws_port="$(randomPort)"
    [[ -z "${trojan_port}" ]] && trojan_port="$(randomPort)"
    [[ -z "${hysteria2_port}" ]] && hysteria2_port="$(randomPort)"
    [[ -z "${reality_vision_port}" ]] && reality_vision_port="$(randomPort)"
    [[ -z "${reality_grpc_port}" ]] && reality_grpc_port="$(randomPort)"
    [[ -z "${tuic_port}" ]] && tuic_port="$(randomPort)"
    [[ -z "${naive_port}" ]] && naive_port="$(randomPort)"
    [[ -z "${vmess_httpupgrade_port}" ]] && vmess_httpupgrade_port="$(randomPort)"
    [[ -z "${reality_xhttp_port}" ]] && reality_xhttp_port="$(randomPort)"
    [[ -z "${anytls_port}" ]] && anytls_port="$(randomPort)"
    [[ -z "${subscribe_port}" ]] && subscribe_port="$(randomPort)"
    [[ -z "${current_path}" ]] && current_path="$(initRandomPath)"
    [[ -z "${xhttp_path}" ]] && xhttp_path="$(initRandomPath)"
}

promptBaseInstallSettings() {
    local inputValue=""
    assignDefaultPortsAndPaths

    if protocolSelectionRequiresTLS; then
        read -r -p "请输入 TLS 域名/currentHost:" inputValue
        if [[ -n "${inputValue}" ]]; then
            current_host="${inputValue}"
        fi
        if [[ -z "${current_host}" ]]; then
            echoContent red "TLS 协议至少需要一个域名"
            return 1
        fi

        if [[ ! -f "${PROJECT_ROOT}/tls/${current_host}.crt" || ! -f "${PROJECT_ROOT}/tls/${current_host}.key" ]]; then
            read -r -p "检测到未导入 TLS 证书，是否尝试导入本地证书？[回车默认y]:" inputValue
            if [[ -z "${inputValue}" ]]; then
                inputValue="y"
            fi
            normalizeYesNoInput inputValue
            if [[ "${inputValue}" == "y" ]]; then
                installLocalTLS "${current_host}" || true
            fi
        fi

        if [[ ! -f "${PROJECT_ROOT}/tls/${current_host}.crt" || ! -f "${PROJECT_ROOT}/tls/${current_host}.key" ]]; then
            echoContent red "未检测到可用本地证书，请先准备证书后再继续"
            return 1
        fi

        tls_cert_file="${PROJECT_ROOT}/tls/${current_host}.crt"
        tls_key_file="${PROJECT_ROOT}/tls/${current_host}.key"
    fi

    if protocolSelectionHasReality; then
        promptRealityServerName
        if [[ -z "${reality_private_key}" || -z "${reality_public_key}" ]]; then
            generateRealityKeypair || {
                echoContent red "生成 Reality 密钥失败"
                return 1
            }
        fi
    fi

    if containsProtocol "1" || containsProtocol "3" || containsProtocol "11"; then
        read -r -p "请输入基础路径 [回车默认 ${current_path}]:" inputValue
        if [[ -n "${inputValue}" ]]; then
            current_path="${inputValue#/}"
        fi
    fi

    if containsProtocol "12"; then
        read -r -p "请输入 XHTTP 基础路径 [回车默认 ${xhttp_path}]:" inputValue
        if [[ -n "${inputValue}" ]]; then
            xhttp_path="${inputValue#/}"
        fi
    fi

    read -r -p "请输入订阅端口 [回车默认 ${subscribe_port}]:" inputValue
    if [[ -n "${inputValue}" ]]; then
        subscribe_port="${inputValue}"
    fi

    if protocolSelectionRequiresTLS; then
        read -r -p "订阅是否使用 https ？[回车默认y]:" inputValue
        if [[ -z "${inputValue}" ]]; then
            inputValue="y"
        fi
        normalizeYesNoInput inputValue
        if [[ "${inputValue}" == "y" ]]; then
            subscribe_type="https"
        else
            subscribe_type="http"
        fi
    else
        subscribe_type="http"
    fi

    return 0
}

getPublicIP() {
    local currentIP=""
    if commandExists curl; then
        currentIP=$(curl -fsS https://api.ipify.org 2>/dev/null || true)
    fi
    if [[ -z "${currentIP}" ]]; then
        currentIP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    printf '%s' "${currentIP}"
}

urlEncode() {
    python3 - "$1" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
}

buildVmessLink() {
    local host="$1"
    local port="$2"
    local uuid="$3"
    local ps="$4"
    local net="$5"
    local path="$6"
    local tlsHost="$7"
    python3 - "${host}" "${port}" "${uuid}" "${ps}" "${net}" "${path}" "${tlsHost}" <<'PY'
import base64, json, sys
host, port, uuid, ps, net, path, tls_host = sys.argv[1:8]
payload = {
    "add": host,
    "aid": 0,
    "host": tls_host,
    "id": uuid,
    "net": net,
    "path": path,
    "port": int(port),
    "ps": ps,
    "tls": "tls",
    "type": "none",
    "v": 2
}
print("vmess://" + base64.b64encode(json.dumps(payload, separators=(",", ":")).encode()).decode())
PY
}

showTerminalQRCode() {
    local qrText="$1"
    if [[ -z "${qrText}" ]]; then
        return 0
    fi
    if commandExists qrencode; then
        echoContent yellow " ---> 终端二维码"
        echo "${qrText}" | qrencode -s 10 -m 1 -t UTF8
    fi
}

writeDefaultFakeSite() {
    cat >"${FAKE_SITE_DIR}/index.html" <<EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${fake_site_title}</title>
  <style>
    body { font-family: Arial, sans-serif; background: #0b1220; color: #e5e7eb; margin: 0; }
    .wrap { max-width: 880px; margin: 80px auto; padding: 32px; }
    .card { background: #111827; border-radius: 16px; padding: 32px; box-shadow: 0 12px 40px rgba(0,0,0,.35); }
    h1 { margin: 0 0 16px; font-size: 32px; }
    p { line-height: 1.7; color: #cbd5e1; }
    .tag { display: inline-block; margin-top: 16px; padding: 8px 12px; border-radius: 999px; background: #1d4ed8; color: #fff; font-size: 14px; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>${fake_site_title}</h1>
      <p>这是由 docker_v2ray_agent.sh 自动生成的伪装站首页。你可以在菜单 8 中切换为自定义标题页或覆盖为你自己的 index.html。</p>
      <span class="tag">telegram:@wbowen</span>
    </div>
  </div>
</body>
</html>
EOF
}

writeComposeScaffold() {
    local includeXray="false"
    local includeSingBox="false"
    if containsProtocol "12"; then
        includeXray="true"
    fi
    local protocolId
    for protocolId in 0 1 3 4 6 7 8 9 10 11 13; do
        if containsProtocol "${protocolId}"; then
            includeSingBox="true"
            break
        fi
    done

    cat >"${COMPOSE_FILE}" <<EOF
services:
EOF
    if [[ "${includeXray}" == "true" ]]; then
        cat >>"${COMPOSE_FILE}" <<EOF
  xray:
    image: ghcr.io/xtls/xray-core:26.5.9
    container_name: v2ray-agent-xray
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/xray/conf:/etc/xray:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${PROJECT_ROOT}/logs:/var/log/v2ray-agent
    command: ["run", "-c", "/etc/xray/config.json"]

EOF
    fi
    if [[ "${includeSingBox}" == "true" ]]; then
        cat >>"${COMPOSE_FILE}" <<EOF
  sing-box:
    image: ghcr.io/sagernet/sing-box:latest
    container_name: v2ray-agent-sing-box
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/sing-box/conf:/etc/sing-box:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${PROJECT_ROOT}/logs:/var/log/v2ray-agent
    command: ["run", "-c", "/etc/sing-box/config.json"]

EOF
    fi
    cat >>"${COMPOSE_FILE}" <<EOF
  nginx:
    image: nginx:alpine
    container_name: v2ray-agent-nginx
    restart: unless-stopped
    network_mode: host
    volumes:
      - ${PROJECT_ROOT}/nginx/conf.d:/etc/nginx/conf.d:ro
      - ${PROJECT_ROOT}/tls:/etc/v2ray-agent/tls:ro
      - ${FAKE_SITE_DIR}:/usr/share/nginx/html/site:ro
      - ${PROJECT_ROOT}/subscribe:/usr/share/nginx/html/subscribe:ro
      - ${PROJECT_ROOT}/logs:/var/log/nginx
EOF
}

writeNginxSubscribeConf() {
    local subscribeServerName="_"
    local sslConfig=""
    local listenDirective="${subscribe_port}"
    if [[ -n "${current_host}" ]]; then
        subscribeServerName="${current_host}"
    fi
    if [[ "${subscribe_type}" == "https" && -n "${current_host}" ]]; then
        listenDirective="${subscribe_port} ssl"
        sslConfig="ssl_certificate /etc/v2ray-agent/tls/${current_host}.crt; ssl_certificate_key /etc/v2ray-agent/tls/${current_host}.key;"
    fi
    cat >"${NGINX_SUBSCRIBE_FILE}" <<EOF
server {
    listen ${listenDirective};
    server_name ${subscribeServerName};
    ${sslConfig}
    root /usr/share/nginx/html/site;
    index index.html;
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    location /s/ {
        alias /usr/share/nginx/html/subscribe/;
        autoindex off;
    }
}
EOF
}

generateProtocolConfigs() {
    ensureUsersFile
    mkdir -p "$(dirname "${SINGBOX_CONFIG_FILE}")" "$(dirname "${XRAY_CONFIG_FILE}")"
    python3 - "${USERS_FILE}" "${SINGBOX_CONFIG_FILE}" "${XRAY_CONFIG_FILE}" <<'PY'
import json, os, sys

users_file, singbox_path, xray_path = sys.argv[1:4]
with open(users_file, 'r', encoding='utf-8') as fh:
    users = json.load(fh)

ids = [x for x in os.environ.get("selected_protocol_ids", "").split(",") if x]
idset = set(ids)
current_host = os.environ.get("current_host", "")
current_path = os.environ.get("current_path", "")
xhttp_path = os.environ.get("xhttp_path", "")
subscribe_port = os.environ.get("subscribe_port", "")
reality_server_name = os.environ.get("reality_server_name", "")
reality_target_port = int(os.environ.get("reality_target_port", "443") or "443")
reality_private_key = os.environ.get("reality_private_key", "")
reality_public_key = os.environ.get("reality_public_key", "")
reality_short_id = os.environ.get("reality_short_id", "6ba85179e30d4fc2")
hysteria2_up = int(os.environ.get("hysteria2_up_mbps", "1000"))
hysteria2_down = int(os.environ.get("hysteria2_down_mbps", "1000"))
tuic_cc = os.environ.get("tuic_congestion_control", "bbr")

def get_port(name):
    return int(os.environ.get(name, "0") or "0")

def tls_block(host):
    return {
        "enabled": True,
        "server_name": host,
        "certificate_path": f"/etc/v2ray-agent/tls/{host}.crt" if host else "",
        "key_path": f"/etc/v2ray-agent/tls/{host}.key" if host else ""
    }

def vless_users(flow=None):
    result = []
    for item in users:
        user = {"name": item["email"], "uuid": item["uuid"]}
        if flow:
            user["flow"] = flow
        result.append(user)
    return result

def vmess_users():
    return [{"name": item["email"], "uuid": item["uuid"]} for item in users]

def password_users(key="password"):
    result = []
    for item in users:
        result.append({"name": item["email"], "password": item.get(key, item["uuid"])})
    return result

sing_inbounds = []
xray_inbounds = []

if "0" in idset:
    sing_inbounds.append({
        "type": "vless",
        "tag": "VLESS_TCP_TLS_VISION",
        "listen": "::",
        "listen_port": get_port("vless_tcp_port"),
        "users": vless_users("xtls-rprx-vision"),
        "tls": tls_block(current_host)
    })

if "1" in idset:
    item = {
        "type": "vless",
        "tag": "VLESS_WS_TLS",
        "listen": "::",
        "listen_port": get_port("vless_ws_port"),
        "users": vless_users(),
        "transport": {"type": "ws", "path": f"/{current_path}ws"},
        "tls": tls_block(current_host)
    }
    sing_inbounds.append(item)

if "3" in idset:
    item = {
        "type": "vmess",
        "tag": "VMESS_WS_TLS",
        "listen": "::",
        "listen_port": get_port("vmess_ws_port"),
        "users": vmess_users(),
        "transport": {"type": "ws", "path": f"/{current_path}vws"},
        "tls": tls_block(current_host)
    }
    sing_inbounds.append(item)

if "4" in idset:
    sing_inbounds.append({
        "type": "trojan",
        "tag": "TROJAN_TCP_TLS",
        "listen": "::",
        "listen_port": get_port("trojan_port"),
        "users": password_users(),
        "tls": tls_block(current_host)
    })

if "6" in idset:
    sing_inbounds.append({
        "type": "hysteria2",
        "tag": "HYSTERIA2",
        "listen": "::",
        "listen_port": get_port("hysteria2_port"),
        "users": password_users(),
        "up_mbps": hysteria2_up,
        "down_mbps": hysteria2_down,
        "tls": {
            **tls_block(current_host),
            "alpn": ["h3"]
        }
    })

if "7" in idset:
    sing_inbounds.append({
        "type": "vless",
        "tag": "VLESS_REALITY_VISION",
        "listen": "::",
        "listen_port": get_port("reality_vision_port"),
        "users": vless_users("xtls-rprx-vision"),
        "tls": {
            "enabled": True,
            "server_name": reality_server_name,
            "reality": {
                "enabled": True,
                "private_key": reality_private_key,
                "handshake": {"server": reality_server_name, "server_port": reality_target_port},
                "short_id": [reality_short_id]
            }
        }
    })

if "8" in idset:
    sing_inbounds.append({
        "type": "vless",
        "tag": "VLESS_REALITY_GRPC",
        "listen": "::",
        "listen_port": get_port("reality_grpc_port"),
        "users": vless_users(),
        "transport": {"type": "grpc", "service_name": "grpc"},
        "tls": {
            "enabled": True,
            "server_name": reality_server_name,
            "reality": {
                "enabled": True,
                "private_key": reality_private_key,
                "handshake": {"server": reality_server_name, "server_port": reality_target_port},
                "short_id": [reality_short_id]
            }
        }
    })

if "9" in idset:
    sing_inbounds.append({
        "type": "tuic",
        "tag": "TUIC",
        "listen": "::",
        "listen_port": get_port("tuic_port"),
        "users": [{"name": i["email"], "uuid": i["uuid"], "password": i["tuic_password"]} for i in users],
        "congestion_control": tuic_cc,
        "tls": {
            **tls_block(current_host),
            "alpn": ["h3"]
        }
    })

if "10" in idset:
    sing_inbounds.append({
        "type": "naive",
        "tag": "NAIVE",
        "listen": "::",
        "listen_port": get_port("naive_port"),
        "users": [{"username": i["email"], "password": i["password"]} for i in users],
        "tls": tls_block(current_host)
    })

if "11" in idset:
    sing_inbounds.append({
        "type": "vmess",
        "tag": "VMESS_HTTPUPGRADE",
        "listen": "::",
        "listen_port": get_port("vmess_httpupgrade_port"),
        "users": vmess_users(),
        "transport": {"type": "httpupgrade", "path": f"/{current_path}"},
        "tls": tls_block(current_host)
    })

if "13" in idset:
    sing_inbounds.append({
        "type": "anytls",
        "tag": "ANYTLS",
        "listen": "::",
        "listen_port": get_port("anytls_port"),
        "users": password_users(),
        "tls": tls_block(current_host)
    })

if "12" in idset:
    xray_users = [{"id": i["uuid"], "email": i["email"]} for i in users]
    xray_inbounds.append({
        "port": get_port("reality_xhttp_port"),
        "listen": "0.0.0.0",
        "protocol": "vless",
        "tag": "VLESSRealityXHTTP",
        "settings": {"clients": xray_users, "decryption": "none"},
        "streamSettings": {
            "network": "xhttp",
            "security": "reality",
            "realitySettings": {
                "show": False,
                "target": f"{reality_server_name}:{reality_target_port}",
                "xver": 0,
                "serverNames": [reality_server_name],
                "privateKey": reality_private_key,
                "publicKey": reality_public_key,
                "maxTimeDiff": 70000,
                "shortIds": ["", reality_short_id]
            },
            "xhttpSettings": {
                "host": reality_server_name,
                "path": f"/{xhttp_path}xHTTP",
                "mode": "auto"
            }
        }
    })

sing_config = {
    "log": {"level": "info"},
    "inbounds": sing_inbounds,
    "outbounds": [
        {"type": "direct", "tag": "direct"},
        {"type": "block", "tag": "block"}
    ]
}

xray_config = {
    "log": {"loglevel": "warning"},
    "inbounds": xray_inbounds,
    "outbounds": [
        {"protocol": "freedom", "tag": "direct"},
        {"protocol": "blackhole", "tag": "block"}
    ]
}

with open(singbox_path, 'w', encoding='utf-8') as fh:
    json.dump(sing_config, fh, ensure_ascii=False, indent=2)
with open(xray_path, 'w', encoding='utf-8') as fh:
    json.dump(xray_config, fh, ensure_ascii=False, indent=2)
PY
}

buildDefaultLinksForUser() {
    local userEmail="$1"
    local userUUID="$2"
    local userPassword="$3"
    local userTuicPassword="$4"
    local host="${current_host}"
    local publicIP
    publicIP="$(getPublicIP)"
    if [[ -z "${host}" ]]; then
        host="${publicIP}"
    fi

    if containsProtocol "0"; then
        echo "vless://${userUUID}@${host}:${vless_tcp_port}?encryption=none&security=tls&type=tcp&sni=${host}&flow=xtls-rprx-vision#${userEmail}-VLESS_TCP_TLS_Vision"
    fi
    if containsProtocol "1"; then
        echo "vless://${userUUID}@${host}:${vless_ws_port}?encryption=none&security=tls&type=ws&host=${host}&path=%2F${current_path}ws&sni=${host}#${userEmail}-VLESS_WS_TLS"
    fi
    if containsProtocol "3"; then
        buildVmessLink "${host}" "${vmess_ws_port}" "${userUUID}" "${userEmail}-VMess_WS_TLS" "ws" "/${current_path}vws" "${host}"
    fi
    if containsProtocol "4"; then
        echo "trojan://${userPassword}@${host}:${trojan_port}?sni=${host}&type=tcp#${userEmail}-Trojan_TLS"
    fi
    if containsProtocol "6"; then
        local hysteriaDisplayPort="${hysteria2_port}"
        if [[ -n "${hysteria2_port_hopping}" ]]; then
            hysteriaDisplayPort="${hysteria2_port_hopping}"
        fi
        echo "hysteria2://${userPassword}@${host}:${hysteriaDisplayPort}?peer=${host}&insecure=0&sni=${host}&alpn=h3#${userEmail}-Hysteria2"
    fi
    if containsProtocol "7"; then
        echo "vless://${userUUID}@${publicIP}:${reality_vision_port}?encryption=none&security=reality&type=tcp&sni=${reality_server_name}&fp=chrome&pbk=${reality_public_key}&sid=${reality_short_id}&flow=xtls-rprx-vision#${userEmail}-Reality_Vision"
    fi
    if containsProtocol "8"; then
        echo "vless://${userUUID}@${publicIP}:${reality_grpc_port}?encryption=none&security=reality&type=grpc&sni=${reality_server_name}&serviceName=grpc&fp=chrome&pbk=${reality_public_key}&sid=${reality_short_id}#${userEmail}-Reality_gRPC"
    fi
    if containsProtocol "9"; then
        local tuicDisplayPort="${tuic_port}"
        if [[ -n "${tuic_port_hopping}" ]]; then
            tuicDisplayPort="${tuic_port_hopping}"
        fi
        echo "tuic://${userUUID}:${userTuicPassword}@${host}:${tuicDisplayPort}?congestion_control=${tuic_congestion_control}&alpn=h3&sni=${host}&udp_relay_mode=quic#${userEmail}-Tuic"
    fi
    if containsProtocol "10"; then
        echo "naive+https://${userEmail}:${userPassword}@${host}:${naive_port}#${userEmail}-Naive"
    fi
    if containsProtocol "11"; then
        buildVmessLink "${host}" "${vmess_httpupgrade_port}" "${userUUID}" "${userEmail}-VMess_HTTPUpgrade" "httpupgrade" "/${current_path}" "${host}"
    fi
    if containsProtocol "12"; then
        echo "vless://${userUUID}@${publicIP}:${reality_xhttp_port}?encryption=none&security=reality&type=xhttp&sni=${reality_server_name}&host=${reality_server_name}&path=%2F${xhttp_path}xHTTP&fp=chrome&pbk=${reality_public_key}&sid=${reality_short_id}#${userEmail}-Reality_XHTTP"
    fi
    if containsProtocol "13"; then
        echo "anytls://${userPassword}@${host}:${anytls_port}?peer=${host}&insecure=0&sni=${host}#${userEmail}-AnyTLS"
    fi
}

regenerateSubscriptions() {
    ensureUsersFile
    ensureProjectDirs
    if [[ ! -f "${SUBSCRIBE_SALT_FILE}" ]]; then
        echo "$(initRandomPath)$(initRandomPath)" >"${SUBSCRIBE_SALT_FILE}"
    fi
    local subscribeSalt
    subscribeSalt="$(cat "${SUBSCRIBE_SALT_FILE}")"
    rm -f "${PROJECT_ROOT}/subscribe/default/"* 2>/dev/null || true
    rm -f "${PROJECT_ROOT}/subscribe/clashMeta/"* 2>/dev/null || true
    rm -f "${PROJECT_ROOT}/subscribe/clashMetaProfiles/"* 2>/dev/null || true
    rm -f "${PROJECT_ROOT}/subscribe/sing-box/"* 2>/dev/null || true
    rm -f "${PROJECT_ROOT}/subscribe/sing-box_profiles/"* 2>/dev/null || true

    while IFS= read -r userEntry; do
        local userEmail="${userEntry%%,*}"
        local userUUID="${userEntry##*,}"
        local userPassword="${userUUID}"
        local userTuicPassword="${userUUID//-/}"
        local emailMd5
        local defaultLinks
        emailMd5=$(echo -n "${userEmail}$(cat "${SUBSCRIBE_SALT_FILE}")" | md5sum | awk '{print $1}')
        defaultLinks="$(buildDefaultLinksForUser "${userEmail}" "${userUUID}" "${userPassword}" "${userTuicPassword}")"
        printf '%s\n' "${defaultLinks}" | sed '/^$/d' | base64 -w 0 >"${PROJECT_ROOT}/subscribe/default/${emailMd5}"
        cat >"${PROJECT_ROOT}/subscribe/clashMetaProfiles/${emailMd5}" <<EOF
mixed-port: 7890
allow-lan: true
mode: rule
log-level: info
proxies: []
proxy-groups:
  - name: 手动切换
    type: select
    proxies:
      - DIRECT
rules:
  - MATCH,手动切换
EOF
        cat >"${PROJECT_ROOT}/subscribe/sing-box/${emailMd5}" <<EOF
{
  "outbounds": [],
  "route": {
    "auto_detect_interface": true
  }
}
EOF
    done < <(listUsers | awk -F '[:,]' '{print $2","$3}')
}

startDockerStack() {
    ${compose_command} -f "${COMPOSE_FILE}" down >/dev/null 2>&1 || true
    ${compose_command} -f "${COMPOSE_FILE}" up -d >/dev/null 2>&1 || {
        echoContent red "Docker 栈启动失败"
        return 1
    }
    stack_status="installed"
    saveState
    return 0
}

rebuildDockerStack() {
    ensureProjectDirs
    createInitialUserIfMissing
    if [[ ! -f "${FAKE_SITE_DIR}/index.html" || "${fake_site_mode}" == "default" || "${fake_site_mode}" == "custom_title" ]]; then
        writeDefaultFakeSite
    fi
    selected_protocol_names="$(joinSelectedProtocolNames "${selected_protocol_ids}")"
    writeComposeScaffold
    writeNginxSubscribeConf
    generateProtocolConfigs
    regenerateSubscriptions
    writeMigrationManifest
    saveState
    startDockerStack
}

showSubscribeLinks() {
    local userEntry
    local emailMd5
    local subscribeHost
    local subscribeSalt
    local defaultSubscribeUrl
    local clashMetaSubscribeUrl
    local singBoxSubscribeUrl
    subscribeSalt="$(cat "${SUBSCRIBE_SALT_FILE}" 2>/dev/null)"
    subscribeHost="${current_host}"
    if [[ -z "${subscribeHost}" ]]; then
        subscribeHost="$(getPublicIP)"
    fi
    while IFS= read -r userEntry; do
        local userEmail="${userEntry%%,*}"
        emailMd5=$(echo -n "${userEmail}${subscribeSalt}" | md5sum | awk '{print $1}')
        defaultSubscribeUrl="${subscribe_type}://${subscribeHost}:${subscribe_port}/s/default/${emailMd5}"
        clashMetaSubscribeUrl="${subscribe_type}://${subscribeHost}:${subscribe_port}/s/clashMetaProfiles/${emailMd5}"
        singBoxSubscribeUrl="${subscribe_type}://${subscribeHost}:${subscribe_port}/s/sing-box/${emailMd5}"
        echoContent skyBlue "\n----------默认订阅----------\n"
        showContactInfo
        echoContent yellow "url:${defaultSubscribeUrl}"
        echoContent yellow "在线二维码:https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$(urlEncode "${defaultSubscribeUrl}")"
        showTerminalQRCode "${defaultSubscribeUrl}"
        echoContent skyBlue "\n----------clashMeta订阅----------\n"
        echoContent yellow "url:${clashMetaSubscribeUrl}"
        echoContent yellow "在线二维码:https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$(urlEncode "${clashMetaSubscribeUrl}")"
        showTerminalQRCode "${clashMetaSubscribeUrl}"
        echoContent skyBlue "\n----------sing-box订阅----------\n"
        echoContent yellow "url:${singBoxSubscribeUrl}"
        echoContent yellow "在线二维码:https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$(urlEncode "${singBoxSubscribeUrl}")"
        showTerminalQRCode "${singBoxSubscribeUrl}"
    done < <(listUsers | awk -F '[:,]' '{print $2","$3}')
}

showAccounts() {
    local userEntry
    while IFS= read -r userEntry; do
        local userEmail="${userEntry%%,*}"
        local userUUID="${userEntry##*,}"
        local userPassword="${userUUID}"
        local userTuicPassword="${userUUID//-/}"
        local nodeLink
        echoContent skyBlue "\n============================= ${userEmail} =============================="
        showContactInfo
        while IFS= read -r nodeLink; do
            [[ -z "${nodeLink}" ]] && continue
            echoContent green "${nodeLink}"
            echoContent yellow "在线二维码:https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=$(urlEncode "${nodeLink}")"
            showTerminalQRCode "${nodeLink}"
        done < <(buildDefaultLinksForUser "${userEmail}" "${userUUID}" "${userPassword}" "${userTuicPassword}")
    done < <(listUsers | awk -F '[:,]' '{print $2","$3}')
    showSubscribeLinks
}

addUser() {
    local addCount=1
    local idx=1
    local newUUID
    local newEmail
    read -r -p "请输入要添加的用户数量 [回车默认1]:" addCount
    [[ -z "${addCount}" ]] && addCount=1
    while [[ "${idx}" -le "${addCount}" ]]; do
        newUUID="$(generateUUID)"
        newEmail="${newUUID%%-*}"
        createUserRecord "${newEmail}" "${newUUID}"
        ((idx++))
    done
    rebuildDockerStack
    echoContent green " ---> 用户添加完成"
}

removeUser() {
    local userEntry
    local delIndex=""
    echoContent yellow "当前用户列表:"
    while IFS= read -r userEntry; do
        echoContent green "${userEntry}"
    done < <(listUsers)
    read -r -p "请输入要删除的用户编号:" delIndex
    if [[ -z "${delIndex}" ]]; then
        return 0
    fi
    removeUserRecord "${delIndex}"
    rebuildDockerStack
    echoContent green " ---> 用户删除完成"
}

manageAccountMenu() {
    echoContent red "=============================================================="
    echoContent yellow "1.查看账号"
    echoContent yellow "2.查看订阅"
    echoContent yellow "3.添加用户"
    echoContent yellow "4.删除用户"
    echoContent red "=============================================================="
    read -r -p "请输入:" manageAccountStatus
    case "${manageAccountStatus}" in
    1)
        showAccounts
        ;;
    2)
        showSubscribeLinks
        ;;
    3)
        addUser
        ;;
    4)
        removeUser
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

manageTLSMenu() {
    local tlsMenuStatus=""
    local inputDomain=""
    echoContent red "=============================================================="
    echoContent yellow "1.导入本地证书"
    echoContent yellow "2.查看当前证书"
    echoContent red "=============================================================="
    read -r -p "请选择:" tlsMenuStatus
    case "${tlsMenuStatus}" in
    1)
        read -r -p "请输入要导入的证书域名:" inputDomain
        [[ -z "${inputDomain}" ]] && inputDomain="${current_host}"
        if installLocalTLS "${inputDomain}"; then
            current_host="${inputDomain}"
            saveState
            rebuildDockerStack
        else
            echoContent red " ---> 未找到可导入的本地证书"
        fi
        ;;
    2)
        echoContent yellow "证书文件:${tls_cert_file}"
        echoContent yellow "私钥文件:${tls_key_file}"
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

allowUdpRangePort() {
    local rangeValue="$1"
    if commandExists firewall-cmd && systemctl is-active firewalld >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port="${rangeValue}/udp" >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
    fi
}

removeUdpRangePort() {
    local rangeValue="$1"
    if commandExists firewall-cmd && systemctl is-active firewalld >/dev/null 2>&1; then
        firewall-cmd --permanent --remove-port="${rangeValue}/udp" >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
    fi
}

getPortHoppingValue() {
    local protocolType="$1"
    if [[ "${protocolType}" == "hysteria2" ]]; then
        printf '%s' "${hysteria2_port_hopping}"
    else
        printf '%s' "${tuic_port_hopping}"
    fi
}

setPortHoppingValue() {
    local protocolType="$1"
    local rangeValue="$2"
    if [[ "${protocolType}" == "hysteria2" ]]; then
        hysteria2_port_hopping="${rangeValue}"
    else
        tuic_port_hopping="${rangeValue}"
    fi
}

clearPortHoppingValue() {
    local protocolType="$1"
    if [[ "${protocolType}" == "hysteria2" ]]; then
        hysteria2_port_hopping=""
    else
        tuic_port_hopping=""
    fi
}

getProtocolTargetPort() {
    local protocolType="$1"
    if [[ "${protocolType}" == "hysteria2" ]]; then
        printf '%s' "${hysteria2_port}"
    else
        printf '%s' "${tuic_port}"
    fi
}

validatePortHoppingRange() {
    local rangeValue="$1"
    local startPort="${rangeValue%%:*}"
    local endPort="${rangeValue##*:}"
    if [[ ! "${startPort}" =~ ^[0-9]+$ || ! "${endPort}" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    if [[ "${startPort}" -ge "${endPort}" ]]; then
        return 1
    fi
    if [[ "${startPort}" -lt 1 || "${endPort}" -gt 65535 ]]; then
        return 1
    fi
    return 0
}

deletePortHoppingRules() {
    local protocolType="$1"
    local targetPort="$2"
    local currentRange
    currentRange="$(getPortHoppingValue "${protocolType}")"
    if [[ -z "${currentRange}" ]]; then
        return 0
    fi
    local commentTag="wbowen123_${protocolType}_portHopping"
    local startPort="${currentRange%%:*}"
    local endPort="${currentRange##*:}"

    if commandExists firewall-cmd && systemctl is-active firewalld >/dev/null 2>&1; then
        local currentPort
        for ((currentPort = startPort; currentPort <= endPort; currentPort++)); do
            firewall-cmd --permanent --remove-forward-port=port="${currentPort}":proto=udp:toport="${targetPort}" >/dev/null 2>&1 || true
        done
        removeUdpRangePort "${currentRange}"
        firewall-cmd --reload >/dev/null 2>&1 || true
    elif commandExists iptables; then
        iptables -t nat -D PREROUTING -p udp --dport "${startPort}:${endPort}" -m comment --comment "${commentTag}" -j DNAT --to-destination ":${targetPort}" >/dev/null 2>&1 || true
    fi
}

applyPortHoppingRules() {
    local protocolType="$1"
    local rangeValue="$2"
    local targetPort="$3"
    local startPort="${rangeValue%%:*}"
    local endPort="${rangeValue##*:}"
    local commentTag="wbowen123_${protocolType}_portHopping"

    if commandExists firewall-cmd && systemctl is-active firewalld >/dev/null 2>&1; then
        local currentPort
        for ((currentPort = startPort; currentPort <= endPort; currentPort++)); do
            firewall-cmd --permanent --add-forward-port=port="${currentPort}":proto=udp:toport="${targetPort}" >/dev/null 2>&1 || true
        done
        allowUdpRangePort "${rangeValue}"
        firewall-cmd --reload >/dev/null 2>&1 || true
        return 0
    fi

    if commandExists iptables; then
        iptables -t nat -A PREROUTING -p udp --dport "${startPort}:${endPort}" -m comment --comment "${commentTag}" -j DNAT --to-destination ":${targetPort}" >/dev/null 2>&1 || return 1
        return 0
    fi

    return 1
}

portHoppingMenu() {
    local protocolType="$1"
    local targetPort
    local currentRange
    local rangeInput=""
    local portHopStatus=""
    targetPort="$(getProtocolTargetPort "${protocolType}")"
    currentRange="$(getPortHoppingValue "${protocolType}")"

    if [[ -z "${targetPort}" ]]; then
        echoContent red " ---> 未检测到 ${protocolType} 监听端口，请先完成安装"
        return 1
    fi

    echoContent red "=============================================================="
    echoContent yellow "1.添加/修改端口跳跃"
    echoContent yellow "2.删除端口跳跃"
    echoContent yellow "3.查看端口跳跃"
    echoContent red "=============================================================="
    read -r -p "请选择:" portHopStatus
    case "${portHopStatus}" in
    1)
        echoContent yellow "默认 UDP 端口跳跃范围为 55000:60000"
        read -r -p "请输入端口跳跃范围 [回车默认 55000:60000]:" rangeInput
        [[ -z "${rangeInput}" ]] && rangeInput="55000:60000"
        if ! validatePortHoppingRange "${rangeInput}"; then
            echoContent red " ---> 端口跳跃范围格式错误，应为 55000:60000"
            return 1
        fi
        deletePortHoppingRules "${protocolType}" "${targetPort}"
        if ! applyPortHoppingRules "${protocolType}" "${rangeInput}" "${targetPort}"; then
            echoContent red " ---> 端口跳跃添加失败，请确认系统存在 firewalld 或 iptables"
            return 1
        fi
        setPortHoppingValue "${protocolType}" "${rangeInput}"
        saveState
        echoContent green " ---> ${protocolType} 端口跳跃添加成功: ${rangeInput} -> ${targetPort}/udp"
        ;;
    2)
        if [[ -z "${currentRange}" ]]; then
            echoContent yellow " ---> 当前未设置端口跳跃"
            return 0
        fi
        deletePortHoppingRules "${protocolType}" "${targetPort}"
        clearPortHoppingValue "${protocolType}"
        saveState
        echoContent green " ---> ${protocolType} 端口跳跃已删除"
        ;;
    3)
        if [[ -n "${currentRange}" ]]; then
            echoContent green " ---> 当前 ${protocolType} 端口跳跃范围: ${currentRange}"
            echoContent green " ---> 实际转发目标端口: ${targetPort}/udp"
        else
            echoContent yellow " ---> 当前未设置端口跳跃"
        fi
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

manageHysteria2Menu() {
    if ! containsProtocol "6"; then
        echoContent red " ---> 当前未安装 Hysteria2"
        return 1
    fi
    portHoppingMenu "hysteria2"
}

manageTuicMenu() {
    if ! containsProtocol "9"; then
        echoContent red " ---> 当前未安装 Tuic"
        return 1
    fi
    portHoppingMenu "tuic"
}

showInstalledProtocolPorts() {
    containsProtocol "0" && echoContent yellow "0. VLESS+TCP[TLS_Vision] : ${vless_tcp_port}"
    containsProtocol "1" && echoContent yellow "1. VLESS+WS[TLS] : ${vless_ws_port}"
    containsProtocol "3" && echoContent yellow "3. VMess+WS[TLS] : ${vmess_ws_port}"
    containsProtocol "4" && echoContent yellow "4. Trojan+TCP[TLS] : ${trojan_port}"
    containsProtocol "6" && echoContent yellow "6. Hysteria2 : ${hysteria2_port}"
    containsProtocol "6" && [[ -n "${hysteria2_port_hopping}" ]] && echoContent green "   Hysteria2 端口跳跃: ${hysteria2_port_hopping}"
    containsProtocol "7" && echoContent yellow "7. VLESS+Reality+Vision : ${reality_vision_port}"
    containsProtocol "8" && echoContent yellow "8. VLESS+Reality+gRPC : ${reality_grpc_port}"
    containsProtocol "9" && echoContent yellow "9. Tuic : ${tuic_port}"
    containsProtocol "9" && [[ -n "${tuic_port_hopping}" ]] && echoContent green "   Tuic 端口跳跃: ${tuic_port_hopping}"
    containsProtocol "10" && echoContent yellow "10. Naive : ${naive_port}"
    containsProtocol "11" && echoContent yellow "11. VMess+TLS+HTTPUpgrade : ${vmess_httpupgrade_port}"
    containsProtocol "12" && echoContent yellow "12. VLESS+Reality+XHTTP : ${reality_xhttp_port}"
    containsProtocol "13" && echoContent yellow "13. AnyTLS : ${anytls_port}"
    echoContent yellow "s. 订阅端口 : ${subscribe_port}"
}

setProtocolPortByChoice() {
    local protocolChoice="$1"
    local newPort="$2"
    case "${protocolChoice}" in
    0) vless_tcp_port="${newPort}" ;;
    1) vless_ws_port="${newPort}" ;;
    3) vmess_ws_port="${newPort}" ;;
    4) trojan_port="${newPort}" ;;
    6) hysteria2_port="${newPort}" ;;
    7) reality_vision_port="${newPort}" ;;
    8) reality_grpc_port="${newPort}" ;;
    9) tuic_port="${newPort}" ;;
    10) naive_port="${newPort}" ;;
    11) vmess_httpupgrade_port="${newPort}" ;;
    12) reality_xhttp_port="${newPort}" ;;
    13) anytls_port="${newPort}" ;;
    s | S) subscribe_port="${newPort}" ;;
    *) return 1 ;;
    esac
    return 0
}

addNewPortMenu() {
    local protocolChoice=""
    local newPort=""
    echoContent red "=============================================================="
    echoContent yellow "当前已安装协议端口如下："
    showInstalledProtocolPorts
    echoContent red "=============================================================="
    read -r -p "请输入要修改端口的协议编号:" protocolChoice
    read -r -p "请输入新的端口:" newPort
    if [[ -z "${newPort}" || ! "${newPort}" =~ ^[0-9]+$ ]]; then
        echoContent red " ---> 端口输入错误"
        return 1
    fi
    setProtocolPortByChoice "${protocolChoice}" "${newPort}" || {
        echoContent red " ---> 未识别的协议编号"
        return 1
    }
    saveState
    rebuildDockerStack
    echoContent green " ---> 端口已更新并重建 Docker 栈"
}

manageFakeSiteMenu() {
    local siteMenuStatus=""
    local customTitle=""
    local sourceFile=""
    echoContent red "=============================================================="
    echoContent yellow "1.使用默认伪装站"
    echoContent yellow "2.自定义站点标题"
    echoContent yellow "3.导入当前目录 index.html"
    echoContent yellow "4.查看站点目录"
    echoContent red "=============================================================="
    read -r -p "请选择:" siteMenuStatus
    case "${siteMenuStatus}" in
    1)
        fake_site_mode="default"
        writeDefaultFakeSite
        saveState
        rebuildDockerStack
        echoContent green " ---> 默认伪装站已启用"
        ;;
    2)
        read -r -p "请输入新的站点标题:" customTitle
        [[ -z "${customTitle}" ]] && customTitle="Welcome"
        fake_site_title="${customTitle}"
        fake_site_mode="custom_title"
        writeDefaultFakeSite
        saveState
        rebuildDockerStack
        echoContent green " ---> 自定义标题伪装站已更新"
        ;;
    3)
        sourceFile="${PWD}/index.html"
        if [[ ! -f "${sourceFile}" ]]; then
            echoContent red " ---> 当前目录未找到 index.html"
            return 1
        fi
        cp "${sourceFile}" "${FAKE_SITE_DIR}/index.html"
        fake_site_mode="custom_file"
        saveState
        rebuildDockerStack
        echoContent green " ---> 已导入当前目录的 index.html"
        ;;
    4)
        echoContent yellow "站点目录: ${FAKE_SITE_DIR}"
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

showCoreStatus() {
    echoContent skyBlue "========================= Core 状态 ========================="
    if [[ -f "${COMPOSE_FILE}" ]]; then
        ${compose_command} -f "${COMPOSE_FILE}" ps 2>/dev/null || true
    else
        echoContent yellow "尚未生成 Docker Compose 文件"
    fi
    echoContent yellow "xray 配置: ${XRAY_CONFIG_FILE}"
    echoContent yellow "sing-box 配置: ${SINGBOX_CONFIG_FILE}"
    echoContent yellow "nginx 配置: ${NGINX_SUBSCRIBE_FILE}"
}

coreManageMenu() {
    local coreMenuStatus=""
    echoContent red "=============================================================="
    echoContent yellow "1.查看 core 状态"
    echoContent yellow "2.重启 Docker 栈"
    echoContent yellow "3.拉取最新镜像并重建"
    echoContent red "=============================================================="
    read -r -p "请选择:" coreMenuStatus
    case "${coreMenuStatus}" in
    1)
        showCoreStatus
        ;;
    2)
        startDockerStack
        echoContent green " ---> Docker 栈已重启"
        ;;
    3)
        ${compose_command} -f "${COMPOSE_FILE}" pull >/dev/null 2>&1 || {
            echoContent red " ---> 拉取镜像失败"
            return 1
        }
        startDockerStack
        echoContent green " ---> 镜像已更新并重建 Docker 栈"
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

featureReserved() {
    echoContent yellow "该功能入口已在 Docker 八合一总控脚本中预留。"
    echoContent yellow "下一步会按 install.sh 的对应逻辑继续迁移该模块。"
    echo
}

showProtocolSelectionHelp() {
    local idx
    echoContent red "=============================================================="
    for idx in "${!ALL_PROTOCOL_IDS[@]}"; do
        echoContent yellow "${ALL_PROTOCOL_IDS[$idx]}. ${ALL_PROTOCOL_NAMES[$idx]}"
    done
    echoContent red "=============================================================="
}

prepareDockerStackScaffold() {
    ensureProjectDirs
    writeComposeScaffold
    writeMigrationManifest
    stack_status="scaffolded"
    state_created_at="$(date '+%Y-%m-%d %H:%M:%S')"
    selected_protocol_names="$(joinSelectedProtocolNames "${selected_protocol_ids}")"
    saveState
    echoContent green "Docker 八合一目录骨架已生成：${PROJECT_ROOT}"
    echoContent green "Compose 骨架已生成：${COMPOSE_FILE}"
    echoContent green "迁移清单已生成：${MANIFEST_FILE}"
}

installFullStack() {
    install_mode="full"
    core_stack="hybrid"
    selected_protocol_ids="$(IFS=,; echo "${ALL_PROTOCOL_IDS[*]}")"
    promptBaseInstallSettings || return 1
    prepareDockerStackScaffold
    rebuildDockerStack || return 1
    echoContent green "已完成八合一全量 Docker 安装"
    showAccounts
}

installCustomStack() {
    local customSelection=""
    showProtocolSelectionHelp
    read -r -p "请输入要安装的协议编号，多个用逗号分隔:" customSelection
    customSelection="${customSelection// /}"
    if [[ -z "${customSelection}" ]]; then
        echoContent red "未输入任何协议编号"
        return 1
    fi
    install_mode="custom"
    core_stack="hybrid"
    selected_protocol_ids="${customSelection}"
    promptBaseInstallSettings || return 1
    prepareDockerStackScaffold
    rebuildDockerStack || return 1
    echoContent green "已完成自定义 Docker 协议安装"
    showAccounts
}

findRealityScript() {
    if [[ -f "${REALITY_SCRIPT_TARGET}" ]]; then
        printf '%s' "${REALITY_SCRIPT_TARGET}"
        return 0
    fi
    if [[ -f "./docker_reality.sh" ]]; then
        printf '%s' "./docker_reality.sh"
        return 0
    fi
    if [[ -f "$(dirname "$0")/docker_reality.sh" ]]; then
        printf '%s' "$(dirname "$0")/docker_reality.sh"
        return 0
    fi
    return 1
}

installNoDomainReality() {
    local realityScript=""
    if ! realityScript="$(findRealityScript)"; then
        echoContent red "未找到 docker_reality.sh，无法继续执行无域名 Reality 安装"
        return 1
    fi
    echoContent green "开始调用 docker_reality.sh 执行无域名 Reality 安装"
    bash "${realityScript}"
}

showAccountSummary() {
    loadState
    echoContent skyBlue "========================= Docker 账号摘要 ========================="
    showContactInfo
    echoContent yellow "项目目录: ${PROJECT_ROOT}"
    echoContent yellow "Compose 文件: ${COMPOSE_FILE}"
    if [[ -n "${selected_protocol_names}" ]]; then
        echoContent green "已选协议: ${selected_protocol_names}"
    else
        echoContent yellow "尚未生成八合一协议骨架"
    fi
    if [[ -f "${MANIFEST_FILE}" ]]; then
        echoContent yellow "迁移清单: ${MANIFEST_FILE}"
    fi
    echoContent skyBlue "================================================================="
}

showSubscribeSummary() {
    echoContent skyBlue "-------------------------备注---------------------------------"
    echoContent yellow "# Docker 八合一订阅目录已预留"
    echoContent yellow "# 当前目录: ${PROJECT_ROOT}/subscribe"
    echoContent yellow "# 联系方式已固定为:"
    showContactInfo
    echoContent skyBlue "--------------------------------------------------------------"
}

updateDockerAgentScript() {
    local targetFile="/etc/v2ray-agent/docker_v2ray_agent.sh"
    echoContent skyBlue "\n进度 1/1 : 更新 docker_v2ray_agent.sh"
    if commandExists wget; then
        wget -q -O "${targetFile}" "${RAW_SCRIPT_URL}" || {
            echoContent red "下载新脚本失败: ${RAW_SCRIPT_URL}"
            return 1
        }
    elif commandExists curl; then
        curl -fsSL "${RAW_SCRIPT_URL}" -o "${targetFile}" || {
            echoContent red "下载新脚本失败: ${RAW_SCRIPT_URL}"
            return 1
        }
    else
        echoContent red "系统中没有 wget 或 curl，无法更新脚本"
        return 1
    fi
    chmod 700 "${targetFile}"
    echoContent green "\n ---> 更新完毕"
    showDockerStartHint
}

uninstallDockerAgent() {
    local uninstallStatus=""
    read -r -p "是否确认卸载 Docker 八合一管理脚本？[y/n]:" uninstallStatus
    normalizeYesNoInput uninstallStatus
    if [[ "${uninstallStatus}" != "y" ]]; then
        echoContent green " ---> 放弃卸载"
        return 0
    fi

    if [[ -f "${COMPOSE_FILE}" ]]; then
        ${compose_command} -f "${COMPOSE_FILE}" down >/dev/null 2>&1 || true
        echoContent green " ---> Docker Compose 栈关闭完成"
    fi

    rm -rf "${PROJECT_ROOT}" >/dev/null 2>&1 || true
    echoContent green " ---> 删除 Docker 八合一数据目录完成"

    rm -rf /usr/bin/vad /usr/bin/VAD >/dev/null 2>&1 || true
    rm -rf /usr/sbin/vad /usr/sbin/VAD >/dev/null 2>&1 || true
    echoContent green " ---> 卸载快捷方式完成"

    rm -f "${SELF_TARGET}" >/dev/null 2>&1 || true
    echoContent green " ---> 删除 docker_v2ray_agent.sh 完成"
}

selectCoreInstall() {
    echoContent red "=============================================================="
    echoContent yellow "1. 完整八合一 Docker 骨架"
    echoContent yellow "2. 任意组合 Docker 骨架"
    echoContent yellow "3. 一键无域名 Reality"
    echoContent red "=============================================================="
    read -r -p "请选择:" selectInstallType
    case "${selectInstallType}" in
    1)
        installFullStack
        ;;
    2)
        installCustomStack
        ;;
    3)
        installNoDomainReality
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

manageReality() {
    local realityScript=""
    if ! realityScript="$(findRealityScript)"; then
        echoContent red "未找到 docker_reality.sh，无法进入 Reality 管理"
        return 1
    fi
    bash "${realityScript}"
}

menu() {
    ensureProjectDirs
    loadState
    echoContent red "\n=============================================================="
    echoContent green "作者：wbowen123"
    echoContent green "当前版本：${SCRIPT_VERSION}"
    echoContent green "Github：${GITHUB_REPO_URL}"
    echoContent green "描述：八合一 Docker 总控脚本"
    showInstallStatus
    echoContent red "=============================================================="
    echoContent yellow "1.重新安装/初始化"
    echoContent yellow "2.任意组合安装"
    echoContent yellow "3.一键无域名Reality"
    echoContent yellow "4.Hysteria2管理"
    echoContent yellow "5.REALITY管理"
    echoContent yellow "6.Tuic管理"
    echoContent red "-------------------------工具管理-----------------------------"
    echoContent yellow "7.用户管理"
    echoContent yellow "8.伪装站管理"
    echoContent yellow "9.证书管理"
    echoContent yellow "10.CDN节点管理"
    echoContent yellow "11.分流工具"
    echoContent yellow "12.添加新端口"
    echoContent yellow "13.BT下载管理"
    echoContent yellow "15.域名黑名单"
    echoContent red "-------------------------版本管理-----------------------------"
    echoContent yellow "16.core管理"
    echoContent yellow "17.更新脚本"
    echoContent yellow "18.安装BBR、DD脚本"
    echoContent red "-------------------------脚本管理-----------------------------"
    echoContent yellow "20.卸载脚本"
    echoContent red "=============================================================="

    read -r -p "请选择:" menuStatus
    case "${menuStatus}" in
    1)
        installFullStack
        ;;
    2)
        installCustomStack
        ;;
    3)
        installNoDomainReality
        ;;
    4)
        manageHysteria2Menu
        ;;
    5)
        manageReality
        ;;
    6)
        manageTuicMenu
        ;;
    7)
        manageAccountMenu
        ;;
    8)
        manageFakeSiteMenu
        ;;
    9)
        manageTLSMenu
        ;;
    10)
        featureReserved
        ;;
    11)
        featureReserved
        ;;
    12)
        addNewPortMenu
        ;;
    13)
        featureReserved
        ;;
    15)
        featureReserved
        ;;
    16)
        coreManageMenu
        ;;
    17)
        updateDockerAgentScript
        ;;
    18)
        featureReserved
        ;;
    20)
        uninstallDockerAgent
        ;;
    -h | --help)
        showHelp
        ;;
    *)
        echoContent red " ---> 选择错误"
        ;;
    esac
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        showHelp
    fi
    ensureRootLinux
    ensureDockerEnvironment
    selfInstallShortcut
    menu
}

main "$@"
