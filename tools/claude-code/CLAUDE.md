# Claude Code - 项目级指令

## 项目信息
- **项目**: Zorron Agent Toolchain
- **品牌**: Zorron
- **配置管理**: 通过 Zorron Toolchain 统一管理

## 编码规范
- 遵循 shared/rules/global.md 中定义的全局规范
- Shell 脚本使用 bash，遵循 Google Shell Style Guide
- JSON 配置文件使用 2 空格缩进
- YAML 配置文件使用 2 空格缩进

## 工作流程
1. 修改代码前先理解现有结构
2. 遵循约定优于配置原则
3. 新增配置文件时使用占位符（{{HOME}}, {{HOSTNAME}} 等）
4. 提交前确保 install.sh 能正常工作

## MCP 服务
- 通过 shared/mcp-servers/ 目录管理
- 敏感信息通过 ~/.zorron/secrets.local.json 注入

## 注意事项
- 不要修改 target.conf 的格式约定
- 新增工具时使用 `./scripts/zorron add tool <名称>`
- 新增 Skill 时使用 `./scripts/zorron add skill <名称>`
