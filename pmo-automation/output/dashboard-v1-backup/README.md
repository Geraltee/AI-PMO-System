# PMO Dashboard - OneDrive 信息检索增强版

## 📋 更新内容

本次更新在 Dashboard 最上侧新增了**OneDrive 文档信息检索模块**，实现企业文档的智能检索与调取。

## ✨ 核心功能

### 1. OneDrive 集成
- **管理员配置**: 支持手动添加多个 OneDrive 文档库 URL
- **自动扫描**: 定期扫描 OneDrive 文档，建立全文索引
- **内容读取**: 支持 Word、Excel、PowerPoint、PDF、OneNote 等格式

### 2. 智能检索
- **关键词搜索**: 类似谷歌学术/知网的关键词匹配
- **自然语言提问**: 支持用自然语言提问，自动提取关键词
- **高级筛选**: 按文件类型、日期范围、元数据等条件筛选

### 3. 检索逻辑
- **相关性排序**: 基于标题匹配、内容匹配、修改时间等维度计算相关性
- **语义理解**: 识别问题类型（what/how/why/when/who），优化搜索结果
- **智能摘要**: 自动生成答案摘要，快速定位关键信息

## 🚀 使用方式

### 基本搜索
1. 在搜索框输入关键词或问题
2. 点击"🔍 搜索"或按回车键
3. 查看搜索结果，点击文档打开

### 搜索模式切换
- **关键词搜索**: 适合精确查找特定文档
- **自然语言提问**: 适合询问问题，如"AI 客服项目的技术架构是什么？"
- **高级选项**: 配置 OneDrive URL 和搜索参数

### OneDrive 配置
1. 点击"高级选项"标签
2. 输入 OneDrive 文档库 URL（管理员权限）
3. 点击"💾 保存配置"
4. 点击"📡 扫描文档"建立索引

## 📁 文件结构

```
D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval\
├── index.html                      # 主页面（含检索模块）
├── onedrive-retrieval-api.js       # OneDrive 检索 API 服务
├── onedrive-config.json            # OneDrive 配置（运行时生成）
└── document-index.json             # 文档索引（运行时生成）
```

## 🔧 技术实现

### 前端功能
- 响应式搜索界面
- 实时搜索反馈
- 结果高亮显示
- 文档预览支持

### 后端 API（待实现）
```javascript
// 添加 OneDrive URL
POST /api/onedrive/add
{
  "url": "https://your-company.sharepoint.com/sites/PMO",
  "name": "PMO 文档库"
}

// 扫描文档
POST /api/onedrive/scan

// 关键词搜索
GET /api/search/keyword?q=AI 客服&mode=keyword

// 自然语言搜索
GET /api/search/natural?q=AI 客服项目的技术架构是什么？

// 读取文档内容
GET /api/document/:id/content
```

### Microsoft Graph API 集成
实际部署时需要调用 Microsoft Graph API：
- 认证：OAuth 2.0（管理员权限）
- 扫描：`GET /sites/{site-id}/drive/root/children`
- 读取：`GET /sites/{site-id}/drive/items/{item-id}/content`
- 搜索：`GET /search/query`

## 📊 检索算法

### 相关性评分
```
得分 = 标题匹配 (5 分) + 内容匹配 (2 分) + 最近修改 (1-3 分)
```

### 问题类型识别
- **what**（什么/哪些）: 优先返回内容丰富的文档
- **how**（怎么/如何）: 优先返回方案、技术类文档
- **why**（为什么）: 优先返回分析报告、决策文档
- **when**（何时）: 优先返回计划、时间表类文档
- **who**（谁/哪个）: 优先返回人员、组织相关文档

## 🎯 使用场景

1. **项目文档查找**: "查找 AI 客服项目的需求文档"
2. **技术方案检索**: "CRM 系统迁移的技术方案是什么？"
3. **数据分析**: "上个季度的项目交付数据"
4. **会议纪要**: "3 月份的项目评审会议纪要"
5. **合同文件**: "供应商合同模板"

## ⚙️ 配置说明

### 管理员权限
需要 Microsoft 365 管理员权限，授予以下权限：
- `Sites.Read.All` - 读取所有站点文档
- `Files.Read.All` - 读取所有文件
- `User.Read` - 读取用户信息

### 安全考虑
- 文档索引存储在本地，不上传外部服务器
- 支持配置访问控制列表（ACL）
- 敏感文档可设置访问权限

## 📝 更新日志

**2026-04-06**
- ✅ 新增 OneDrive 文档检索模块
- ✅ 支持关键词搜索和自然语言提问
- ✅ 实现文档扫描与索引功能
- ✅ 添加高级搜索选项
- ✅ 优化搜索结果排序算法

## 🔮 后续优化

- [ ] 集成真实的 Microsoft Graph API
- [ ] 支持文档内容全文检索（OCR for PDF）
- [ ] 添加文档预览功能
- [ ] 支持多语言检索
- [ ] 实现智能推荐（相关文档推荐）
- [ ] 添加搜索历史记录
- [ ] 支持批量文档操作

## 📞 技术支持

如有问题或建议，请联系 PMO 系统管理员。

---

**最后更新**: 2026-04-06 08:58 EDT  
**版本**: v2.0 (OneDrive 检索增强版)
