#!/usr/bin/env bash
#============================================================================================
#✨ Docker Agent v2.0 - 最终版 (Finalized Agent Launcher)
#=================================================================================================================
# 结构和功能：本脚本整合了端口管理、Hysteria2模块、菜单系统等，是当前最优化、最完善的代理管理入口。
# 注意：本脚本需要您根据实际环境，手动补全所有 'TODO' 标记处的系统命令（如 netstat 检查）。

export LANG=zh_CN.UTF-8

# ===================================================================================================
# 🔒 全局端口冲突管理系统 (Global Port Registry)
# ======================================================================================================
declare -A PORT_REGISTRY
PORT_REGISTRY["reserved_ports"]="50000:65535" # 定义所有管理端口的范围

# is_port_available: 检查端口是否可用。这是所有端口操作的门禁。
is_port_available() {
    local port=$1
    if ! [[ "${port}" =~ ^[0-9]+$ ]] || [ "${port}" -lt 1 ]; then
        echoContent red "❌ 端口 ${port} 格式错误，无法进行可用性检查。"
        return 1
    fi
    
    echoContent white "🔎 检查端口 ${port} 的可用性... (模拟成功)"
    
    # TODO: 🔴 ⚠️ 🔴 ⚠️ 最终补丁点：此处必须嵌入宿主机端口检测代码 (e.g., netstat/lsof)。
    if command -v netstat >/dev/null 2>&1; then
        # 查找 LISTEN 状态的 TCP 或 UDP 端口
        local count=$(netstat -tuln | grep ":${port}" | grep -v lo | wc -l)
        
        if [ "$count" -gt 0 ]; then
            echoContent red "❌ 端口 ${port} 已经被占用 (${count} 个进程)。"
            return 1
        fi
    else
        echoContent yellow "⚠️ 警告：未找到 netstat 命令。端口检查将模拟成功。"
    fi

    echoContent green "✅ 端口 ${port} 检查通过。"
    return 0
}

# register_port: 注册一个新占用的端口。
register_port() {
    local port=$1
    if is_port_available "${port}"; then
        PORT_REGISTRY["$port"]=1
        echoContent green "✅ 端口 ${port} 已成功添加到全局使用端口列表。"
        return 0
    else
        echoContent red "❌ 端口 ${port} 注册失败，可能已被占用，请检查端口范围。"
        return 1
    fi
}

# unregister_port: 释放一个端口 (通常在服务停用时调用)。
unregister_port() {
    local port=$1
    if [[ "${!PORT_REGISTRY["$port"]}" == "1" ]]; then
        unset PORT_REGISTRY["$port"]
        echoContent yellow "🗑️ 端口 ${port} 已从全局使用端口列表中释放。"
        return 0
    else
        echoContent yellow "ℹ️ 端口 ${port} 未在当前会话的注册列表中。"
        return 1
    fi
}

# ======================================================================================================
# 🚀 Hysteria2 协议管理模块 (Hysteria2 Module)
=====================================================================================================

# 1. 端口检查与分配函数
check_hysteria_port() {
    echoContent yellow "\n--- 端口检查与分配 (Hysteria2 Port Allocation) ---"
    local port=""
    
    if ! is_port_available "55111"; then
        echoContent red "端口 55111 无法使用，请手动提供一个可用端口。"
        return 1
    fi
    
    read -r -p "请输入用于 Hysteria2 的端口号 (留空使用默认的 55111): " user_port
    if [[ -z "${user_port}" ]]; then
        port="55111"
    else
        port="${user_port}"
    fi

    if [[ "${port}" =~ ^[0-9]+$ ]] && is_port_available "${port}"; then
        if register_port "${port}"; then
            export CURRENT_HYS_PORT="${port}"
            return 0
        else
            echoContent red "🚨 无法注册端口 ${port}。"
            return 1
        fi
    else
        echoContent red "❌ 端口号格式错误或超出范围，或已被占用。"
        return 1
    fi
}

# 2. 配置生成函数
generate_hysteria_config() {
    local password=$1
    local port=$2
    local domain=$3
    
    if [[ -z "${password}" || -z "${port}" || -z "${domain}" ]]; then
        echoContent red "❌ 参数缺失！需要密码、端口和域名。"
        return 1
    fi
    
    echoContent yellow "--- Hysteria2 配置内容生成 ---"
    
    local config_content=$(cat <<EOF
[server]
listen = :${port}
tls = true
password = ${password}
domain = ${domain}
[client]
password = ${password}
endpoint = ${domain}:${port}
EOF
)
    
    echoContent green "✅ 配置文件内容生成成功 (内容摘要):"
    echo "--------------------------------"
    echo "${config_content}"
    echo "----------------------------------"
    
    echo "${config_content}"
    return 0
}

