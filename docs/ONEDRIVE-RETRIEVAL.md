# 📚 OneDrive 信息检索模块 - 实现文档

## 功能概述

在 PMO Dashboard 底部新增信息检索模块，对接公司内部 OneDrive，支持：
- ✅ 文档链接存储与扫描
- ✅ 内容读取与索引
- ✅ 关键词搜索
- ✅ 自然语言提问
- ✅ 精准筛选与调取匹配文档

---

## 文件结构

```
D:\AI-PMO-System\
├── pmo\
│   ├── web\
│   │   ├── dashboard.html          # 主界面（已添加检索模块 HTML）
│   │   ├── retrieval-module.css    # 检索模块样式
│   │   └── retrieval-module.js     # 前端交互逻辑
│   ├── config\
│   │   └── email-config.json       # 邮箱配置
│   └── scripts\
│       ├── test-imap.ps1           # IMAP 测试脚本
│       └── send-test-email.ps1     # 邮件发送测试
├── pmo-automation\
│   ├── api\
│   │   └── retrieval-api.js        # OneDrive 检索 API 服务
│   ├── output\
│   │   └── project-dashboard.html  # 项目仪表板
│   └── data\
│       └── timeline-tracking.json  # 项目时间线追踪
└── docs\
    └── ONEDRIVE-RETRIEVAL.md       # 本文档
```

---

## 部署步骤

### 1. 前端集成（已完成）

检索模块已添加到 `pmo/web/dashboard.html` 底部，包含：
- 搜索输入框
- 搜索模式切换（关键词/自然语言）
- 结果显示区域
- OneDrive 连接状态指示器
- 快捷搜索链接

### 2. 后端 API 配置

**安装依赖：**
```bash
cd D:\AI-PMO-System\pmo-automation
npm install express @microsoft/microsoft-graph-client @azure/identity
```

**环境变量配置：**
创建 `.env` 文件：
```env
# OneDrive/Microsoft Graph API 配置
ONEDRIVE_TENANT_ID=your-tenant-id
ONEDRIVE_CLIENT_ID=your-client-id
ONEDRIVE_CLIENT_SECRET=your-client-secret

# 服务端口
API_PORT=3000
```

### 3. Azure AD 应用注册

1. 访问 https://portal.azure.com
2. 进入 **Azure Active Directory** → **应用注册**
3. 创建新应用，记录：
   - 应用程序 (客户端) ID
   - 目录 (租户) ID
4. 创建客户端密码
5. 添加 API 权限：
   - `Files.Read` - 读取 OneDrive 文件
   - `Files.Read.All` - 读取所有 OneDrive 文件
   - `Sites.Read.All` - 读取 SharePoint 站点

### 4. 启动 API 服务

```bash
node D:\AI-PMO-System\pmo-automation\api\retrieval-api.js
```

---

## API 端点

### 🔍 搜索文档
```
GET /api/retrieval/search?q=关键词&mode=keyword|natural&limit=20
```

**响应示例：**
```json
{
  "query": "AI 客服",
  "mode": "keyword",
  "total": 5,
  "results": [
    {
      "id": "01ABC123",
      "title": "AI 智能客服系统需求文档 v2.0",
      "snippet": "本文档详细描述了...",
      "source": "OneDrive/Projects/AI-Customer-Service/",
      "date": "2026-04-02",
      "type": "docx",
      "url": "https://company-my.sharepoint.com/..."
    }
  ]
}
```

### 💬 自然语言提问
```
POST /api/retrieval/query
Content-Type: application/json

{
  "question": "AI 客服项目的需求文档在哪里？",
  "context": {
    "projectId": "PRJ-2026-001"
  }
}
```

**响应示例：**
```json
{
  "question": "AI 客服项目的需求文档在哪里？",
  "keywords": ["AI", "客服", "需求", "文档"],
  "answer": "找到 5 个相关文档。最相关的是：AI 智能客服系统需求文档 v2.0、客服系统技术架构设计...",
  "sources": [...],
  "total": 5
}
```

### 📄 获取文档内容
```
GET /api/retrieval/document/:id
```

---

## 前端使用

### 搜索模式

1. **关键词搜索**：直接输入关键词，如 `AI 客服 需求`
2. **自然语言提问**：输入完整问题，如 `AI 客服项目的需求文档在哪里？`

### 快捷链接

点击预设快捷链接快速搜索：
- 📄 需求文档
- 🏗️ 技术架构
- 📊 项目计划
- 📈 市场报告

---

## 安全注意事项

1. **不要硬编码凭据** - 使用环境变量
2. **限制 API 访问** - 添加身份验证中间件
3. **速率限制** - 防止滥用
4. **审计日志** - 记录搜索和访问行为

---

## 当前状态

| 组件 | 状态 | 备注 |
|------|------|------|
| 前端 UI | ✅ 完成 | 已集成到 dashboard.html |
| 前端逻辑 | ✅ 完成 | retrieval-module.js |
| 样式 | ✅ 完成 | retrieval-module.css |
| 后端 API | ✅ 完成 | retrieval-api.js（含 Mock 数据） |
| OneDrive 连接 | ⏳ 待配置 | 需要 Azure AD 应用注册 |
| 文档索引 | ⏳ 待实现 | 需要 Graph API 权限 |

---

## 下一步

1. **配置 Azure AD 应用** - 获取 OneDrive API 访问权限
2. **测试真实连接** - 替换 Mock 数据为真实 API 调用
3. **添加文档预览** - 支持在线查看文档内容
4. **实现智能排序** - 基于相关性和使用时间排序结果
5. **添加收藏功能** - 用户可收藏常用文档

---

*文档创建：2026-04-05*
*版本：1.0*
