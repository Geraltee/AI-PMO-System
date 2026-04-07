# OneDrive 检索 API 集成指南

## 📡 API 端点

### 基础 URL
```
http://localhost:3000/api
```

## 🔐 认证

使用 OAuth 2.0 获取 Microsoft Graph API 访问令牌：

```javascript
// 1. 重定向到 Microsoft 登录
const authUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize?
  client_id=${clientId}&
  response_type=code&
  redirect_uri=${redirectUri}&
  scope=Sites.Read.All Files.Read.All User.Read&
  response_mode=query`;

// 2. 用授权码换取访问令牌
POST https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=${authorizationCode}&
redirect_uri=${redirectUri}&
client_id=${clientId}&
client_secret=${clientSecret}&
scope=Sites.Read.All Files.Read.All User.Read
```

## 📚 API 接口

### 1. 添加 OneDrive 文档库

**POST** `/onedrive/add`

**请求体:**
```json
{
  "url": "https://your-company.sharepoint.com/sites/PMO/Shared Documents",
  "name": "PMO 文档库",
  "credentials": {
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "tenantId": "your-tenant-id"
  }
}
```

**响应:**
```json
{
  "success": true,
  "message": "OneDrive URL 已添加",
  "data": {
    "id": "drive-001",
    "url": "https://...",
    "name": "PMO 文档库",
    "status": "pending"
  }
}
```

---

### 2. 扫描文档

**POST** `/onedrive/scan`

**请求体:**
```json
{
  "driveId": "drive-001",
  "options": {
    "includeSubfolders": true,
    "maxDepth": 5
  }
}
```

**响应:**
```json
{
  "success": true,
  "message": "扫描完成",
  "data": {
    "totalDocuments": 127,
    "indexedDocuments": 125,
    "failedDocuments": 2,
    "duration": "45.3s"
  }
}
```

---

### 3. 关键词搜索

**GET** `/search/keyword`

**参数:**
```
q: 搜索关键词 (必需)
driveId: 文档库 ID (可选)
fileType: 文件类型过滤 (可选: docx,xlsx,pptx,pdf)
startDate: 开始日期 (可选: ISO 8601)
endDate: 结束日期 (可选: ISO 8601)
limit: 返回数量限制 (可选，默认 50)
offset: 偏移量 (可选，默认 0)
```

**请求示例:**
```
GET /search/keyword?q=AI 客服项目&fileType=docx&limit=20
```

**响应:**
```json
{
  "success": true,
  "query": "AI 客服项目",
  "total": 15,
  "searchTime": 234,
  "results": [
    {
      "id": "doc-001",
      "title": "AI 智能客服系统需求文档 v2.0",
      "snippet": "本文档详细描述了 AI 智能客服升级项目的功能需求...",
      "type": "docx",
      "size": 2048576,
      "url": "https://...",
      "createdDate": "2026-04-01T10:00:00Z",
      "modifiedDate": "2026-04-02T15:30:00Z",
      "relevanceScore": 95.5,
      "highlights": [
        "AI 智能客服系统需求文档",
        "AI 客服升级项目"
      ]
    }
  ]
}
```

---

### 4. 自然语言搜索

**GET** `/search/natural`

**参数:**
```
q: 自然语言问题 (必需)
```

**请求示例:**
```
GET /search/natural?q=AI 客服项目的技术架构是什么？
```

**响应:**
```json
{
  "success": true,
  "question": "AI 客服项目的技术架构是什么？",
  "questionType": "what",
  "keywords": ["AI", "客服", "项目", "技术架构"],
  "total": 8,
  "answer": "根据检索结果，找到 8 个相关文档。最相关的文档是《AI 智能客服系统需求文档 v2.0》...",
  "results": [
    {
      "id": "doc-001",
      "title": "AI 智能客服系统技术架构设计",
      "snippet": "系统采用微服务架构，包含 NLP 引擎、知识库、对话管理等核心模块...",
      "type": "pptx",
      "relevanceScore": 92.3
    }
  ]
}
```

---

### 5. 读取文档内容

**GET** `/document/:id/content`

**路径参数:**
```
id: 文档 ID
```

**请求示例:**
```
GET /document/doc-001/content
```

**响应:**
```json
{
  "success": true,
  "data": {
    "id": "doc-001",
    "title": "AI 智能客服系统需求文档 v2.0",
    "type": "docx",
    "content": "完整的文档内容...",
    "metadata": {
      "author": "张三",
      "createdDate": "2026-04-01T10:00:00Z",
      "modifiedDate": "2026-04-02T15:30:00Z",
      "tags": ["AI", "客服", "需求文档"],
      "category": "技术"
    },
    "downloadUrl": "https://..."
  }
}
```

---

### 6. 获取统计信息

**GET** `/stats`

**响应:**
```json
{
  "success": true,
  "data": {
    "totalDocuments": 127,
    "byType": {
      "docx": 45,
      "xlsx": 32,
      "pptx": 28,
      "pdf": 22
    },
    "byDrive": {
      "drive-001": 85,
      "drive-002": 42
    },
    "lastUpdated": "2026-04-06T08:58:00Z",
    "configuredDrives": 2
  }
}
```

---

### 7. 删除文档库

**DELETE** `/onedrive/:driveId`

**响应:**
```json
{
  "success": true,
  "message": "文档库已删除"
}
```

---

### 8. 更新文档索引

**POST** `/onedrive/:driveId/sync`

**请求体:**
```json
{
  "force": false,
  "incremental": true
}
```

**响应:**
```json
{
  "success": true,
  "data": {
    "added": 5,
    "updated": 12,
    "deleted": 2,
    "unchanged": 108
  }
}
```

## 🔍 搜索算法

### 相关性评分公式

```
relevanceScore = 
  (titleMatch * 10) +
  (contentMatch * 5) +
  (metadataMatch * 3) +
  (recencyBonus) +
  (frequencyBonus)
