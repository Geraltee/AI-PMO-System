# AI PMO - 部署到云端指南

## 🌐 方案 1：Azure Static Web Apps（推荐，免费）

### 步骤：

1. **准备文件**
   ```powershell
   cd D:\AI-PMO-System\pmo\web
   ```

2. **创建 GitHub 仓库**
   - 访问 https://github.com
   - 新建仓库 `ai-pmo-dashboard`
   - 上传 `web` 目录内容

3. **部署到 Azure**
   - 访问 https://portal.azure.com
   - 创建 Static Web App
   - 连接 GitHub 仓库
   - 获取公网 URL

---

## 🌐 方案 2：Vercel（最简单，免费）

### 步骤：

1. 访问 https://vercel.com
2. 用 GitHub 账号登录
3. 导入项目
4. 自动部署，获取公网 URL

---

## 🌐 方案 3：公司内网服务器

### 如果有内网 Web 服务器：

1. **复制文件到服务器**
   ```
   目标位置：\\内网服务器\www\pmo\
   ```

2. **配置 IIS/Apache**
   - 设置网站根目录
   - 开放端口访问

3. **Teams 中访问内网 URL**
   ```
   http://内网服务器/pmo
   ```

---

## 🌐 方案 4：Ngrok 内网穿透（临时测试）

### 步骤：

1. **下载 Ngrok**
   ```
   https://ngrok.com/download
   ```

2. **启动 Flask 服务器**
   ```powershell
   cd D:\AI-PMO-System\pmo\web
   python server.py
   ```

3. **启动 Ngrok**
   ```powershell
   ngrok http 5000
   ```

4. **获取公网 URL**
   ```
   https://xxxx.ngrok.io
   ```

5. **Teams 中使用该 URL**

---

## 🌐 方案 5：SharePoint 页面嵌入

### 步骤：

1. **导出为 HTML**
   - 已有 `dashboard.html`

2. **上传到 SharePoint**
   - 访问公司 SharePoint
   - 上传到文档库

3. **在 Teams 频道添加**
   - Teams → 频道 → 文件
   - 直接访问 HTML 文件

---

## 📋 Teams 添加标签页步骤

1. **打开 Teams**
2. **选择频道**
3. **点击 + 添加标签页**
4. **选择"网站"**
5. **输入 URL**（公网或内网）
6. **命名标签页**（如"PMO 仪表板"）
7. **保存**

---

## 🎯 推荐方案对比

| 方案 | 难度 | 成本 | 速度 | 推荐 |
|------|------|------|------|------|
| Ngrok | ⭐ | 免费 | 快 | 临时测试 |
| Vercel | ⭐⭐ | 免费 | 快 | 个人使用 |
| Azure | ⭐⭐⭐ | 免费额度 | 中 | 企业使用 |
| 内网服务器 | ⭐⭐ | 已有 | 快 | 公司内部 |
| SharePoint | ⭐ | 已有 | 快 | 最简单 |

---

## 💡 最快方案：SharePoint

1. 复制 `dashboard.html` 到 SharePoint 文档库
2. Teams 频道 → 文件 → 直接打开
3. 无需额外配置！

---

**位置：** `D:\AI-PMO-System\pmo\deploy\README.md`
