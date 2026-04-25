# linux-server 主机覆盖说明

此目录用于存放 Linux 服务器特有的配置覆盖。

## 使用方法

1. 确保主机名匹配（运行 `hostname -s` 查看）
2. 在此目录下创建与 tools/ 对应的覆盖文件
3. 运行 `./install.sh` 自动应用覆盖

## 示例

如果需要覆盖 Claude Code 的配置：
```bash
mkdir -p hosts/linux-server/override/tools/claude-code
# 创建覆盖文件
```

如果需要添加服务器特有的 MCP 服务：
```bash
# 创建 MCP 覆盖文件
echo '{"mcpServers":{...}}' > hosts/linux-server/override/mcp-servers.json
```
