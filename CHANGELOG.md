# Changelog

All notable changes to the Zorron Agent Toolchain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2025-01-01

### Added
- 初始版本发布
- 核心部署脚本 `install.sh`，支持智能检测和按需部署
- 命令行助手 `scripts/zorron`，支持 add/init/list/deploy/status/backup 命令
- 公共函数库 `scripts/lib.sh`，提供日志、路径解析、占位符替换、JSON 合并等能力
- 备份工具 `scripts/backup.sh`，支持自动备份和恢复
- 三个工具的初始配置模板：Claude Code、Hermes Agent、OpenCode
- Qwen Code 工具模板（示例）
- 共享 Skills 系统（含 pdf-reader 示例）
- 全局 MCP 服务配置（支持主文件 + 拆分式目录）
- 全局编码规范和 AI 协作准则
- 多层级覆盖机制（通用 < 工具 < 主机 < 本地）
- 主机覆盖示例（macbook-pro、linux-server）
- 敏感信息安全隔离（secrets.local.json + .env.local）
- 路径占位符系统（{{HOME}}、{{HOSTNAME}}、{{PROJECT_DIR}}）
- target.conf 自描述部署机制
- 幂等安装，多次运行安全
- 安装前自动备份已有配置
