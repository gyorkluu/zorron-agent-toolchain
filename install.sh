#!/usr/bin/env bash
# ============================================================================
# Zorron Agent Toolchain - 核心部署脚本
# ============================================================================
# 智能检测已安装的 Agent 工具，按需部署配置
# 用法: ./install.sh [--force] [--dry-run] [--verbose] [--host <hostname>]
# ============================================================================

set -euo pipefail

# ---- 解析参数 ----
FORCE=false
DRY_RUN=false
VERBOSE=false
CUSTOM_HOST=""
SELECTIVE_TOOLS=""
INSTALL_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f)   FORCE=true; shift ;;
        --dry-run|-n) DRY_RUN=true; shift ;;
        --verbose|-v) VERBOSE=true; shift ;;
        --host|-H)    CUSTOM_HOST="$2"; shift 2 ;;
        --tools|-t)   SELECTIVE_TOOLS="$2"; shift 2 ;;
        --all|-a)     INSTALL_ALL=true; shift ;;
        --help|-h)
            echo "用法: ./install.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --force, -f     强制部署，覆盖已有配置（不询问）"
            echo "  --dry-run, -n   模拟运行，不实际修改文件"
            echo "  --verbose, -v   显示详细输出"
            echo "  --host, -H      指定主机名（默认自动检测）"
            echo "  --tools, -t     指定仅部署的工具列表，逗号分隔 (例: --tools claude-code,opencode)"
            echo "  --all, -a       强制部署所有工具，跳过 CLI 已安装检测"
            echo "  --help, -h      显示帮助"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# ---- 初始化 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ZORRON_ROOT="${ZORRON_ROOT:-$SCRIPT_DIR}"
export ZORRON_HOME="${ZORRON_HOME:-$HOME/.zorron}"

# 如果指定了自定义主机名
if [[ -n "$CUSTOM_HOST" ]]; then
    export ZORRON_HOSTNAME="$CUSTOM_HOST"
fi

# 加载函数库
source "${ZORRON_ROOT}/scripts/lib.sh"
source "${ZORRON_ROOT}/scripts/backup.sh"

# ---- 打印横幅 ----
print_banner

# ---- 自动安装缺失工具的函数 ----
install_missing_dependency() {
    local tool_name="$1"
    
    if $DRY_RUN; then
        log_step "  [模拟] 自动安装缺失的工具: ${tool_name}"
        return 0
    fi
    
    log_info "正在尝试自动安装工具: ${tool_name}..."
    
    local os_type
    os_type="$(uname -s)"
    
    case "$tool_name" in
        git)
            if [[ "$os_type" == "Darwin" ]]; then
                if command -v brew &>/dev/null; then
                    brew install git
                else
                    log_warn "未检测到 Homebrew，尝试调用 xcode-select 安装 Command Line Tools..."
                    xcode-select --install || true
                fi
            else
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y git
                elif command -v yum &>/dev/null; then
                    sudo yum install -y git
                elif command -v pacman &>/dev/null; then
                    sudo pacman -Sy --noconfirm git
                else
                    log_error "未找到支持的包管理器，请手动安装 git"
                    return 1
                fi
            fi
            ;;
        python3)
            if [[ "$os_type" == "Darwin" ]]; then
                if command -v brew &>/dev/null; then
                    brew install python
                else
                    log_error "未检测到 Homebrew，请手动安装 Python 3"
                    return 1
                fi
            else
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y python3
                elif command -v yum &>/dev/null; then
                    sudo yum install -y python3
                elif command -v pacman &>/dev/null; then
                    sudo pacman -Sy --noconfirm python
                else
                    log_error "未找到支持的包管理器，请手动安装 python3"
                    return 1
                fi
            fi
            ;;
        bun)
            # Bun 官方安装器在 macOS & Linux 下均支持，直接写入 ~/.bun
            curl -fsSL https://bun.sh/install | bash
            export PATH="$HOME/.bun/bin:$PATH"
            ;;
        jq)
            if [[ "$os_type" == "Darwin" ]]; then
                if command -v brew &>/dev/null; then
                    brew install jq
                else
                    log_error "未检测到 Homebrew，请手动安装 jq"
                    return 1
                fi
            else
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &>/dev/null; then
                    sudo yum install -y jq
                elif command -v pacman &>/dev/null; then
                    sudo pacman -Sy --noconfirm jq
                else
                    log_error "未找到支持的包管理器，请手动安装 jq"
                    return 1
                fi
            fi
            ;;
        envsubst)
            if [[ "$os_type" == "Darwin" ]]; then
                if command -v brew &>/dev/null; then
                    brew install envsubst || brew install gettext
                else
                    log_error "未检测到 Homebrew，请手动安装 gettext"
                    return 1
                fi
            else
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y gettext
                elif command -v yum &>/dev/null; then
                    sudo yum install -y gettext
                elif command -v pacman &>/dev/null; then
                    sudo pacman -Sy --noconfirm gettext
                else
                    log_error "未找到支持的包管理器，请手动安装 gettext"
                    return 1
                fi
            fi
            ;;
    esac
    
    if command -v "$tool_name" &>/dev/null || [[ "$tool_name" == "bun" && -f "$HOME/.bun/bin/bun" ]]; then
        log_ok "${tool_name} 自动安装完成！"
    else
        log_warn "${tool_name} 自动安装可能失败，请稍后检查环境。"
    fi
}

