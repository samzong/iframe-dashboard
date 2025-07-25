# iframe Dashboard

> 基于 Vue 3 + Go + MySQL 的 iframe 看板管理工具

## 项目概述

iframe Dashboard 是一个简洁的 iframe 内容管理工具。该工具采用前后端分离架构，支持多用户场景下的个性化 iframe 内容管理，并提供代理服务来解决跨域和安全问题。

### 核心功能

- **多用户 iframe 管理**：基于 JWT token 的用户身份验证，每个用户拥有独立的 iframe 配置
- **代理服务**：HTTP/HTTPS 代理功能，解决 iframe 嵌入的跨域和安全限制
- **实时标签切换**：支持多个 iframe 页面间的快速切换
- **响应式设计**：适配不同屏幕尺寸的设备

## 技术栈

### 后端技术栈

- **Go 1.24**：主要编程语言
- **Gin Framework**：Web 框架，提供高性能的 HTTP 服务
- **GORM**：ORM 框架，简化数据库操作
- **MySQL 8.0**：关系型数据库
- **JWT**：用户身份验证
- **Docker**：容器化部署

### 前端技术栈

- **Vue 3**：前端框架，使用 Composition API
- **TypeScript**：类型安全的 JavaScript 超集
- **Vue Router 4**：前端路由管理
- **SCSS**：CSS 预处理器
- **Nginx**：静态资源服务器

## 项目结构

```
iframe-dashboard/
├── backend/                 # 后端服务
│   ├── main.go             # 主程序入口
│   ├── models.go           # 数据模型定义
│   ├── database.go         # 数据库连接和操作
│   ├── init.sql            # 数据库初始化脚本
│   ├── docker-compose.yml  # Docker Compose 配置
│   ├── Dockerfile          # 后端 Docker 镜像配置
│   └── go.mod              # Go 模块依赖
├── frontend/               # 前端应用
│   ├── src/                # 源代码
│   │   ├── App.vue         # 主应用组件
│   │   ├── types/          # TypeScript 类型定义
│   │   ├── router/         # 路由配置
│   │   └── views/          # 页面组件
│   ├── public/             # 静态资源
│   ├── Dockerfile          # 前端 Docker 镜像配置
│   ├── package.json        # 前端依赖配置
│   └── vue.config.js       # Vue 构建配置
└── README.md               # 项目文档
```

## 快速开始

### 环境要求

- **Node.js** >= 16.13.2
- **Go** >= 1.24
- **MySQL** >= 8.0
- **Docker** (可选，用于容器化部署)

### 本地开发

#### 1. 克隆项目

```bash
git clone <repository-url>
cd iframe-dashboard
```

#### 2. 启动后端服务

```bash
cd backend

# 安装依赖
go mod tidy

# 配置数据库（使用 docker-compose）
docker-compose up -d mysql

# 等待数据库启动后，运行后端服务
go run .
```

