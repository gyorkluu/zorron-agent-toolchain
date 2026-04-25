#!/usr/bin/env bash
# ============================================================================
# Zorron Agent Toolchain - 公共函数库
# ============================================================================
# 提供：日志输出、路径解析、占位符替换、JSON 深度合并等通用能力
# 用法：source "${ZORRON_ROOT}/scripts/lib.sh"
# ============================================================================

# ---- 基础变量 ----
ZORRON_ROOT="${ZORRON_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ZORRON_HOME="${ZORRON_HOME:-$HOME/.zorron}"
ZORRON_SECRETS="${ZORRON_SECRETS:-$ZORRON_HOME/secrets.local.json}"
ZORRON_HOSTNAME="${ZORRON_HOSTNAME:-$(hostname -s 2>/dev/null || echo "unknown")}"

# ---- 颜色与日志 ----
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
    C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'; C_BOLD='\033[1m'; C_DIM='\033[2m'; C_RESET='\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_DIM=''; C_RESET=''
fi

log_info()  { echo -e "${C_BLUE}ℹ${C_RESET}  $*"; }
log_ok()    { echo -e "${C_GREEN}✔${C_RESET}  $*"; }
log_warn()  { echo -e "${C_YELLOW}⚠${C_RESET}  $*"; }
log_error() { echo -e "${C_RED}✖${C_RESET}  $*" >&2; }
log_step()  { echo -e "${C_CYAN}   ➜${C_RESET} $*"; }

# ---- 路径解析 ----
# 将 target.conf 中的路径变量展开为实际路径
# 支持 ~ 和 $HOME 展开
resolve_path() {
    local raw="$1"
    # 展开 ~ 为 $HOME
    raw="${raw/#\~/$HOME}"
    # 展开 $HOME
    raw="${raw/\$HOME/$HOME}"
    echo "$raw"
}

# ---- 占位符替换 ----
# 在文件中替换 {{HOME}} {{PROJECT_DIR}} {{HOSTNAME}} 占位符
# 用法: render_template <输入文件> <输出文件> [项目目录]
render_template() {
    local input="$1"
    local output="$2"
    local project_dir="${3:-.}"

    if [[ ! -f "$input" ]]; then
        log_error "模板文件不存在: $input"
        return 1
    fi

    local home_esc home_dir_esc hostname_esc project_dir_esc
    home_esc=$(printf '%s\n' "$HOME" | sed 's/[&/\]/\\&/g')
    home_dir_esc=$(printf '%s\n' "$HOME" | sed 's/[&/\]/\\&/g')
    hostname_esc=$(printf '%s\n' "$ZORRON_HOSTNAME" | sed 's/[&/\]/\\&/g')
    project_dir_esc=$(printf '%s\n' "$project_dir" | sed 's/[&/\]/\\&/g')

    sed \
        -e "s|{{HOME}}|${home_esc}|g" \
        -e "s|{{USER_HOME}}|${home_dir_esc}|g" \
        -e "s|{{HOSTNAME}}|${hostname_esc}|g" \
        -e "s|{{PROJECT_DIR}}|${project_dir_esc}|g" \
        "$input" > "$output"
}

# 批量渲染目录下所有文件（递归）
render_directory() {
    local src_dir="$1"
    local dst_dir="$2"
    local project_dir="${3:-.}"

    mkdir -p "$dst_dir"

    find "$src_dir" -type f | while read -r src_file; do
        local rel="${src_file#$src_dir/}"
        local dst_file="$dst_dir/$rel"
        mkdir -p "$(dirname "$dst_file")"
        render_template "$src_file" "$dst_file" "$project_dir"
    done
}

# ---- target.conf 解析 ----
# 读取 target.conf 并导出变量
# 返回 0 表示解析成功
parse_target_conf() {
    local conf_file="$1"
    if [[ ! -f "$conf_file" ]]; then
        log_error "target.conf 不存在: $conf_file"
        return 1
    fi

    TARGET_GLOBAL_DIR=""
    TARGET_PROJECT_DIR=""
    TARGET_LINK_TYPE="symlink"
    TARGET_CLI_CMD=""
    TARGET_VERSION_CHECK=""

    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # 去除前后空白
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        case "$key" in
            DEF_GLOBAL_DIR)    TARGET_GLOBAL_DIR="$value" ;;
            DEF_PROJECT_DIR)   TARGET_PROJECT_DIR="$value" ;;
            LINK_TYPE)         TARGET_LINK_TYPE="$value" ;;
            CLI_CMD)           TARGET_CLI_CMD="$value" ;;
            VERSION_CHECK)     TARGET_VERSION_CHECK="$value" ;;
        esac
    done < "$conf_file"

    return 0
}