# ---- 前置检查 ----
log_info "检查并自动安装缺失的系统依赖..."
log_audit "deploy_start" "Force: $FORCE, Dry-run: $DRY_RUN"

# 检查并安装 git
if ! command -v git &>/dev/null; then
    install_missing_dependency "git"
fi

# 检查并安装 python3
if ! command -v python3 &>/dev/null; then
    install_missing_dependency "python3"
fi

# 检查并安装 bun
if ! command -v bun &>/dev/null && [[ ! -f "$HOME/.bun/bin/bun" ]]; then
    install_missing_dependency "bun"
fi

# 检查并安装 jq
if ! command -v jq &>/dev/null; then
    install_missing_dependency "jq"
fi

# 检查并安装 envsubst
if ! command -v envsubst &>/dev/null; then
    install_missing_dependency "envsubst"
fi

# 确保 Zorron 本地目录存在
mkdir -p "$ZORRON_HOME"

# 检查并拉取子模块
if [[ -d "${ZORRON_ROOT}/shared/skills/zorron-skills" ]] && [[ ! -f "${ZORRON_ROOT}/shared/skills/zorron-skills/README.md" ]]; then
    log_info "🔄 检测到 Skill 子模块未初始化，正在拉取..."
    if command -v git &>/dev/null; then
        git submodule update --init --recursive || log_warn "子模块自动拉取失败，请检查网络连接"
    else
        log_warn "未检测到 git 命令，无法自动拉取子模块"
    fi
fi

# ---- 干运行提示 ----
if $DRY_RUN; then
    log_warn "🔍 模拟运行模式 — 不会实际修改任何文件"
    echo ""
fi

# ---- 第一步：扫描已安装工具 ----
log_info "🔍 扫描已安装的 Agent 工具..."

TOOLS_DIR="${ZORRON_ROOT}/tools"
INSTALLED_TOOLS=()

