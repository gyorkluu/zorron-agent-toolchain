# 腾讯云 EdgeOne Pages 官方文档参考

本文件编译自腾讯云 EdgeOne Pages 官方文档库（包含产品简介、快速开始、CLI 部署、配置文件说明、函数与存储服务等章节），作为本地开发与部署的权威参考。

---

## 一、 产品简介 (Product Introduction)

### 1. 产品概述
EdgeOne Pages 是基于 Tencent EdgeOne 基础设施打造的**全栈开发部署平台**。它支持从纯前端静态页面到动态 API (Serverless Functions) 的无服务器部署，适用于构建现代化营销网站、AI 应用、企业官网等现代 Web 项目。

### 2. 产品优势
- **现代化部署流程**：支持 Git 自动关联构建、命令行 CLI、MCP 插件及主流 IDE 插件，实现全自动持续集成与发布（CI/CD）。
- **全球边缘加速**：静态资源和动态 API 运行于 EdgeOne 全球边缘网络，配合智能缓存与动态路由，确保全球极低时延访问。
- **云边一体化 Serverless**：同时提供**边缘函数 (Edge Functions)** 和**云函数 (Cloud Functions)**，无需预估或管理底层服务器硬件，按需自动弹性伸缩。
- **全栈框架零配置集成**：原生兼容 Next.js、Nuxt、Astro 等主流全栈框架的 SSR（服务端渲染）与 ISR（增量静态生成）特性。

### 3. 应用场景
- **高性能全栈项目**：如具有服务端渲染 (SSR)、复杂 API 请求、大模型流式响应 (SSE) 的全栈网站。
- **静态及单页应用 (SPA) 托管**：基于 React、Vue、Svelte、Astro、Hexo 等构建的静态网页与单页应用。
- **敏捷开发与发布**：团队通过分支自动化部署预览版本，进行高频验证。

---

## 二、 快速开始与 CLI 部署 (Quick Start & CLI)

使用 EdgeOne CLI 可以直接在本地终端完成项目的初始化、配置、测试与部署。

### 1. 安装 CLI
EdgeOne CLI 依赖 Node.js 或 Bun 运行环境，可通过 npm 全局安装：
```bash
npm install -g edgeone
```
验证安装是否成功：
```bash
edgeone -v
```

### 2. 账号登录
在部署前，需登录腾讯云账号。
- **交互式浏览器登录（开发环境首选）**：
  ```bash
  edgeone login
  ```
  执行后会拉起默认浏览器，授权腾讯云账号登录。
- **Token 登录（CI/CD/免交互环境）**：
  在腾讯云控制台获取 API Token，并在执行部署时通过 `-t` 参数传入：
  ```bash
  edgeone pages deploy ./dist -t <api_token> -n <project-name>
  ```

### 3. 项目初始化与关联
在前端项目根目录下运行，用于绑定云端 Pages 项目：
```bash
# 初始化生成配置文件
edgeone pages init

# 关联现有云端项目，或交互式创建新项目
edgeone pages link
```

### 4. 本地开发与调试
启动本地模拟环境，同时支持前端静态资源和 Serverless 函数的本地调试：
```bash
edgeone pages dev
```
- 默认服务端口为 `8088`。
- 本地调试支持自动挂载项目根目录下的 `edge-functions/` 和 `cloud-functions/`。
- 拉取云端环境变量到本地：
  ```bash
  edgeone pages env pull
  ```

### 5. 项目部署
将本地构建后的静态目录发布至 EdgeOne Pages：
- **部署至生产环境**：
  ```bash
  edgeone pages deploy ./dist
  ```
- **部署至预览/测试环境**：
  ```bash
  edgeone pages deploy ./dist -e preview
  ```

---

## 三、 `edgeone.json` 详细配置参考 (Configuration Specification)

`edgeone.json` 放在前端项目的根目录下，用于声明构建规则、路由重定向、重写、HTTP 自定义头部信息、云函数限制以及 Cron 定时触发器。

### 1. 字段说明汇总

| 字段名 | 类型 | 说明 | 示例 |
| --- | --- | --- | --- |
| `buildCommand` | `string` | 构建命令，用于云端构建时打包资源。 | `"npm run build"` |
| `installCommand` | `string` | 依赖安装命令，自定义包管理工具。 | `"pnpm install"` |
| `outputDirectory` | `string` | 静态资源导出的目录。 | `"dist"` |
| `nodeVersion` | `string` | 云端构建时所使用的 Node.js 版本。支持 `18.20.4`、`20.18.0`、`22.11.0` 等。 | `"22.11.0"` |
| `redirects` | `array` | HTTP 重定向规则列表（最多支持 100 条）。 | 见下文 |
| `rewrites` | `array` | URL 重写规则列表（最多支持 100 条）。仅用于静态资源。 | 见下文 |
| `headers` | `array` | HTTP 自定义头部信息配置列表。 | 见下文 |
| `cloudFunctions` | `object` | 动态云函数的运行配置（超时时间、区域映射等）。 | 见下文 |
| `schedules` | `array` | Cron 定时任务配置，用于周期性触发特定函数路径。 | 见下文 |

### 2. 配置示例与规则

#### A. 重定向规则 (`redirects`)
支持 `301` 永久重定向或 `302` 临时重定向。
```json
{
  "redirects": [
    {
      "source": "/old-blog/:slug",
      "destination": "/blog/:slug",
      "statusCode": 301
    },
    {
      "source": "/help-center",
      "destination": "/support",
      "statusCode": 302
    }
  ]
}
```

