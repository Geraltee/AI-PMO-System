# OneDrive 文档库配置要求

## 📋 前提条件

### 1. Microsoft 365 账号要求

| 要求 | 说明 |
|------|------|
| **账号类型** | Microsoft 365 商业版/企业版账号 |
| **权限级别** | 需要 OneDrive/SharePoint 管理员权限或文档库所有者权限 |
| **订阅计划** | Business Basic 及以上版本 |

### 2. 需要的权限

**最小权限要求**:
- `Sites.Read.All` - 读取所有站点文档
- `Files.Read.All` - 读取所有文件
- `User.Read` - 读取用户基本信息

**推荐权限**（如需完整功能）:
- `Sites.ReadWrite.All` - 读写所有站点文档
- `Files.ReadWrite.All` - 读写所有文件
- `offline_access` - 离线访问（刷新令牌）

---

## 🔧 配置步骤

### 步骤一：获取 OneDrive/SharePoint URL

**OneDrive for Business**:
```
https://[your-company]-my.sharepoint.com/personal/[username]_[domain]_com/Documents
```

**SharePoint 文档库**:
```
https://[your-company].sharepoint.com/sites/[site-name]/Shared Documents/[folder-name]
```

**示例**:
```
https://contoso.sharepoint.com/sites/PMO/Shared Documents/Project Documents
```

### 步骤二：Azure AD 应用注册

1. 登录 [Azure Portal](https://portal.azure.com)
2. 导航到 **Azure Active Directory** → **应用注册**
3. 点击 **新注册**
4. 填写信息:
   - 名称：`PMO Dashboard`
   - 支持的账户类型：`仅组织目录中的账户`
   - 重定向 URI：`http://localhost:3000/auth/callback`

5. 注册后记录以下信息:
   - **应用程序 (客户端) ID**
   - **目录 (租户) ID**

### 步骤三：配置 API 权限

1. 在应用注册页面，点击 **API 权限**
2. 点击 **添加权限** → **Microsoft Graph**
3. 选择 **应用程序权限**
4. 添加以下权限:
   - `Sites.Read.All`
   - `Files.Read.All`
   - `User.Read`

5. 点击 **授予管理员同意**

### 步骤四：创建客户端密钥

1. 在应用注册页面，点击 **证书和密钥**
2. 点击 **新客户端密钥**
3. 填写描述和过期时间
4. **立即复制密钥值**（只显示一次）

### 步骤五：配置 Dashboard

在 Dashboard 中:
1. 点击 **高级选项** 标签
2. 输入 OneDrive 文档库 URL
3. 点击 **保存配置**
4. 输入 Azure AD 应用信息:
   - 客户端 ID
   - 租户 ID
   - 客户端密钥

---

## 📁 文档库结构建议

```
OneDrive/SharePoint/
├── Projects/
│   ├── AI-Customer-Service/
│   │   ├── 01-Requirements/
│   │   ├── 02-Design/
│   │   ├── 03-Development/
│   │   └── 04-Testing/
│   ├── CRM-Migration/
│   └── Data-Platform/
├── Templates/
├── Reports/
└── Meeting-Notes/
```

---

## 🔐 安全最佳实践

### 1. 密钥管理
- ❌ **不要**将密钥硬编码在代码中
- ✅ **使用**环境变量或密钥管理服务
- ✅ **定期轮换**客户端密钥

### 2. 访问控制
- 限制应用只能访问特定文档库
- 使用最小权限原则
- 定期审计访问日志

### 3. 数据保护
- 启用多因素认证 (MFA)
- 使用条件访问策略
- 监控异常访问

---

## 🧪 测试连接

### PowerShell 测试脚本

```powershell
# 测试 OneDrive 连接
$tenantId = "your-tenant-id"
$clientId = "your-client-id"
$clientSecret = "your-client-secret"
$siteUrl = "https://your-company.sharepoint.com/sites/PMO"

# 获取访问令牌
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Body $body

$accessToken = $tokenResponse.access_token

# 测试连接
$headers = @{
    Authorization = "Bearer $accessToken"
}

$response = Invoke-RestMethod -Method Get `
    -Uri "https://graph.microsoft.com/v1.0/sites/$siteUrl" `
    -Headers $headers

Write-Host "连接成功！" -ForegroundColor Green
Write-Host "站点名称：$($response.displayName)"
Write-Host "站点 URL: $($response.webUrl)"
```

---

## ❓ 常见问题

### Q1: 提示"权限不足"？
**A**: 检查以下几点:
1. 确认账号有文档库访问权限
2. 确认 Azure AD 应用已授予管理员同意
3. 确认使用的是正确的租户 ID

### Q2: 无法获取访问令牌？
**A**: 检查:
1. 客户端 ID 和密钥是否正确
2. 租户 ID 是否正确
3. 应用注册中的重定向 URI 是否匹配

### Q3: 扫描不到文档？
**A**: 确认:
1. OneDrive URL 格式正确
2. 文档库不是私人 OneDrive（需要 SharePoint）
3. 应用有 `Files.Read.All` 权限

### Q4: 支持个人 OneDrive 吗？
**A**: 不支持。仅支持:
- OneDrive for Business
- SharePoint Online 文档库

个人 OneDrive 需要使用不同的认证流程（OAuth 2.0 授权码流）。

---

## 📞 技术支持

### 内部支持
- 联系公司 IT 部门获取 Azure AD 应用注册帮助
- 联系 SharePoint 管理员获取文档库权限

### Microsoft 文档
- [Microsoft Graph API 文档](https://docs.microsoft.com/graph/api/overview)
- [SharePoint REST API](https://docs.microsoft.com/sharepoint/dev/sp-add-ins/sharepoint-add-ins)
- [Azure AD 应用注册](https://docs.microsoft.com/azure/active-directory/develop/quickstart-register-app)

---

## 🎯 快速检查清单

配置前请确认:

- [ ] 有 Microsoft 365 商业版/企业版账号
- [ ] 有 OneDrive/SharePoint 管理员权限
- [ ] 已记录 OneDrive/SharePoint URL
- [ ] 已注册 Azure AD 应用
- [ ] 已记录客户端 ID 和租户 ID
- [ ] 已创建客户端密钥
- [ ] 已授予 API 权限
- [ ] 已测试连接

---

**版本**: v1.0  
**最后更新**: 2026-04-06  
**适用**: PMO Dashboard OneDrive 集成