# ---- JSON 深度合并 ----
# 使用 jq 将 overlay JSON 合并到 base JSON
# 用法: json_deep_merge <base.json> <overlay.json> <output.json>
json_deep_merge() {
    local base="$1"
    local overlay="$2"
    local output="$3"

    if ! command -v jq &>/dev/null; then
        log_error "需要 jq 但未安装，请先安装: sudo apt install jq / brew install jq"
        return 1
    fi

    if [[ ! -f "$base" ]]; then
        # 如果 base 不存在，直接复制 overlay
        cp "$overlay" "$output"
        return 0
    fi

    if [[ ! -f "$overlay" ]]; then
        cp "$base" "$output"
        return 0
    fi

    jq -s '.[0] * .[1]' "$base" "$overlay" > "$output"
}

# ---- MCP 服务器配置合并 ----
# 合并多个 MCP 服务器 JSON 文件（支持 mcp-servers.json 和 mcp-servers/*.json）
# 用法: merge_mcp_configs <输出文件>
merge_mcp_configs() {
    local output="$1"
    local base_json="${ZORRON_ROOT}/shared/mcp-servers.json"
    local servers_dir="${ZORRON_ROOT}/shared/mcp-servers"
    local host_override="${ZORRON_ROOT}/hosts/${ZORRON_HOSTNAME}/override/mcp-servers.json"

    # 收集所有 MCP 配置
    local all_configs=()

    # 1. 主文件
    if [[ -f "$base_json" ]]; then
        all_configs+=("$base_json")
    fi

    # 2. 拆分式目录下的 JSON 文件
    if [[ -d "$servers_dir" ]]; then
        while IFS= read -r -d '' f; do
            all_configs+=("$f")
        done < <(find "$servers_dir" -name "*.json" -print0 | sort -z)
    fi

    # 3. 主机覆盖
    if [[ -f "$host_override" ]]; then
        all_configs+=("$host_override")
    fi

    # 4. 本地密钥中的 mcpServers 部分
    if [[ -f "$ZORRON_SECRETS" ]]; then
        # 提取 mcpServers 部分到临时文件
        local tmp_secrets
        tmp_secrets=$(mktemp)
        if jq -e '.mcpServers // empty' "$ZORRON_SECRETS" > "$tmp_secrets" 2>/dev/null; then
            all_configs+=("$tmp_secrets")
        else
            rm -f "$tmp_secrets"
        fi
    fi

    if [[ ${#all_configs[@]} -eq 0 ]]; then
        # 没有任何配置，创建空结构
        echo '{"mcpServers":{}}' > "$output"
        return 0
    fi

    # 逐步合并所有配置
    local merged="${all_configs[0]}"
    for ((i = 1; i < ${#all_configs[@]}; i++)); do
        local tmp_out
        tmp_out=$(mktemp)
        # 使用 jq 的 * 运算符进行深度合并
        jq -s --argjson a "$(cat "${all_configs[$((i-1))]}")" \
               --argjson b "$(cat "${all_configs[$i]}")" \
               '$a * $b' > "$tmp_out"
        merged="$tmp_out"
    done

    cp "$merged" "$output"
    # 清理临时文件
    rm -f "$merged"

    log_ok "MCP 配置合并完成: ${#all_configs[@]} 个来源"
}

# ---- 工具检测 ----
# 检测某个 CLI 工具是否已安装
# 用法: detect_tool <cli_command>
detect_tool() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# 扫描 tools/ 目录，返回已安装工具列表
scan_installed_tools() {
    local tools_dir="${ZORRON_ROOT}/tools"
    local installed=()

    for tool_dir in "$tools_dir"/*/; do
        [[ -d "$tool_dir" ]] || continue
        local tool_name
        tool_name=$(basename "$tool_dir")
        local conf_file="$tool_dir/target.conf"

        if [[ -f "$conf_file" ]]; then
            parse_target_conf "$conf_file"
            if [[ -n "$TARGET_CLI_CMD" ]]; then
                if detect_tool "$TARGET_CLI_CMD"; then
                    installed+=("$tool_name")
                fi
            fi
        fi
    done

    echo "${installed[@]}"
}

# ---- 符号链接部署 ----
# 创建符号链接，如果目标已存在则先备份
# 用法: deploy_link <源文件/目录> <目标路径> <链接类型: symlink|copy>
deploy_link() {
    local src="$1"
    local dst="$2"
    local link_type="${3:-symlink}"

    # 确保源存在
    if [[ ! -e "$src" ]]; then
        log_error "源不存在: $src"
        return 1
    fi

    # 创建目标目录
    mkdir -p "$(dirname "$dst")"

    # 如果目标已存在且不是符号链接，先备份
    if [[ -e "$dst" ]] && [[ ! -L "$dst" ]]; then
        log_warn "目标已存在，将备份: $dst"
        backup_path "$dst"
        rm -rf "$dst"
    elif [[ -L "$dst" ]]; then
        # 已是符号链接，直接删除重建
        rm -f "$dst"
    fi

    case "$link_type" in
        symlink)
            ln -s "$src" "$dst"
            log_ok "符号链接: $dst → $src"
            ;;
        copy)
            cp -a "$src" "$dst"
            log_ok "复制: $dst ← $src"
            ;;
        dir)
            # 目录模式：将源目录内容链接/复制到目标
            if [[ -d "$src" ]]; then
                mkdir -p "$dst"
                for item in "$src"/*; do
                    [[ -e "$item" ]] || continue
                    local item_name
                    item_name=$(basename "$item")
                    deploy_link "$item" "$dst/$item_name" "$link_type"
                done
            else
                ln -s "$src" "$dst"
                log_ok "符号链接: $dst → $src"
            fi
            ;;
        *)
            log_error "不支持的链接类型: $link_type"
            return 1
            ;;
    esac
}

# ---- 主机覆盖应用 ----
# 将主机级覆盖文件合并到目标配置
# 用法: apply_host_override <工具名> <目标配置目录>
apply_host_override() {
    local tool_name="$1"
    local target_dir="$2"
    local host_override_dir="${ZORRON_ROOT}/hosts/${ZORRON_HOSTNAME}/override/tools/${tool_name}"

    if [[ ! -d "$host_override_dir" ]]; then
        return 0  # 没有主机覆盖，直接返回
    fi

    log_info "应用主机覆盖 (${ZORRON_HOSTNAME}): $tool_name"

    find "$host_override_dir" -type f | while read -r override_file; do
        local rel="${override_file#$host_override_dir/}"
        local target_file="$target_dir/$rel"

        if [[ -f "$target_file" ]]; then
            # JSON 文件深度合并，其他文件直接覆盖
            if [[ "$target_file" == *.json ]] && command -v jq &>/dev/null; then
                local tmp_out
                tmp_out=$(mktemp)
                json_deep_merge "$target_file" "$override_file" "$tmp_out"
                mv "$tmp_out" "$target_file"
                log_step "合并覆盖: $rel"
            else
                cp "$override_file" "$target_file"
                log_step "覆盖文件: $rel"
            fi
        else
            mkdir -p "$(dirname "$target_file")"
            cp "$override_file" "$target_file"
            log_step "新增文件: $rel"
        fi
    done
}

# ---- 版本检测 ----
# 运行版本检测命令并返回结果
# 用法: check_tool_version <检测命令>
check_tool_version() {
    local check_cmd="$1"
    local version
    version=$(eval "$check_cmd" 2>/dev/null) || return 1
    echo "$version"
}

# ---- 工具函数 ----
# 确认操作
confirm() {
    local msg="$1"
    local default="${2:-y}"
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="$msg [Y/n] "
    else
        prompt="$msg [y/N] "
    fi

    [[ -t 0 ]] || return 0  # 非交互模式默认确认

    read -r -p "$(echo -e "${C_YELLOW}${prompt}${C_RESET}")" answer
    answer="${answer:-$default}"
    [[ "$answer" =~ ^[Yy] ]]
}

# 打印带品牌的横幅
print_banner() {
    echo -e "${C_BOLD}${C_CYAN}"
    cat <<'BANNER'
  __ _  ___ _ __ ___  _ __ __ _
 / _` |/ _ \ '_ ` _ \| '__/ _` |
| (_| |  __/ | | | | | | | (_| |
 \__, |\___|_| |_| |_|_|  \__,_|
 |___/
BANNER
    echo -e "${C_RESET}"
    echo -e "${C_BOLD}  Agent Toolchain${C_RESET} — 你的 AI 编程环境基础设施"
    echo ""
}
