# 🌐 AI PMO Web 服务器 - 使用指南

## 📦 方案 1：Python Flask（推荐）⭐

### 第一步：安装 Python（如果没有）

1. 访问 https://www.python.org/downloads/
2. 下载并安装 Python 3.8+
3. 安装时勾选 "Add Python to PATH"

### 第二步：安装依赖

```powershell
cd D:\AI-PMO-System\pmo\web
pip install -r requirements.txt
```

### 第三步：启动服务器

```powershell
python server.py
```

### 第四步：访问仪表板

浏览器打开：**http://localhost:5000**

---

## 📦 方案 2：快速测试（无需安装）

直接双击打开 HTML 文件：

```
D:\AI-PMO-System\pmo\web\dashboard.html
```

⚠️ 注意：此方式显示的是**示例数据**，不会读取真实项目文件。

---

## 📦 方案 3：PowerShell 简单服务器

```powershell
cd D:\AI-PMO-System\pmo\web
python -m http.server 8080
```

访问：**http://localhost:8080/dashboard.html**

---

## 🔌 API 端点

启动 Python 服务器后，可用 API：

| 端点 | 说明 |
|------|------|
| `GET /` | 仪表板页面 |
| `GET /api/projects` | 获取所有项目 |
| `GET /api/projects/<ID>` | 获取单个项目 |
| `GET /api/stats` | 获取统计信息 |

### API 响应示例

```json
// GET /api/projects
{
  "success": true,
  "count": 1,
  "projects": [
    {
      "id": "PRJ-2026-001",
      "name": "AI 客服系统升级",
      "status": "green",
      "priority": "P1",
      "owner": "待填写",
      "progress": 0,
      "milestones": [...],
      "risks": [...]
    }
  ]
}
```

---

## 🎨 自定义仪表板

编辑文件：
```
D:\AI-PMO-System\pmo\web\dashboard.html
```

修改内容：
- **颜色主题**：修改 CSS 中的 `:root` 变量
- **布局**：调整 `.stats-grid` 和 `.projects-grid`
- **功能**：编辑 `<script>` 中的 JavaScript

---

## 📱 在 Teams 中嵌入

### 方法 1：添加网站标签页

1. Teams 频道 → 添加标签页 (+)
2. 选择"网站"
3. 输入：`http://localhost:5000`（本地测试）
   或部署后的公网 URL

### 方法 2：部署到云端

**选项：**
- Azure Static Web Apps（免费）
- GitHub Pages（免费）
- Vercel（免费）
- 公司内网服务器

部署后，Teams 中访问公网 URL。

---

## 🚀 快速启动脚本

创建 `start.bat`：

```batch
@echo off
echo Starting AI PMO Web Server...
cd /d D:\AI-PMO-System\pmo\web
python server.py
pause
```

双击运行即可启动！

---

## 📊 功能对比

| 功能 | 纯 HTML | Flask 服务器 |
|------|---------|-------------|
| 显示项目 | ❌ 示例数据 | ✅ 真实数据 |
| 自动更新 | ❌ 手动刷新 | ✅ API 实时读取 |
| 搜索筛选 | ✅ 支持 | ✅ 支持 |
| 项目详情 | ✅ 弹窗 | ✅ 弹窗 |
| 数据持久化 | ❌ | ✅ Markdown 文件 |
| 安装难度 | ⭐ 无 | ⭐⭐ Python |

---

## 💡 推荐工作流程

```
1. 编辑项目文件
   ↓
   D:\AI-PMO-System\pmo\projects\*.md
   ↓
2. Flask 服务器自动读取
   ↓
3. 浏览器访问 http://localhost:5000
   ↓
4. 看到最新项目状态
   ↓
5. （可选）Teams 中嵌入查看
```

---

## ❓ 常见问题

### Q: 端口 5000 被占用？
A: 修改 `server.py` 中的 `port=5000` 为其他端口

### Q: 中文乱码？
A: 确保文件保存为 UTF-8 编码

### Q: 如何添加新项目？
A: 用 PMO 脚本创建：`.\pmo-core.ps1 new "项目名"`
   刷新网页即可看到

---

**版本**: v0.1.0  
**位置**: `D:\AI-PMO-System\pmo\web\`
