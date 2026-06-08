#compdef zorron
# ============================================================================
# Zorron Agent Toolchain - Zsh 命令行自动补全脚本
# ============================================================================
# 用法: 将此文件所在目录加入 fpath，或者直接在 .zshrc 中 source 此文件：
#       source /Users/gyork/Documents/workspace/zorron-agent-toolchain/scripts/completion.zsh
# ============================================================================

_zorron() {
    local -a commands
    commands=(
        'add:添加新的配置模板 (skill, mcp, tool)'
        'init:初始化本地覆盖和密钥示例'
        'list:列出已配置的工具、Skills、MCP 服务'
        'deploy:运行 install.sh 部署配置'
        'status:显示当前部署状态'
        'backup:管理备份 (list, restore)'
    )

    _arguments -C \
        '1: :->command' \
        '*:: :->args'

    case "$state" in
        command)
            _describe -t commands 'zorron commands' commands
            ;;
        args)
            case "$words[1]" in
                add)
                    local -a add_subcommands
                    add_subcommands=(
                        'skill:创建新的 Skill 模板'
                        'mcp:添加 MCP 服务条目'
                        'tool:创建新工具配置模板'
                    )
                    _describe -t add_subcommands 'add subcommands' add_subcommands
                    
                    # 如果是 add skill，可以尝试补全分类名称（第二参数）
                    if [[ "${#words}" -ge 4 && "$words[2]" == "skill" ]]; then
                        local -a categories
                        categories=(
                            'zorron-skills/frontend:前端开发相关技能'
                            'zorron-skills/docs:文档编写与内容优化'
                            'zorron-skills/bun-ecosystem:Bun/ElysiaJS 后端架构'
                            'zorron-skills/browser:浏览器自动化与 DevTools'
                            'zorron-skills/git:Git 提交与 gh-cli 提效'
                            'zorron-skills/openai:OpenAI 与图像生成'
                            'zorron-skills/zorron-original:自定义原始核心技能'
                        )
                        _describe -t categories 'categories' categories
                    fi
                    ;;
                backup)
                    local -a backup_subcommands
                    backup_subcommands=(
                        'list:列出所有备份'
                        'restore:从备份恢复配置'
                    )
                    _describe -t backup_subcommands 'backup subcommands' backup_subcommands
                    ;;
            esac
            
            case "$words[2]" in
                # 如果用户输入了 zorron backup restore 路径，默认补全文件
                restore)
                    _files
                    ;;
            esac
            ;;
    esac
}

# 注册补全函数
compdef _zorron zorron
# 也为 ./scripts/zorron 注册补全
compdef _zorron ./scripts/zorron
compdef _zorron scripts/zorron