#### B. 重写规则 (`rewrites`)
重写用于内部路径映射，浏览器地址栏的 URL 不会改变。
> [!IMPORTANT]
> `rewrites` 规则仅对**静态资源路径**生效。单页应用（SPA）的前端路由跳转（如 React Router/Vue Router）属于客户端行为，应当在前端代码中配置，而非通过 `rewrites` 重写。
```json
{
  "rewrites": [
    {
      "source": "/images/*",
      "destination": "/static/images/:splat"
    }
  ]
}
```

#### C. 自定义 HTTP 头部 (`headers`)
可为特定路径的请求注入安全头部或缓存策略。
```json
{
  "headers": [
    {
      "source": "/**/*.js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/*",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        }
      ]
    }
  ]
}
```

#### D. 云函数运行配置 (`cloudFunctions`)
- `maxDuration`：单次云函数最大执行时间（超时时间），最高支持 `120` 秒。适用于处理长时间运行的流式大模型 API 接口（SSE）。
- `mainlandRegions` / `overseasRegions`：指定在境内与境外的部署数据中心节点（如 `ap-guangzhou`、`ap-singapore`）。
- `includeFiles`：打包部署时额外包含的配置文件或静态模板。
```json
{
  "cloudFunctions": {
    "maxDuration": 60,
    "mainlandRegions": ["ap-guangzhou"],
    "overseasRegions": ["ap-singapore"],
    "includeFiles": ["templates/*.html", "config/settings.json"]
  }
}
```

#### E. 定时任务触发器 (`schedules`)
定义基于 Cron 表达式的后台任务，定期自动请求指定的 API 路径：
```json
{
  "schedules": [
    {
      "cron": "0 0 * * *",
      "path": "/api/daily-report"
    }
  ]
}
```

---

## 四、 边缘函数与云函数架构 (Serverless Functions)

EdgeOne Pages 采用云边一体架构，包含两套独立的无服务器函数系统：

| 维度 | 边缘函数 (Edge Functions) | 云函数 (Cloud Functions) |
| --- | --- | --- |
| **执行节点** | 全球数百个 EdgeOne 边缘节点（就近计算） | 腾讯云中心数据中心 |
| **冷启动延迟** | **近乎 0 毫秒** (V8 Isolate 隔离技术) | 稍高（取决于容器加载与初始化） |
| **超时限制** | 极短时间限制 | 最长可达 120 秒 (支持复杂计算) |
| **运行语言环境** | 纯标准 JavaScript (支持标准 Web Worker API) | Node.js, Python, Go 等 |
| **存储绑定** | KV 存储、Blob 存储 | Blob 存储 |
| **主要应用场景** | 头部改写、A/B测试、轻量路由转发、CORS注入 | 数据库查询、复杂第三方 API 调用、大模型SSE流式输出 |

### 目录结构与放置规则
在代码库中，这两个目录**必须存放在项目的根目录**中，即与 `package.json` 同级：

```text
my-project/
├── edge-functions/          # 边缘函数源码目录
│   └── api/
│       └── welcome.js       # 映射路径为 https://<domain>/api/welcome
├── cloud-functions/         # 云函数源码目录
│   └── api/
│       └── llm.js           # 映射路径为 https://<domain>/api/llm
├── edgeone.json             # 配置文件
└── package.json
```

#### ⚠️ CLI 手动打包规则：
1. **自动构建部署模式**：当直接把目录托管给 Git 或直接使用 CLI 打包（CLI 运行构建命令）时，Pages 会在项目根目录下自动寻找并编译这两个目录。
2. **手动编译部署模式**：如果你手动运行构建（例如：本地执行 `npm run build` 输出到 `./dist`，然后通过 `edgeone pages deploy ./dist` 上传静态文件包），你**必须**在上传前手动将 `edge-functions/` 和 `cloud-functions/` 目录以及 `package.json` 复制到 `./dist` 目录中，否则云端只会收到静态前端资源，API 路由将全部报 404 错误。

---

## 五、 内置存储服务 (Integrated Storage)

EdgeOne Pages 提供了开箱即用的分布式存储系统，方便函数读写持久化状态。

### 1. KV 存储 (Key-Value)
- **特点**：高性能、最终一致性读取（边缘节点缓存可能存在最长 60 秒的更新延迟）。
- **空间限制**：单条 Key 长度最大为 512 字节，Value 大小上限为 25 MB。
- **适用场景**：全局计数器、配置开关、用户会话 Session State。

### 2. Blob 存储 (Object Store)
- **特点**：分布式对象存储，支持创建虚拟子目录结构，支持“强一致性读取”与“最终一致性读取”切换。
- **适用场景**：文件上传托管、大型 JSON 数据结构包、动态图片或媒体资产。

---

## 六、 可观测性与域名解析 (Observability & Domains)

### 1. 域名与安全 (SSL)
- **分配域名**：每个 Pages 项目会自动分配一个免费二级域名：`*.edgeone.app`。
- **自定义域名**：支持绑定自有域名。在控制台添加域名后，将自有域名的 CNAME 解析记录指向 Pages 分配的专属 CNAME 地址。
- **免费 SSL**：绑定自定义域名后，系统可自动申请、部署并到期自动续签 Let's Encrypt 证书。

### 2. 运行监控 (Observability)
- **多维度分析**：提供页面请求次数、4xx/5xx 状态码分布、边缘节点分发流量、函数冷启动时间与处理时延图表。
- **日志审计**：支持导出边缘运行日志；控制台可直接检索边缘函数控制台输出（`console.log`）及未捕获错误堆栈。
