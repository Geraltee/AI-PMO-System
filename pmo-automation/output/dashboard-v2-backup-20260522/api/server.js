// ═══════════════════════════════════════════════════════════════
//  PMO Dashboard — AI 后端代理服务
// ═══════════════════════════════════════════════════════════════
//
//  作用：前端无法直接调用 AI API（Key 暴露 + CORS 限制），
//        本服务作为中间层，接收前端请求 → 调用智谱 AI → 返回结果
//
//  启动：cd api/ && npm install && node server.js
//  测试：http://localhost:3456/api/v1/health
//
// ═══════════════════════════════════════════════════════════════

const express = require('express');
const cors = require('cors');
const https = require('https');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());                          // 允许前端跨域请求
app.use(express.json({ limit: '20mb' })); // 解析 JSON 请求体（支持大文件）

// ─── 读取配置 ───
function loadEnv() {
    const envPath = path.join(__dirname, '.env');
    if (!fs.existsSync(envPath)) {
        console.error('');
        console.error('❌ 找不到 .env 配置文件！');
        console.error('');
        console.error('请执行以下步骤：');
        console.error('  1. 复制 .env.example 为 .env');
        console.error('  2. 在 .env 中填入你的智谱 API Key');
        console.error('');
        process.exit(1);
    }
    const lines = fs.readFileSync(envPath, 'utf-8')
        .split('\n')
        .filter(l => l.trim() && !l.startsWith('#'))
        .map(l => l.split('='));
    const env = {};
    lines.forEach(([k, ...v]) => { env[k.trim()] = v.join('=').trim(); });
    return env;
}

const env = loadEnv();
const ZHIPU_API_KEY = env.ZHIPU_API_KEY;
const PORT = parseInt(env.PORT) || 3456;
const AI_MODEL = env.AI_MODEL || 'glm-4-plus';

if (!ZHIPU_API_KEY || ZHIPU_API_KEY === '在这里填入你的API_Key') {
    console.error('');
    console.error('❌ 请先在 .env 文件中填入你的智谱 API Key！');
    console.error('   获取地址：https://open.bigmodel.cn → 控制台 → API Keys');
    console.error('');
    process.exit(1);
}

console.log(`✅ 配置加载完成 — 模型: ${AI_MODEL}, 端口: ${PORT}`);


// ═══════════════════════════════════════════
//  调用智谱 AI 的统一函数
// ═══════════════════════════════════════════════