#### 3. 启动前端服务

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run serve
```

#### 4. 访问应用

- 前端应用：http://localhost:8000
- 后端 API：http://localhost:8080
- API 健康检查：http://localhost:8080/health

### Docker 部署

#### 1. 使用 Docker Compose（推荐）

```bash
cd backend
docker-compose up -d
```

这将启动：

- MySQL 数据库（端口 3307）
- 后端服务（端口 30081）

#### 2. 单独构建镜像

**构建后端镜像：**

```bash
cd backend
docker build -t drun-backend .
```

**构建前端镜像：**

```bash
cd frontend
docker build -t drun-frontend .
```

## API 接口

### 认证

所有 API 请求需要在请求头中包含 JWT token：

```
Authorization: Bearer <your-jwt-token>
```

### 接口列表

#### 获取用户 iframe 列表

```http
GET /api/v1/iframes
Authorization: Bearer <jwt-token>
```

**响应示例：**

```json
{
  "success": true,
  "data": [
    {
      "id": "appsmith",
      "title": "运营看板",
      "url": "https://example.com/proxy?url=http%3A//124.70.131.166%3A8080/app/operator/page1-685bab80355d7571d32052b6",
      "user_uuid": "85eef8ab-6106-48dd-825e-c661a17cefca"
    }
  ],
  "message": "Success"
}
```

#### 代理服务

```http
GET /proxy?url=<target-url>
POST /proxy?url=<target-url>
# 支持所有 HTTP 方法
```

**功能：**

- 代理 HTTP 请求到目标 URL
- 移除 X-Frame-Options 头部限制
- 添加 CORS 支持
- 设置宽松的 CSP 策略

#### 健康检查

```http
GET /health
```

**响应：**

```json
{
  "status": "healthy",
  "service": "iframe-dashboard-backend"
}
```

## 配置说明

### 后端环境变量

| 变量名        | 默认值           | 说明           |
| ------------- | ---------------- | -------------- |
| `DB_HOST`     | localhost        | 数据库主机地址 |
| `DB_PORT`     | 3306             | 数据库端口     |
| `DB_USER`     | root             | 数据库用户名   |
| `DB_PASSWORD` | -                | 数据库密码     |
| `DB_NAME`     | iframe_dashboard | 数据库名称     |
| `PORT`        | 8080             | 服务端口       |

### 前端环境变量

| 变量名                     | 说明                  |
| -------------------------- | --------------------- |
| `VUE_APP_PUBLIC_BASE_PATH` | API 基础路径          |
| `VUE_APP_TOKEN`            | JWT Token（开发环境） |
| `VUE_APP_ROUTER_BASE_PATH` | 路由基础路径          |

## 数据库结构

### iframe_configs 表

| 字段名       | 类型         | 说明                    |
| ------------ | ------------ | ----------------------- |
| `id`         | VARCHAR(50)  | 主键，iframe 唯一标识   |
| `title`      | VARCHAR(200) | iframe 显示标题         |
| `url`        | TEXT         | iframe 源地址           |
| `user_uuid`  | VARCHAR(36)  | 用户唯一标识            |
| `status`     | VARCHAR(20)  | 状态（active/inactive） |
| `created_at` | TIMESTAMP    | 创建时间                |
| `updated_at` | TIMESTAMP    | 更新时间                |

**索引：**

- `idx_iframe_configs_status`：状态索引
- `idx_iframe_configs_title`：标题索引
- `idx_iframe_configs_user_uuid`：用户 UUID 索引

## 安全性

### JWT Token 处理

- 系统使用 JWT token 进行用户身份验证
- 后端解析 token 中的 `sub` 字段获取用户 UUID
- 当前实现不验证 token 签名（根据需求设计）

### 代理服务安全

- 代理服务移除 `X-Frame-Options` 限制
- 设置宽松的 CORS 策略
- 支持 HTTP 到 HTTPS 的安全代理

### 容器安全

- 后端容器使用非 root 用户运行
- 镜像基于 Alpine Linux，减少攻击面

## 部署建议

### 生产环境

1. **数据库配置**

   - 使用专用的 MySQL 实例
   - 配置适当的数据库连接池
   - 启用 SSL 连接

2. **服务配置**

   - 使用反向代理（Nginx/Traefik）
   - 配置 HTTPS 证书
   - 设置适当的资源限制

3. **监控和日志**
   - 配置应用监控
   - 设置日志收集和分析
   - 实施健康检查

### 扩展性考虑

- 支持水平扩展的无状态设计
- 数据库连接池配置
- 缓存策略（如需要）

## 故障排除

### 常见问题

1. **数据库连接失败**

   - 检查数据库服务是否启动
   - 验证环境变量配置
   - 确认网络连接

2. **前端无法连接后端**

   - 检查 CORS 配置
   - 验证 API 基础路径设置
   - 确认后端服务状态

3. **iframe 无法加载**
   - 检查目标 URL 的可访问性
   - 验证代理服务配置
   - 确认 CSP 策略设置

## 贡献指南

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过以下方式联系：

- 项目 Issues：[GitHub Issues](../../issues)
- 邮箱：[your-email@example.com](mailto:your-email@example.com)
