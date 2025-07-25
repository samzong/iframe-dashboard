# iframe Dashboard

基于 Vue 3 + Go + MySQL 的多用户 iframe 管理工具。

## 功能特性

- **多用户管理**：基于 JWT 的用户身份验证，每个用户独立的 iframe 配置
- **标签切换**：支持多个 iframe 页面间的快速切换
- **响应式设计**：适配不同屏幕尺寸

## 技术栈

**后端**：Go 1.24 + Gin + GORM + MySQL  
**前端**：Vue 3 + TypeScript + Vue Router

## 快速开始

### 环境要求

- Go >= 1.24
- Node.js >= 16
- MySQL >= 8.0

### 本地开发

1. **启动后端**

```bash
cd backend
go mod tidy
docker-compose up -d mysql  # 启动数据库
go run .                    # 启动后端服务 (端口 8080)
```

2. **启动前端**

```bash
cd frontend
npm install
npm run serve              # 启动前端服务 (端口 8000)
```

### 使用 Makefile

```bash
make help                  # 查看所有可用命令
make debug                 # 启动后端调试模式
make frontend-dev          # 启动前端开发服务器
make check                 # 运行完整质量检查
```

## API 接口

### 认证

所有 API 请求需要在请求头中包含 JWT token：

```
Authorization: Bearer <jwt-token>
```

### 获取用户 iframe 列表

```http
GET /api/v1/iframes
```

### 健康检查

```http
GET /health
```

## 环境变量

**后端配置**：

- `DB_HOST`：数据库主机 (默认: localhost)
- `DB_PORT`：数据库端口 (默认: 3306)
- `DB_USER`：数据库用户名 (默认: root)
- `DB_PASSWORD`：数据库密码
- `DB_NAME`：数据库名称 (默认: iframe_dashboard)
- `PORT`：服务端口 (默认: 8080)

## 数据库结构

### iframe_configs 表

| 字段       | 类型         | 说明            |
| ---------- | ------------ | --------------- |
| id         | VARCHAR(50)  | iframe 唯一标识 |
| title      | VARCHAR(200) | 显示标题        |
| url        | TEXT         | iframe 源地址   |
| user_uuid  | VARCHAR(36)  | 用户唯一标识    |
| status     | VARCHAR(20)  | 状态            |
| created_at | TIMESTAMP    | 创建时间        |
| updated_at | TIMESTAMP    | 更新时间        |

## 开发工具

项目包含完整的开发工具链：

- **代码格式化**：`make fmt`
- **代码检查**：`make lint`
- **测试**：`make test`
- **Git 钩子**：`make install-hooks`

## 许可证

MIT License
