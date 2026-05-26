# AI PMO - Microsoft 365 插件部署指南

---

## 📦 文件结构

```
m365/
├── manifest.xml        # 插件配置
├── taskpane.html       # 主界面（所有功能）
├── commands.html       # 后台命令（可选）
└── README.md           # 本文件
```

---

## 🚀 快速部署（3 步）

### 第 1 步：启动本地服务器

```powershell
cd D:\AI-PMO-System\pmo\m365
python -m http.server 3000
```

或使用 Node.js：
```powershell
npx http-server -p 3000
```

### 第 2 步：上传插件到 Microsoft 365

**方式 A：组织管理员部署（推荐）**

1. 访问 https://admin.microsoft.com
2. 设置 → 集成应用程序 → 加载项
3. 点击"+" → 上传 `manifest.xml`
4. 分配给用户/组

**方式 B：个人使用**

1. 打开 Excel/Word Online
2. 插入 → 加载项 → 管理我的加载项
3. 点击"+" → 上传 `manifest.xml`
4. 确定

### 第 3 步：使用插件

1. 打开 Excel/Word
2. 点击"开始"选项卡 → "AI PMO 组" → "打开 PMO"
3. 右侧面板打开，开始使用

---

## ✨ 核心功能

### 1️⃣ 概览
- 项目统计
- 快速访问项目列表

### 2️⃣ 新建项目
- 手动输入创建
- AI 解析文本创建

### 3️⃣ OneDrive 文件读取
- 输入 OneDrive/SharePoint URL
- 自动读取文件内容
- AI 解析提取项目信息

### 4️⃣ 项目管理
- 查看所有项目
- 点击查看详情

### 5️⃣ 预警
- 风险项目列表
- 待处理事项

---

## 🔗 OneDrive URL 获取方法

### 从 OneDrive 网页版：

1. 访问 https://onedrive.live.com 或公司 SharePoint
2. 打开文件
3. 复制浏览器地址栏 URL
4. 粘贴到插件的"OneDrive 文件 URL"框

### URL 格式示例：

```
https://[公司].sharepoint.com/sites/[团队]/Shared Documents/项目文档/项目计划.docx
```

### 权限要求：

- 文件必须对当前用户有访问权限
- 如果是外部链接，需要公开访问权限

---

## 🛠️ 开发调试

### 修改代码后：

1. 保存 `taskpane.html`
2. 刷新 Office 应用中的插件（关闭重开）
3. 或按 F5 刷新任务窗格

### 查看日志：

- 按 F12 打开开发者工具
- 查看 Console 标签

---

## 📤 发布到应用商店

### 准备：

1. 部署到 HTTPS 服务器（Azure/AWS/公司服务器）
2. 准备图标文件（16/32/80px）
3. 修改 `manifest.xml` 中的 URL

### 提交：

1. 访问 https://partnercenter.microsoft.com
2. 创建新加载项
3. 上传 manifest.xml
4. 提交审核

---

## ⚠️ 注意事项

| 问题 | 解决 |
|------|------|
| 插件不显示 | 检查 manifest.xml 语法 |
| URL 无法访问 | 确保 HTTPS 且证书有效 |
| OneDrive 读取失败 | 检查文件权限 |
| 跨域错误 | 配置 CORS 或使用代理 |

---

## 💡 高级功能（后续）

- [ ] Microsoft Graph API 集成（直接读取 OneDrive）
- [ ] Teams 聊天机器人
- [ ] Outlook 邮件解析
- [ ] Planner 任务同步
- [ ] Power Automate 工作流

---

**位置：** `D:\AI-PMO-System\pmo\m365\README.md`  
**版本：** v1.0