```

其中:
- `titleMatch`: 标题匹配次数 (0-5)
- `contentMatch`: 内容匹配次数 (0-3)
- `metadataMatch`: 元数据匹配 (0 或 1)
- `recencyBonus`: 最近修改 bonus (0-3)
  - 7 天内：+3
  - 30 天内：+2
  - 90 天内：+1
- `frequencyBonus`: 关键词频率 bonus (0-2)

### 自然语言处理

```javascript
// 问题类型识别
const questionTypes = {
  'what': ['什么', '哪些', '什么内容'],
  'how': ['怎么', '如何', '怎样'],
  'why': ['为什么', '为何'],
  'when': ['何时', '什么时候', '哪天'],
  'who': ['谁', '哪个', '哪些人']
};

// 关键词提取
function extractKeywords(question) {
  const stopWords = ['的', '了', '是', '在', '我', '有', '和', '就', '不'];
  return question
    .split(/[\s,，.。？?！!]+/)
    .filter(word => word.length > 1 && !stopWords.includes(word));
}
```

## 📦 Node.js 实现示例

### 服务器端 (Express)

```javascript
const express = require('express');
const { Client } = require('@microsoft/microsoft-graph-client');
const app = express();

app.use(express.json());

// Microsoft Graph 客户端
function getGraphClient(accessToken) {
  return Client.init({
    authProvider: (done) => done(null, accessToken)
  });
}

// 添加 OneDrive
app.post('/api/onedrive/add', async (req, res) => {
  const { url, name, credentials } = req.body;
  
  // 验证凭证
  const accessToken = await getAccessToken(credentials);
  const graphClient = getGraphClient(accessToken);
  
  // 验证 URL 可访问
  try {
    const site = await graphClient.api(url).get();
    // 保存到配置
    res.json({ success: true, data: { id: site.id, url, name } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
});

// 扫描文档
app.post('/api/onedrive/scan', async (req, res) => {
  const { driveId, options } = req.body;
  
  const graphClient = getGraphClient(getAccessToken());
  
  // 获取文档列表
  const documents = await graphClient
    .api(`/sites/${driveId}/drive/root/children`)
    .filter("file ne null")
    .expand("listItem")
    .get();
  
  // 建立索引
  const index = documents.value.map(doc => ({
    id: doc.id,
    title: doc.name,
    type: doc.file.mimeType.split('/')[1],
    size: doc.size,
    createdDate: doc.createdDateTime,
    modifiedDate: doc.lastModifiedDateTime,
    url: doc.webUrl
  }));
  
  res.json({ 
    success: true, 
    data: { totalDocuments: index.length } 
  });
});

// 搜索
app.get('/api/search/keyword', async (req, res) => {
  const { q, fileType, startDate, endDate, limit = 50 } = req.query;
  
  // 从索引中搜索
  const results = searchIndex(q, { fileType, startDate, endDate });
  
  res.json({
    success: true,
    query: q,
    total: results.length,
    results: results.slice(0, limit)
  });
});

app.listen(3000, () => {
  console.log('OneDrive 检索 API 服务已启动：http://localhost:3000');
});
```

### 客户端 (前端)

```javascript
// 搜索函数
async function searchDocuments(query, options = {}) {
  const params = new URLSearchParams({ q: query, ...options });
  const response = await fetch(`/api/search/keyword?${params}`);
  const data = await response.json();
  
  if (data.success) {
    displayResults(data.results);
  } else {
    showError(data.message);
  }
}

// 自然语言搜索
async function askQuestion(question) {
  const response = await fetch(`/api/search/natural?q=${encodeURIComponent(question)}`);
  const data = await response.json();
  
  if (data.success) {
    displayAnswer(data.answer);
    displayResults(data.results);
  }
}

// 打开文档
async function openDocument(docId) {
  const response = await fetch(`/api/document/${docId}/content`);
  const data = await response.json();
  
  if (data.success) {
    window.open(data.data.downloadUrl, '_blank');
  }
}
```

## 🔒 安全最佳实践

1. **凭证存储**: 使用环境变量或密钥管理服务
2. **访问控制**: 实现基于角色的访问控制 (RBAC)
3. **速率限制**: 限制 API 调用频率
4. **日志记录**: 记录所有 API 调用和错误
5. **HTTPS**: 生产环境必须使用 HTTPS
6. **CORS**: 配置适当的 CORS 策略

## 📊 性能优化

1. **缓存**: 缓存热门搜索结果
2. **索引**: 使用 Elasticsearch 或类似工具加速搜索
3. **分页**: 大数据集使用分页
4. **增量更新**: 只更新变化的文档
5. **异步处理**: 文档扫描使用后台任务

## 🧪 测试

```javascript
// 单元测试示例
const assert = require('assert');
const searchService = require('./search-service');

describe('搜索服务', () => {
  it('应该正确提取关键词', () => {
    const keywords = searchService.extractKeywords('AI 客服项目的技术架构是什么？');
    assert.deepStrictEqual(keywords, ['AI', '客服', '项目', '技术架构']);
  });
  
  it('应该识别问题类型', () => {
    const type = searchService.identifyQuestionType('如何实现用户认证？');
    assert.strictEqual(type, 'how');
  });
});
```

## 📞 技术支持

- Microsoft Graph API 文档：https://docs.microsoft.com/graph/api/overview
- SharePoint REST API: https://docs.microsoft.com/sharepoint/dev/sp-add-ins/sharepoint-add-ins
- 内部支持：联系 PMO 系统管理员

---

**版本**: v1.0  
**最后更新**: 2026-04-06
