// ═══════════════════════════════════════════════════════════════
//  PMO Dashboard — AI 后端代理服务 v3.0
// ═══════════════════════════════════════════════════════════════
//
//  核心升级：
//  - 里程碑拆分遵循「决策优先、闭环推进」原则
//  - 里程碑四要素：决策点、交付物、时间节点、负责人
//  - 任务含风险点、依赖关系、优先级、预计耗时
//  - 支持 SOP 文档生成
//  - 支持团队动态调整时的 SOP 规则
//
// ═══════════════════════════════════════════════════════════════

const express = require('express');
const cors = require('cors');
const https = require('https');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json({ limit: '20mb' }));

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
            max_tokens: extra.max_tokens || 8192,
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
                    let content = parsed.choices?.[0]?.message?.content || '';

                    if (!content) {
                        reject(new Error('AI 返回内容为空'));
                        return;
                    }

                    // 清理 markdown 代码块包裹
                    content = content.trim();
                    if (content.startsWith('```')) {
                        content = content.replace(/^```[a-z]*\n?/, '');
                        content = content.replace(/\n?```$/, '');
                        content = content.trim();
                    }

                    // 提取 JSON 对象
                    const jsonMatch = content.match(/\{[\s\S]*\}/);
                    if (jsonMatch) {
                        content = jsonMatch[0];
                    }

                    resolve(JSON.parse(content));
                } catch (e) {
                    console.error('[AI解析失败] 原始响应:', data.substring(0, 2000));
                    console.error('[AI解析失败] 解析错误:', e.message);
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
//  Prompt 模板 — v3.0 强化版
// ═══════════════════════════════════════════

const PROMPTS = {

    // ─── 项目扩写 Prompt（强化版） ───
    expansion: {
        system: `你是精通大公司高效项目管理 SOP 与里程碑拆分逻辑的资深 PM 专家。你的核心职责是基于输入的项目信息，自动完成里程碑拆解、任务分配、会议流程标准化与项目进度管控，确保项目全流程高效推进。

你生成的所有输出必须符合「高效、闭环、可执行」原则：
- 拒绝模糊表述，所有时间、责任人、交付物必须明确
- 优先保障决策效率，所有任务需减少无效沟通环节和琐碎交付物
- 遵循「决策优先、闭环推进」原则

请根据用户输入的项目描述，自动分析项目名称、项目目标、预算范围估算、核心干系人列表、团队规模建议、时间约束等，并生成完整项目方案。

必须严格按以下 JSON 格式返回：

{
  "projectName": "项目名称",
  "projectType": "内部研发/外部交付/基础设施/管理改善/组织变革/数字化转型",
  "priority": "高/中/低",
  "overview": "200-400字项目概述（含业务背景、核心目标、预期成果）",
  "objectives": ["可衡量的目标1", "可衡量的目标2", "可衡量的目标3", "可衡量的目标4"],
  "scope": {
    "inScope": ["范围内项1", "范围内项2", "范围内项3", "范围内项4", "范围内项5"],
    "outOfScope": ["范围外项1", "范围外项2", "范围外项3"]
  },
  "meta": {
    "budgetRange": "预算范围估算（如 10-50万）",
    "stakeholders": ["核心干系人1（角色）", "核心干系人2（角色）", "核心干系人3（角色）"],
    "teamScale": "建议团队规模（如 5-8人）",
    "timeConstraint": "时间约束描述（如 Q2 交付、3个月周期）"
  },
  "wbs": [
    {
      "phase": "阶段名称",
      "duration": "X 周",
      "decisionPoint": "本阶段的核心决策点描述（Go/No-Go 决策内容）",
      "tasks": [
        {
          "name": "任务名称",
          "description": "任务描述（一句话）",
          "priority": "高/中/低",
          "estimatedHours": 8,
          "deliverable": "本任务交付物"
        }
      ]
    }
  ],
  "timeline": {
    "estimatedDuration": "XX 周",
    "startDate": "下一个周一的日期（YYYY-MM-DD）"
  },
  "resources": {
    "requiredRoles": [
      {"role": "角色名", "count": 1, "desc": "职责描述", "decisionLevel": "执行层/管理层/战略层"}
    ],
    "totalHeadcount": 8
  },
  "risks": [
    {"title": "风险标题", "level": "高/中/低", "mitigation": "缓解措施", "triggerCondition": "触发条件"}
  ],
  "milestones": [
    {
      "name": "里程碑名称（如：需求评审通过）",
      "decisionPoint": "本里程碑的核心决策点（如：方案是否通过评审，决定是否进入下一阶段）",
      "deliverables": ["交付物1", "交付物2"],
      "targetDate": "YYYY-MM-DD",
      "owner": "负责人角色（如：项目经理）",
      "priority": "高/中/低",
      "gatingCriteria": "通过标准（如：方案需获得CTO签字确认）"
    }
  ],
  "deliverables": [
    {"name": "交付物名称", "format": "DOCX/PDF/PPTX/XLSX", "milestone": "所属里程碑名称"}
  ],
  "sopRules": {
    "decisionMechanism": "层级决策(大公司) / 扁平化决策(初创)",
    "approvalChain": ["审批人1（角色）", "审批人2（角色）"],
    "meetingCadence": "会议节奏（如：每周一站会，每双周评审会）",
    "communicationChannels": ["沟通渠道1", "沟通渠道2"],
    "escalationRules": "升级规则（如：任务延期超3天自动升级至PMO负责人）"
  }
}

要求：
- WBS 至少包含 4 个阶段，每个阶段 3-6 个任务
- 每个阶段必须有 decisionPoint（决策点）
- 每个任务必须有 estimatedHours 和 deliverable
- 里程碑至少 4 个，每个里程碑必须包含四要素：decisionPoint、deliverables、targetDate、owner
- 风险至少 3 个，需包含 triggerCondition
- 交付物至少 5 个，关联到对应里程碑
- 资源配置中每个角色需标注 decisionLevel
- SOP 规则必须包含决策机制、审批链、会议节奏、沟通渠道、升级规则`,
        user: '请根据以下项目描述生成完整项目方案：\n\n{input}'
    },

    // ─── 项目拆分 Prompt（强化版） ───
    breakdown: {
        system: `你是精通大公司高效项目管理 SOP 的资深 PM 专家。请将用户提供的项目方案拆分为可执行的任务清单。

核心原则：
- 遵循「决策优先、闭环推进」原则
- 所有输出必须符合「高效、闭环、可执行」原则，拒绝模糊表述
- 优先保障决策效率，减少无效沟通环节
- 里程碑四要素齐全：决策点、交付物、时间节点、负责人

必须严格按以下 JSON 格式返回：

{
  "projectId": "PRJ-YYYY-NNN（自动生成编号）",
  "projectName": "项目名称",
  "projectType": "项目类型",
  "priority": "优先级",
  "status": "规划中",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "overview": "200字项目概述",
  "tasks": [
    {
      "id": "T001",
      "name": "任务名称",
      "phase": "所属阶段",
      "milestone": "所属里程碑名称",
      "assignee": "负责人角色",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "duration": 5,
      "priority": "高/中/低",
      "status": "未开始",
      "progress": 0,
      "dependencies": ["T000"],
      "deliverable": "本任务交付物",
      "riskPoints": ["风险点1", "风险点2"]
    }
  ],
  "milestones": [
    {
      "name": "里程碑名称",
      "decisionPoint": "核心决策点描述（Go/No-Go 决策）",
      "targetDate": "YYYY-MM-DD",
      "deliverables": ["交付物1", "交付物2"],
      "owner": "负责人角色",
      "priority": "高/中/低",
      "status": "待开始",
      "gatingCriteria": "通过标准",
      "relatedTaskIds": ["T001", "T002"]
    }
  ],
  "risks": [
    {"title": "风险标题", "level": "高/中/低", "mitigation": "缓解措施", "triggerCondition": "触发条件"}
  ],
  "team": [
    {"role": "角色", "name": "成员姓名（虚构合理的中文名）", "count": 1, "desc": "职责", "assigned": true, "load": 0}
  ],
  "deliverables": [
    {"name": "交付物名称", "format": "DOCX", "milestone": "所属里程碑名称"}
  ],
  "meta": {
    "budgetRange": "预算范围",
    "stakeholders": ["干系人1（角色）"],
    "teamScale": "团队规模",
    "timeConstraint": "时间约束"
  },
  "sopRules": {
    "decisionMechanism": "层级决策/扁平化决策",
    "approvalChain": ["审批人1"],
    "meetingCadence": "会议节奏",
    "communicationChannels": ["沟通渠道"],
    "escalationRules": "升级规则"
  }
}

要求：
- 任务 ID 从 T001 递增
- 每个任务必须包含：所属里程碑(milestone)、交付物(deliverable)、风险点(riskPoints)
- 任务之间要有依赖关系（前后衔接，形成闭环）
- 高优先级任务占总任务的 20-30%
- 里程碑必须包含四要素：decisionPoint、deliverables、targetDate、owner
- 里程碑的 relatedTaskIds 必须关联到对应的任务
- 团队成员需包含 name 字段（合理的中文姓名）
- 计算每个成员的 load（基于分配的任务量）`,
        user: '请将以下项目方案拆分为可执行的任务清单：\n\n{input}'
    },

    // ─── SOP 文档生成 Prompt（新增） ───
    sop: {
        system: `你是精通大公司高效项目管理 SOP 的资深 PM 专家。请根据项目方案和拆分结果，生成一份完整的标准化项目 SOP 文档。

SOP 文档必须包含以下内容，并以 JSON 格式返回：

{
  "sopTitle": "项目标准化操作流程(SOP)",
  "projectName": "项目名称",
  "version": "v1.0",
  "createdAt": "YYYY-MM-DD",
  "sections": [
    {
      "title": "一、项目基本信息",
      "content": "项目名称、目标、范围、时间线、团队配置的概述文字（200-300字）"
    },
    {
      "title": "二、决策机制与审批流程",
      "content": "决策层级说明（层级决策/扁平化决策）、审批链、关键决策点清单（Go/No-Go）、升级规则详细描述（300-400字）"
    },
    {
      "title": "三、里程碑管控 SOP",
      "content": "每个里程碑的管控规则：决策点检查清单、交付物验收标准、负责人职责、时间节点管控要求（按里程碑逐一描述，每个里程碑 100-150 字）"
    },
    {
      "title": "四、会议流程标准化",
      "content": "会议节奏（站会/评审会/复盘会）、参会人员、议程模板、输出要求、会议纪要模板（200-300字）"
    },
    {
      "title": "五、团队协作规则",
      "content": "任务分配规则、依赖关系管理、进度汇报机制、跨部门协作流程、沟通渠道规范（300-400字）"
    },
    {
      "title": "六、风险管理 SOP",
      "content": "风险识别机制、风险等级定义、升级触发条件、缓解措施执行规则、风险复盘流程（200-300字）"
    },
    {
      "title": "七、变更管理流程",
      "content": "需求变更、人员变更、时间变更的处理 SOP（200-300字）"
    },
    {
      "title": "八、团队规模变化时的 SOP 动态调整规则",
      "content": "当团队成员扩张/减少/替换时的标准操作流程：自动调整任务分配规则、权限边界更新、通知机制、已操作内容保护规则（不覆盖已上传或正在编辑的文档等）（300-400字）"
    }
  ]
}

要求：
- 所有内容必须具体、可执行，拒绝模糊表述
- 日期、责任人、交付物必须明确
- 适配大公司层级决策和初创公司扁平化决策两种场景
- 团队调整规则必须明确保护已有工作成果`,
        user: '请根据以下项目方案和任务拆分结果，生成标准化 SOP 文档：\n\n项目方案：\n{plan}\n\n任务拆分：\n{breakdown}'
    }
};


// ═══════════════════════════════════════════
//  API 路由
// ═══════════════════════════════════════════════

// 健康检查
app.get('/api/v1/health', (req, res) => {
    res.json({ status: 'ok', model: AI_MODEL, version: '3.0', time: new Date().toISOString() });
});

// 项目扩写：文本输入 → 完整方案（强化版）
app.post('/api/v1/project/expand', async (req, res) => {
    const { description } = req.body;

    if (!description || description.trim().length < 10) {
        return res.status(400).json({ success: false, error: '项目描述至少需要 10 个字' });
    }

    try {
        console.log(`[扩写] 收到请求，${description.length} 字`);
        const prompt = PROMPTS.expansion.user.replace('{input}', description.trim());
        const result = await callZhipu(PROMPTS.expansion.system, prompt, { max_tokens: 8192 });
        console.log(`[扩写] 完成 → ${result.projectName || '未知项目'}, ${result.milestones?.length || 0} 个里程碑`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[扩写] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});

// 项目拆分：完整方案 → 任务清单（强化版）
app.post('/api/v1/project/breakdown', async (req, res) => {
    const { plan } = req.body;

    if (!plan) {
        return res.status(400).json({ success: false, error: '缺少项目方案数据' });
    }

    try {
        const planJson = JSON.stringify(plan, null, 2);
        console.log(`[拆分] 收到请求，项目: ${plan.projectName || '未知'}，方案大小: ${planJson.length} 字符`);
        const prompt = PROMPTS.breakdown.user.replace('{input}', planJson);
        const result = await callZhipu(PROMPTS.breakdown.system, prompt, { max_tokens: 8192 });
        console.log(`[拆分] 完成 → ${result.tasks?.length || 0} 个任务，${result.milestones?.length || 0} 个里程碑`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[拆分] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});

// SOP 文档生成（新增）
app.post('/api/v1/project/sop', async (req, res) => {
    const { plan, breakdown } = req.body;

    if (!plan || !breakdown) {
        return res.status(400).json({ success: false, error: '缺少项目方案或拆分数据' });
    }

    try {
        console.log(`[SOP] 收到请求，项目: ${plan.projectName || breakdown.projectName || '未知'}`);
        const prompt = PROMPTS.sop.user
            .replace('{plan}', JSON.stringify(plan, null, 2))
            .replace('{breakdown}', JSON.stringify(breakdown, null, 2));
        const result = await callZhipu(PROMPTS.sop.system, prompt, { max_tokens: 8192 });
        console.log(`[SOP] 完成 → ${result.sections?.length || 0} 个章节`);
        res.json({ success: true, data: result });
    } catch (err) {
        console.error(`[SOP] 失败: ${err.message}`);
        res.status(500).json({ success: false, error: err.message });
    }
});

// 文件解析：上传文件 → 提取项目信息（复用扩写 Prompt）
app.post('/api/v1/project/parse', async (req, res) => {
    const { fileName, fileContent } = req.body;

    if (!fileName) {
        return res.status(400).json({ success: false, error: '缺少文件名' });
    }

    try {
        console.log(`[解析] 收到文件: ${fileName}`);

        let fileText = '';
        if (fileContent && fileContent.startsWith('data:')) {
            const base64Data = fileContent.split(',')[1];
            if (base64Data) {
                fileText = Buffer.from(base64Data, 'base64').toString('utf-8');
                if (fileText.length > 3000) fileText = fileText.substring(0, 3000) + '\n\n[... 文件内容已截取 ...]';
            }
        } else {
            fileText = fileContent || fileName;
        }

        const prompt = PROMPTS.expansion.user.replace('{input}', `文件名：${fileName}\n\n文件内容摘要：\n${fileText}`);
        const result = await callZhipu(PROMPTS.expansion.system, prompt, { max_tokens: 8192 });
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
    console.log(`  🚀 PMO AI 后端服务已启动 (v3.0)`);
    console.log(`  📍 地址: http://localhost:${PORT}`);
    console.log(`  🤖 模型: ${AI_MODEL}`);
    console.log(`  ❤️  健康检查: http://localhost:${PORT}/api/v1/health`);
    console.log('═══════════════════════════════════════════');
    console.log('');
});
