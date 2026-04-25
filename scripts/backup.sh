#!/usr/bin/env bash
# ============================================================================
# Zorron Agent Toolchain - 备份工具
# ============================================================================
# 在部署前备份已有配置，防止误操作丢失
# 用法: source "${ZORRON_ROOT}/scripts/backup.sh"
# ============================================================================

# 备份目录
ZORRON_BACKUP_DIR="${ZORRON_BACKUP_DIR:-$ZORRON_HOME/backups}"

# ---- 核心备份函数 ----
# 备份指定路径，创建带时间戳的备份
# 用法: backup_path <路径>
backup_path() {
    local target="$1"

    if [[ ! -e "$target" ]]; then
        return 0  # 目标不存在，无需备份
    fi

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${target}.backup.${timestamp}"

    # 确保备份目录存在
    mkdir -p "$(dirname "$backup_name")"

    # 执行备份
    if [[ -L "$target" ]]; then
        # 符号链接：记录链接目标
        local link_target
        link_target=$(readlink -f "$target")
        echo "$link_target" > "$backup_name.symlink"
        rm -f "$target"
        log_step "已备份符号链接: $target → $link_target"
    elif [[ -d "$target" ]]; then
        cp -a "$target" "$backup_name"
        log_step "已备份目录: $target → $backup_name"
    else
        cp -a "$target" "$backup_name"
        log_step "已备份文件: $target → $backup_name"
    fi
}

# ---- 备份清理 ----
# 清理超过指定天数的旧备份
# 用法: cleanup_old_backups [保留天数]
cleanup_old_backups() {
    local keep_days="${1:-30}"
    local count=0

    if [[ ! -d "$ZORRON_BACKUP_DIR" ]]; then
        return 0
    fi

    while IFS= read -r -d '' f; do
        rm -rf "$f"
        ((count++))
    done < <(find "$ZORRON_BACKUP_DIR" -name "*.backup.*" -type d -mtime +"$keep_days" -print0 2>/dev/null)

    while IFS= read -r -d '' f; do
        rm -f "$f"
        ((count++))
    done < <(find "$ZORRON_BACKUP_DIR" -name "*.backup.*" ! -type d -mtime +"$keep_days" -print0 2>/dev/null)

    if [[ $count -gt 0 ]]; then
        log_info "已清理 $count 个超过 ${keep_days} 天的旧备份"
    fi
}

# ---- 恢复备份 ----
# 从备份恢复指定路径
# 用法: restore_backup <原始路径> [备份时间戳]
restore_backup() {
    local target="$1"
    local timestamp="${2:-}"

    if [[ -z "$timestamp" ]]; then
        # 找到最新的备份
        local latest
        latest=$(find "$(dirname "$target")" -maxdepth 1 -name "$(basename "$target").backup.*" | sort -r | head -1)
        if [[ -z "$latest" ]]; then
            log_error "未找到 $target 的备份"
            return 1
        fi
        timestamp="${latest##*.backup.}"
    fi

    local backup_name="${target}.backup.${timestamp}"

    if [[ ! -e "$backup_name" ]]; then
        log_error "备份不存在: $backup_name"
        return 1
    fi

    # 检查是否是符号链接备份
    if [[ -f "${backup_name}.symlink" ]]; then
        local link_target
        link_target=$(cat "${backup_name}.symlink")
        rm -f "${backup_name}.symlink"
        ln -s "$link_target" "$target"
        log_ok "已恢复符号链接: $target → $link_target"
    elif [[ -d "$backup_name" ]]; then
        rm -rf "$target"
        mv "$backup_name" "$target"
        log_ok "已恢复目录: $target"
    else
        mv "$backup_name" "$target"
        log_ok "已恢复文件: $target"
    fi
}

# ---- 列出备份 ----
# 列出指定路径的所有备份
# 用法: list_backups [路径前缀]
list_backups() {
    local prefix="${1:-$HOME}"

    echo "📋 备份列表 (前缀: $prefix):"
    echo "─────────────────────────────────────"

    find "$prefix" -name "*.backup.*" -o -name "*.backup.*.symlink" 2>/dev/null | sort | while read -r f; do
        local size=""
        if [[ -f "$f" ]]; then
            size=$(du -h "$f" | cut -f1)
        elif [[ -d "$f" ]]; then
            size=$(du -sh "$f" | cut -f1)
        fi
        echo "  $f  ($size)"
    done
}
