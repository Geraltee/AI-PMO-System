# 🚀 快速启动指南

## 1️⃣ 打开 Dashboard

**方法一：直接双击**
```
D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval\index.html
```

**方法二：浏览器访问**
```
file:///D:/AI-PMO-System/pmo-automation/output/dashboard-with-retrieval/index.html
```

## 2️⃣ 配置 OneDrive（管理员）

1. 点击 **"高级选项"** 标签
2. 输入 OneDrive 文档库 URL，例如：
   ```
   https://your-company.sharepoint.com/sites/PMO/Shared Documents
   ```
3. 点击 **"💾 保存配置"**
4. 点击 **"📡 扫描文档"** 建立索引

## 3️⃣ 开始搜索

### 关键词搜索
```
输入框：AI 客服项目
按回车或点击 🔍 搜索
```

### 自然语言提问
```
切换到 "自然语言提问" 标签
输入：AI 客服项目的技术架构是什么？
按回车或点击 🔍 搜索
```

### 高级筛选
```
切换到 "高级选项" 标签
勾选：
  ☑ 包含子文件夹
  ☑ 搜索文档内容
  ☐ 仅搜索元数据
```

## 4️⃣ 查看结果

搜索结果会显示：
- 📄 文档标题（蓝色高亮）
- 📝 内容摘要（包含关键词）
- 📁 来源路径
- 📅 修改日期
- 🏷️ 文件类型（DOCX/XLSX/PPTX/PDF）

**点击任意结果** 打开文档（需配置真实 OneDrive）

## 5️⃣ 使用 PowerShell 脚本（可选）

### 初始化配置
```powershell
cd "D:\AI-PMO-System\pmo-automation\output\dashboard-with-retrieval"
.\setup-onedrive-retrieval.ps1 -Action setup
```

### 添加 OneDrive URL
```powershell
.\setup-onedrive-retrieval.ps1 -Action add -OneDriveUrl "https://your-company.sharepoint.com/sites/PMO"
```

### 扫描文档
```powershell
.\setup-onedrive-retrieval.ps1 -ScanDocuments
```

### 查看统计
```powershell
.\setup-onedrive-retrieval.ps1 -ShowStats
```

## 📋 搜索技巧

### 精确搜索
```
使用引号："AI 智能客服"
```

### 排除词汇
```
使用减号：项目报告 -测试
```

### 文件类型过滤
```
在高级选项中选择特定文件类型
```

### 日期范围
```
在高级选项中设置开始/结束日期
```

## 🎯 常见问题

### Q: 搜索不到文档？
**A:** 检查是否已配置 OneDrive URL 并执行扫描

### Q: 如何更新文档索引？
**A:** 点击 "📡 扫描文档" 重新扫描

### Q: 支持哪些文件格式？
**A:** Word (DOC/DOCX), Excel (XLS/XLSX), PowerPoint (PPT/PPTX), PDF, OneNote

### Q: 可以搜索多个 OneDrive 吗？
**A:** 可以，在高级选项中添加多个 URL

### Q: 搜索结果如何排序？
**A:** 按相关性得分排序，考虑标题匹配、内容匹配、修改时间等

## 🔗 相关文档

- **完整说明**: `README.md`
- **API 集成**: `API-INTEGRATION-GUIDE.md`
- **更新总结**: `UPDATE-SUMMARY.md`

## 💡 下一步

1. ✅ 打开 Dashboard 查看界面
2. ⬜ 配置真实 OneDrive URL
3. ⬜ 执行文档扫描
4. ⬜ 开始使用搜索功能
5. ⬜ 联系开发团队集成 Microsoft Graph API

---

**需要帮助？** 联系 PMO 系统管理员  
**版本**: v2.0  
**日期**: 2026-04-06