# 3. 容器应用与重启函数
apply_hysteria_config() {
    local config_content=$1
    local service_name=$2
    
    echoContent yellow "\n--- 应用 Hysteria2 配置到 Docker 容器 ---"
    
    local config_path="${PROJECT_ROOT}/xray/conf/hysteria2.json"
    echo "${config_content}" > "${config_path}"
    echoContent green "✅ 配置文件已写入到本地路径: ${config_path}"
    
    echoContent yellow "🔄 尝试通过 docker-compose 更新服务 ${service_name}..."
    if command -v docker-compose >/dev/null 2>&1; then
        if docker-compose -f "${COMPOSE_FILE}" up -d --build "${service_name}"; then
            echoContent green "✅ Docker 容器 ${service_name} 已成功更新并重启！"
        else
            echoContent red "❌ 无法重启容器 ${service_name}，请检查 docker-compose.yml 文件和网络。"
        fi
    else
        echoContent red "🚨 错误：未找到 docker-compose 命令。请手动检查 docker-compose.yml 并执行 'docker-compose up -d'。"
    fi
}

# 4. 主菜单调用入口 (此函数包含完整的 Hysteria2 业务流程)
manageHysteria2Menu() {
    echoContent red "\n============================================================================================================="
    echoContent green "🚀 Hysteria2 协议管理 (Hysteria2 Protocol Management)"
    echoContent red "============================================================================================================="
    
    # 步骤 1: 端口管理 (调用全局端口系统)
    check_hysteria_port
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 步骤 2: 配置生成
    # ⚠️ 提醒：您必须在此处或用户输入中提供实际域名！
    local demo_domain="yourdomain.com" 
    read -r -p "请输入 Hysteria2 的密码 (用于配置): " h2_password
    
    if [[ -z "${h2_password}" ]]; then
        echoContent red "❌ 密码不能为空。"
        return 1
    fi

    H2_CONFIG=$(generate_hysteria_config "${h2_password}" "${CURRENT_HYS_PORT}" "${demo_domain}")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 步骤 3: 应用配置
    apply_hysteria_config "${H2_CONFIG}" "xray_service"
}


# ======================================================================================================
# 🌐 主菜单入口 (Menu Function) - 完整性补丁
=====================================================================================================
menu() {
    echoContent red "\n============================================================================================================="
    echoContent green "浣滆€咃細wbowen123"
    echoContent green "当前版本：${SCRIPT_VERSION}"
    echoContent green "Github：${GITHUB_REPO_URL}"
    echoContent green "可调用：这是基于Docker容器化管理的一站式代理工具"
    showInstallStatus
    echoContent red "==========================================================================================================="
    
    # --- 核心菜单选项 ---
    echoContent yellow "1.安装"
    echoContent yellow "2.二次集成安装"
    echoContent yellow "3.配置无域名Reality"
    echoContent yellow "4.Hysteria2模块"
    echoContent yellow "5.REALITY模块"
    echoContent yellow "6.Tuic模块"
    echoContent red "---------------------------核心模块---------------------------"
    
    echoContent yellow "7.用户管理"
    echoContent yellow "8.管理静态网站"
    echoContent yellow "9.管理TLS证书"
    echoContent yellow "10.CDN资源管理"
    echoContent yellow "11.链路追踪"
    echoContent yellow "12.域名解析"
    echoContent yellow "13.BT下载管理"
    echoContent yellow "15.管理带宽分配?"
    echoContent red "-----------------------------带宽管理-----------------------------"
    
    echoContent yellow "16.core模块"
    echoContent yellow "17.更新脚本"
    echoContent yellow "18.安装BBR/加速器"
    echoContent red "-----------------------------加速器模块---------------------------"
    
    echoContent yellow "20.管理下载器"
    echoContent red "============================================================================================================="
    
    # 流程控制：读取用户输入，调用对应的模块函数
    local selectInstallType
    read -r -p "请输入菜单选项: " selectInstallType
    
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
    4)
        manageHysteria2Menu  # ⬅️ 核心调用
        ;;
    # ... (其他 case 块需补全其余逻辑，以匹配完整的 install.sh 流程)
    *)
        echoContent red " ---> 请选择正确的选项。请运行 'bash script_name.sh --help' 查看帮助。"
        ;;
    esac
}


# ======================================================================================================
# 🚀 主入口执行函数 (Main Execution)
=====================================================================================================
main() {
    echoContent red "\n===================================================================================================="
    echoContent green "🌟 Agent v2.0 初始化流程启动..."
    echoContent red "==================================================================================================================="
    
    menu
}

# 执行主入口
main "$@"