function callZhipu(systemPrompt, userContent, extra = {}) {
    return new Promise((resolve, reject) => {
        const messages = [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent }
        ];

        const body = JSON.stringify({
            model: extra.model || AI_MODEL,
            messages,
            temperature: extra.temperature || 0.7,
            max_tokens: extra.max_tokens || 4096,
            // 要求返回 JSON 格式
            response_format: { type: 'json_object' }
        });

        const options = {
            hostname: 'open.bigmodel.cn',
            path: '/api/paas/v4/chat/completions',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${ZHIPU_API_KEY}`,
                'Content-Length': Buffer.byteLength(body)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.error) {
                        reject(new Error(parsed.error.message || 'AI 返回错误'));
                        return;
                    }
                    // 提取 AI 返回的文本内容
                    const content = parsed.choices?.[0]?.message?.content || '';
                    // 解析 JSON
                    resolve(JSON.parse(content));
                } catch (e) {
                    // 如果 JSON 解析失败，返回原始文本
                    reject(new Error('AI 返回格式异常，请重试'));
                }
            });
        });

        req.on('error', (e) => reject(new Error('网络请求失败: ' + e.message)));
        req.setTimeout(120000, () => { req.destroy(); reject(new Error('请求超时（120秒）')); });
        req.write(body);
        req.end();
    });
}


// ═══════════════════════════════════════════
//  Prompt 模板
// ═══════════════════════════════════════════════

const PROMPTS = {

    // ─── 项目扩写 Prompt ───
    expansion: {
        system: `你是一位资深项目管理专家（PMP认证）。请根据用户输入的项目简介，生成一份完整的项目方案。

必须严格按以下 JSON 格式返回（不要添加任何其他文字）：

{
  "projectName": "项目名称",
  "projectType": "内部研发/外部交付/基础设施/管理改善",
  "priority": "高/中/低",
  "overview": "200-300字项目概述",
  "objectives": ["目标1", "目标2", "目标3", "目标4"],
  "scope": {
    "inScope": ["范围内项1", "范围内项2", "范围内项3", "范围内项4", "范围内项5"],
    "outOfScope": ["范围外项1", "范围外项2", "范围外项3"]
  },
  "wbs": [
    {
      "phase": "阶段名称",
      "duration": "X 周",
      "tasks": ["任务1", "任务2", "任务3"]
    }
  ],
  "timeline": {
    "estimatedDuration": "XX 周",
    "startDate": "下一个周一的日期（YYYY-MM-DD）"
  },
  "resources": {
    "requiredRoles": [
      {"role": "角色名", "count": 1, "desc": "职责描述"}
    ],
    "totalHeadcount": 8
  },
  "risks": [
    {"title": "风险标题", "level": "高/中/低", "mitigation": "缓解措施"}
  ],
  "milestones": [
    {"name": "里程碑名称", "deliverables": ["交付物1", "交付物2"]}
  ],
  "deliverables": [
    {"name": "交付物名称", "format": "DOCX/PDF/PPTX/XLSX"}
  ]
}

要求：
- WBS 至少包含 4 个阶段，每个阶段 3-6 个任务
- 风险至少 3 个（含等级和缓解措施）
- 里程碑至少 4 个
- 交付物至少 5 个
- 资源配置要合理，总人数 5-15 人`,
        user: '请根据以下项目简介生成完整项目方案：\n\n{input}'
    },

    // ─── 项目拆分 Prompt ───
    breakdown: {
        system: `你是一位资深项目管理专家。请将用户提供的项目方案拆分为可执行的任务清单。

必须严格按以下 JSON 格式返回：

{
  "projectId": "PRJ-YYYY-NNN（自动生成编号）",
  "projectName": "项目名称",
  "projectType": "项目类型",
  "priority": "优先级",
  "status": "规划中",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "tasks": [
    {
      "id": "T001",
      "name": "任务名称",
      "phase": "所属阶段",
      "assignee": "待分配",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "duration": 5,
      "priority": "高/中/低",
      "status": "未开始",
      "progress": 0,
      "dependencies": []
    }
  ],
  "milestones": [
    {"name": "里程碑名称", "targetDate": "YYYY-MM-DD", "deliverables": ["交付物"], "status": "待开始"}
  ],
  "risks": [
    {"title": "风险标题", "level": "高/中/低", "mitigation": "缓解措施"}
  ],
  "team": [
    {"role": "角色", "count": 1, "desc": "职责", "assigned": false}
  ],
  "deliverables": [
    {"name": "交付物名称", "format": "DOCX"}
  ]
}

要求：
- 任务 ID 从 T001 递增
- 每个任务要分配合理的开始日期、结束日期和工期（天数）
- 任务之间要有依赖关系（前后衔接）
- 高优先级任务占总任务的 20-30%
- 里程碑日期要与任务结束日期对应`,
        user: '请将以下项目方案拆分为可执行的任务清单：\n\n{input}'
    }
};


// ═══════════════════════════════════════════
//  API 路由
// ═══════════════════════════════════════════════

// 健康检查
app.get('/api/v1/health', (req, res) => {
    res.json({ status: 'ok', model: AI_MODEL, time: new Date().toISOString() });
});

// 项目扩写：文本输入 → 完整方案
app.post('/api/v1/project/expand', async (req, res) => {
    const { description } = req.body;

    if (!description || description.trim().length < 10) {
        return res.status(400).json({ success: false, error: '项目简介至少需要 10 个字' });
    }

    try {
        console.log(`[扩写] 收到请求，${description.length} 字`);
        const prompt = PROMPTS.expansion.user.replace('{input}', description.trim());
        const result = await callZhipu(PROMPTS.expansion.system, prompt, { max_tokens: 4096 });
        console.log(`[扩写] 完成 → ${result.projectName || '未知项目'}`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[扩写] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});

// 项目拆分：完整方案 → 任务清单
app.post('/api/v1/project/breakdown', async (req, res) => {
    const { plan } = req.body;

    if (!plan) {
        return res.status(400).json({ success: false, error: '缺少项目方案数据' });
    }

    try {
        console.log(`[拆分] 收到请求，项目: ${plan.projectName || '未知'}`);
        const prompt = PROMPTS.breakdown.user.replace('{input}', JSON.stringify(plan, null, 2));
        const result = await callZhipu(PROMPTS.breakdown.system, prompt, { max_tokens: 4096 });
        console.log(`[拆分] 完成 → ${result.tasks?.length || 0} 个任务`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[拆分] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});

// 文件解析：上传文件 → 提取项目信息
app.post('/api/v1/project/parse', async (req, res) => {
    const { fileName, fileContent } = req.body;

    if (!fileName) {
        return res.status(400).json({ success: false, error: '缺少文件名' });
    }

    try {
        console.log(`[解析] 收到文件: ${fileName}`);

        let fileText = '';
        // 前端传 base64 或纯文本
        if (fileContent && fileContent.startsWith('data:')) {
            // base64 文件 — 提取文本部分（简化处理）
            const base64Data = fileContent.split(',')[1];
            if (base64Data) {
                fileText = Buffer.from(base64Data, 'base64').toString('utf-8');
                // 截取前 3000 字发给 AI（避免超出 token 限制）
                if (fileText.length > 3000) fileText = fileText.substring(0, 3000) + '\n\n[... 文件内容已截取 ...]';
            }
        } else {
            fileText = fileContent || fileName;
        }

        // 用扩写 Prompt 处理文件内容
        const prompt = PROMPTS.expansion.user.replace('{input}', `文件名：${fileName}\n\n文件内容摘要：\n${fileText}`);
        const result = await callZhipu(PROMPTS.expansion.system, prompt, { max_tokens: 4096 });
        console.log(`[解析] 完成 → ${result.projectName || '未知项目'}`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[解析] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});


// ─── 启动服务 ───
app.listen(PORT, () => {
    console.log('');
    console.log('═══════════════════════════════════════════');
    console.log(`  🚀 PMO AI 后端服务已启动`);
    console.log(`  📍 地址: http://localhost:${PORT}`);
    console.log(`  🤖 模型: ${AI_MODEL}`);
    console.log(`  ❤️  健康检查: http://localhost:${PORT}/api/v1/health`);
    console.log('═══════════════════════════════════════════');
    console.log('');
});