for tool_dir in "$TOOLS_DIR"/*/; do
    [[ -d "$tool_dir" ]] || continue
    tool_name=$(basename "$tool_dir")
    conf_file="$tool_dir/target.conf"

    if [[ ! -f "$conf_file" ]]; then
        $VERBOSE && log_warn "跳过 $tool_name（缺少 target.conf）"
        continue
    fi

    parse_target_conf "$conf_file"

    # 检测工具选择与安装情况
    if $INSTALL_ALL; then
        INSTALLED_TOOLS+=("$tool_name")
        log_ok "强制部署工具 (All Mode): $tool_name"
    elif [[ -n "$SELECTIVE_TOOLS" ]]; then
        # 检查工具是否在指定列表中 (支持逗号分隔)
        if [[ ",$SELECTIVE_TOOLS," == *",$tool_name,"* ]]; then
            INSTALLED_TOOLS+=("$tool_name")
            log_ok "选择部署工具: $tool_name"
        fi
    else
        # 默认：自动探测本地 CLI 状态
        if [[ -n "$TARGET_CLI_CMD" ]]; then
            if detect_tool "$TARGET_CLI_CMD"; then
                INSTALLED_TOOLS+=("$tool_name")
                log_ok "检测到本地已安装: $tool_name (${TARGET_CLI_CMD})"
            else
                $VERBOSE && log_info "未检测到本地安装: $tool_name (${TARGET_CLI_CMD})"
            fi
        else
            # 没有检测命令的工具默认部署
            INSTALLED_TOOLS+=("$tool_name")
            log_ok "检测到工具 (无检测条件): $tool_name"
        fi
    fi
done

if [[ ${#INSTALLED_TOOLS[@]} -eq 0 ]]; then
    log_warn "未检测到任何已安装的 Agent 工具"
    log_info "你可以手动运行: ./scripts/zorron add tool <工具名>"
    exit 0
fi

echo ""
log_info "共检测到 ${#INSTALLED_TOOLS[@]} 个工具: ${INSTALLED_TOOLS[*]}"
echo ""

# ---- 第二步：部署各工具配置 ----
log_info "📦 开始部署配置..."

for tool_name in "${INSTALLED_TOOLS[@]}"; do
    tool_dir="${TOOLS_DIR}/${tool_name}"
    conf_file="$tool_dir/target.conf"

    log_step "部署 ${tool_name} 配置..."

    parse_target_conf "$conf_file"

    # 版本检测（如果配置了）
    if [[ -n "$TARGET_VERSION_CHECK" ]]; then
        tool_version=$(check_tool_version "$TARGET_VERSION_CHECK" 2>/dev/null || echo "unknown")
        $VERBOSE && log_info "  版本: $tool_version"

        # 检查是否有版本特定目录
        if [[ -d "$tool_dir/v2" ]] && [[ "$tool_version" == *"2"* ]]; then
            tool_dir="$tool_dir/v2"
            $VERBOSE && log_info "  使用 v2 配置目录"
        fi
    fi

    # 部署全局配置
    if [[ -n "$TARGET_GLOBAL_DIR" ]]; then
        global_target=$(resolve_path "$TARGET_GLOBAL_DIR")

        if $DRY_RUN; then
            log_step "  [模拟] 部署全局配置到: $global_target"
        else
            # 备份已有配置
            if [[ -e "$global_target" ]] && ! $FORCE; then
                if confirm "全局配置目录 $global_target 已存在，是否备份并覆盖？"; then
                    backup_path "$global_target"
                else
                    log_warn "跳过 $tool_name 全局配置部署"
                    continue
                fi
            elif [[ -e "$global_target" ]] && $FORCE; then
                backup_path "$global_target"
            fi

            # 部署工具目录下的所有配置文件（排除 target.conf）
            for item in "$tool_dir"/*; do
                [[ -e "$item" ]] || continue
                item_name=$(basename "$item")

                # 跳过 target.conf 和版本目录
                [[ "$item_name" == "target.conf" ]] && continue
                [[ "$item_name" =~ ^v[0-9]+$ ]] && continue

                deploy_link "$item" "$global_target/$item_name" "$TARGET_LINK_TYPE"
            done

            # 应用主机覆盖
            apply_host_override "$tool_name" "$global_target"

            # 渲染占位符（对 JSON 和配置文件）
            find "$global_target" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.conf" -o -name "*.toml" \) | while read -r cfg_file; do
                local_tmp=$(mktemp)
                render_template "$cfg_file" "$local_tmp" "."
                mv "$local_tmp" "$cfg_file"
            done
        fi
    fi

    # 部署项目级配置
    if [[ -n "$TARGET_PROJECT_DIR" ]]; then
        project_target="$TARGET_PROJECT_DIR"

        if $DRY_RUN; then
            log_step "  [模拟] 部署项目级配置到: $project_target"
        else
            mkdir -p "$project_target"

            # 查找项目级配置文件（通常以 CLAUDE.md、.opencode 等命名）
            for item in "$tool_dir"/*; do
                [[ -e "$item" ]] || continue
                item_name=$(basename "$item")
                [[ "$item_name" == "target.conf" ]] && continue
                [[ "$item_name" =~ ^v[0-9]+$ ]] && continue

                # 项目级配置通常只部署特定文件
                case "$item_name" in
                    CLAUDE.md|.opencode*|*.project.*)
                        deploy_link "$item" "$project_target/$item_name" "$TARGET_LINK_TYPE"
                        ;;
                esac
            done
        fi
    fi

    echo ""
done

# ---- 第三步：合并全局 MCP 服务 ----
log_info "🔗 合并全局 MCP 服务..."

if $DRY_RUN; then
    log_step "[模拟] 合并 MCP 配置"
else
    # 为每个已安装工具生成 MCP 配置
    for tool_name in "${INSTALLED_TOOLS[@]}"; do
        tool_dir="${TOOLS_DIR}/${tool_name}"
        conf_file="$tool_dir/target.conf"
        parse_target_conf "$conf_file"

        global_target=$(resolve_path "$TARGET_GLOBAL_DIR")

        # 不同工具的 MCP 配置路径
        case "$tool_name" in
            claude-code)
                mcp_output="$global_target/settings.json"
                ;;
            hermes-agent)
                mcp_output="$global_target/.hermes.yaml"
                ;;
            opencode)
                mcp_output="$global_target/config.json"
                ;;
            *)
                mcp_output="$global_target/mcp-servers.json"
                ;;
        esac

        # 合并 MCP 配置
        if [[ -f "$mcp_output" ]] || [[ -f "${ZORRON_ROOT}/shared/mcp-servers.json" ]] || [[ -d "${ZORRON_ROOT}/shared/mcp-servers" ]]; then
            merged_mcp=$(mktemp)
            merge_mcp_configs "$merged_mcp"

            # 根据工具格式注入 MCP 配置
            case "$tool_name" in
                claude-code)
                    if [[ -f "$mcp_output" ]] && command -v jq &>/dev/null; then
                        local_tmp=$(mktemp)
                        # 将 mcpServers 注入到 claude settings.json
                        jq --slurpfile mcp "$merged_mcp" '. * {mcpServers: $mcp[0].mcpServers}' "$mcp_output" > "$local_tmp"
                        mv "$local_tmp" "$mcp_output"
                        log_step "已将 MCP 配置注入 $tool_name"
                    fi
                    ;;
                *)
                    # 其他工具：如果配置文件不存在，直接复制
                    if [[ ! -f "$mcp_output" ]]; then
                        cp "$merged_mcp" "$mcp_output"
                        log_step "已创建 MCP 配置: $mcp_output"
                    fi
                    ;;
            esac

            rm -f "$merged_mcp"
        fi
    done
fi

echo ""

# ---- 第四步：部署共享 Skills ----
log_info "📚 部署共享 Skills..."

SHARED_SKILLS_DIR="${ZORRON_ROOT}/shared/skills"

if [[ -d "$SHARED_SKILLS_DIR" ]]; then
    # 递归查找所有包含 SKILL.md/skill.md 的目录，排除 .git
    find "$SHARED_SKILLS_DIR" -type d -name ".git" -prune -o -type f \( -name "SKILL.md" -o -name "skill.md" \) -print | while read -r skill_file; do
        [[ -f "$skill_file" ]] || continue
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")

        # 校验 Skill 结构稳定性
        if command -v python3 &>/dev/null && [[ -f "${ZORRON_ROOT}/scripts/validate_skill.py" ]]; then
            if ! python3 "${ZORRON_ROOT}/scripts/validate_skill.py" "$skill_file" >/dev/null 2>&1; then
                log_warn "  ⚠️  Skill 校验提示: ${skill_name} 结构不符合规范，建议优化。查看详情: python3 scripts/validate_skill.py $skill_file"
            fi
        fi

        if $DRY_RUN; then
            log_step "[模拟] 部署 Skill: $skill_name"
        else
            # 为每个工具部署 Skill
            for tool_name in "${INSTALLED_TOOLS[@]}"; do
                tool_dir="${TOOLS_DIR}/${tool_name}"
                conf_file="$tool_dir/target.conf"
                parse_target_conf "$conf_file"
                global_target=$(resolve_path "$TARGET_GLOBAL_DIR")

                # 根据工具确定 skills 目录
                case "$tool_name" in
                    claude-code)
                        skill_target="$global_target/skills/$skill_name"
                        ;;
                    *)
                        skill_target="$global_target/skills/$skill_name"
                        ;;
                esac

                if [[ -n "$skill_target" ]]; then
                    mkdir -p "$(dirname "$skill_target")"
                    deploy_link "$skill_dir" "$skill_target" "symlink"
                fi
            done
        fi
    done
else
    log_info "没有找到共享 Skills（shared/skills/ 为空）"
fi

echo ""

# ---- 第五步：部署全局规则 ----
log_info "📜 部署全局规则..."

RULES_DIR="${ZORRON_ROOT}/shared/rules"

if [[ -d "$RULES_DIR" ]]; then
    for rule_file in "$RULES_DIR"/*.md; do
        [[ -f "$rule_file" ]] || continue
        rule_name=$(basename "$rule_file")

        if $DRY_RUN; then
            log_step "[模拟] 部署规则: $rule_name"
        else
            for tool_name in "${INSTALLED_TOOLS[@]}"; do
                tool_dir="${TOOLS_DIR}/${tool_name}"
                conf_file="$tool_dir/target.conf"
                parse_target_conf "$conf_file"
                global_target=$(resolve_path "$TARGET_GLOBAL_DIR")

                case "$tool_name" in
                    claude-code)
                        rule_target="$global_target/CLAUDE.d/rules/$rule_name"
                        ;;
                    *)
                        rule_target="$global_target/rules/$rule_name"
                        ;;
                esac

                if [[ -n "$rule_target" ]]; then
                    mkdir -p "$(dirname "$rule_target")"
                    deploy_link "$rule_file" "$rule_target" "symlink"
                fi
            done
        fi
    done
fi

echo ""

# ---- 第六步：清理旧备份 ----
if ! $DRY_RUN; then
    cleanup_old_backups 30
fi

# ---- 完成 ----
echo ""
log_ok "✅ Zorron Agent Toolchain 已就绪！"
log_audit "deploy_success" "Completed successfully. Installed: ${INSTALLED_TOOLS[*]}"
echo ""
echo -e "${C_BOLD}  已部署工具:${C_RESET} ${INSTALLED_TOOLS[*]}"
echo -e "${C_BOLD}  配置目录:${C_RESET} $ZORRON_HOME"
echo -e "${C_BOLD}  主机标识:${C_RESET} $ZORRON_HOSTNAME"
echo ""
echo -e "${C_DIM}  提示: 运行 ./scripts/zorron 管理 Skills、MCP 服务和工具${C_RESET}"
echo ""
