/**
 * ═══════════════════════════════════════════════════
 *  模拟 AI 返回数据 — Demo 模式使用
 * ═══════════════════════════════════════════════════
 *
 *  当 window.APP_CONFIG.apiBase 未设置时，
 *  callAI() 会自动调用此文件中的模拟函数。
 *  接入真实后端后此文件不再被使用。
 */

function getMockResponse(type, payload) {
  if (type === 'expansion') return mockExpansion(payload);
  if (type === 'breakdown') return mockBreakdown(payload);
  if (type === 'parse')      return mockExpansion(payload);
  return { success: false, error: '未知调用类型' };
}

/* ────────────────────────────────────────────
   项目扩写（文本输入 / 文件解析共用）
   ──────────────────────────────────────────── */
function mockExpansion(payload) {
  const raw = payload.description || payload.fileName || '新项目';
  const title = extractTitle(raw);

  return {
    success: true,
    data: {
      projectName: title,
      projectType: '内部研发',
      priority: '高',

      overview:
        `${title} 旨在通过系统化的项目管理方法，从需求调研到最终交付形成完整的闭环。` +
        `项目将覆盖业务流程梳理、技术方案设计、核心功能开发、全面测试验收四大阶段，` +
        `确保在既定时间、预算和质量标准下完成全部目标。` +
        `项目团队将采用敏捷与瀑布混合管理模式，兼顾灵活性与可控性。`,

      objectives: [
        `完成 ${title} 核心功能的开发与交付`,
        '建立标准化的项目管理流程和文档体系',
        '确保系统稳定性，核心功能可用性 ≥ 99.5%',
        '按时交付并通过内部验收',
      ],

      scope: {
        inScope: [
          '核心业务流程数字化改造',
          '用户界面 (UI/UX) 设计与前端开发',
          '后端服务架构设计与开发',
          '数据库建模与数据迁移',
          '系统集成测试与用户验收测试',
          '技术文档与用户培训材料编写',
        ],
        outOfScope: [
          '遗留系统的全面改造（归入二期）',
          '第三方系统深度集成（API 对接预留接口）',
          '多语言国际化支持',
        ],
      },

      wbs: [
        {
          phase: '第一阶段：需求与规划',
          duration: '2 周',
          tasks: ['业务需求调研', '竞品分析与技术选型', '项目计划制定与评审', '资源与预算确认'],
        },
        {
          phase: '第二阶段：设计',
          duration: '3 周',
          tasks: ['系统架构设计', '数据库建模', 'UI/UX 交互设计', 'API 接口规范设计', '设计评审与冻结'],
        },
        {
          phase: '第三阶段：开发',
          duration: '5 周',
          tasks: ['前端框架搭建与组件开发', '后端核心服务开发', '数据库开发与数据迁移', '前后端联调', '代码审查与重构'],
        },
        {
          phase: '第四阶段：测试',
          duration: '2 周',
          tasks: ['单元测试', '集成测试', '性能与安全测试', '用户验收测试 (UAT)'],
        },
        {
          phase: '第五阶段：部署与收尾',
          duration: '1 周',
          tasks: ['生产环境部署', '用户培训', '运维监控配置', '项目总结与知识沉淀'],
        ],
      ],

      timeline: {
        estimatedDuration: '13 周',
        startDate: getNextMonday(),
        endDate: '',   // 由 breakdown 时计算
      },

      resources: {
        requiredRoles: [
          { role: '项目经理',   count: 1, desc: '整体把控进度与风险' },
          { role: '产品经理',   count: 1, desc: '需求管理与验收' },
          { role: 'UI 设计师',  count: 1, desc: '界面与交互设计' },
          { role: '前端工程师', count: 2, desc: '页面与组件开发' },
          { role: '后端工程师', count: 2, desc: '服务与数据层开发' },
          { role: '测试工程师', count: 1, desc: '测试用例编写与执行' },
        ],
        totalHeadcount: 8,
      },

      risks: [
        { title: '需求变更频繁',     level: '高', mitigation: '建立需求变更管理流程，设置需求冻结节点' },
        { title: '关键技术攻关延迟', level: '高', mitigation: '提前进行技术预研，准备备选方案' },
        { title: '人员资源不足',     level: '中', mitigation: '提前储备外部资源，必要时引入外包支持' },
        { title: '第三方依赖延迟',   level: '中', mitigation: '降低外部耦合度，制定降级方案' },
        { title: '测试环境不稳定',   level: '低', mitigation: '搭建独立测试环境，配置自动化运维工具' },
      ],

      milestones: [
        { name: '需求评审通过', targetDate: '', deliverables: ['需求规格说明书', '项目计划书'] },
        { name: '设计评审通过', targetDate: '', deliverables: ['系统架构设计文档', '数据库设计文档', 'UI 设计稿'] },
        { name: '开发完成',     targetDate: '', deliverables: ['可运行系统', 'API 接口文档'] },
        { name: '验收通过',     targetDate: '', deliverables: ['测试报告', '用户手册', '验收报告'] },
        { name: '项目上线',     targetDate: '', deliverables: ['部署文档', '运维手册'] },
      ],

      deliverables: [
        { name: '需求规格说明书',   format: 'DOCX' },
        { name: '系统设计文档',     format: 'DOCX' },
        { name: 'UI/UX 设计稿',    format: 'PDF' },
        { name: 'API 接口文档',     format: 'DOCX' },
        { name: '测试报告',         format: 'PDF' },
        { name: '用户操作手册',     format: 'PDF' },
        { name: '项目总结报告',     format: 'PPTX' },
      ],
    },
  };
}


/* ────────────────────────────────────────────
   项目拆分 — 将方案转化为可执行结构
   ──────────────────────────────────────────── */
function mockBreakdown(payload) {
  const plan = payload.plan || {};
  const name = plan.projectName || '新项目';
  const wbs  = plan.wbs || [];
  const startDate = plan.timeline?.startDate || getNextMonday();

  // 生成任务列表
  const tasks = [];
  let tid = 1;
  let cumDays = 0;

  wbs.forEach((phase) => {
    const phaseStart = addDays(startDate, cumDays);
    phase.tasks.forEach((taskName, i) => {
      const dur = 3 + Math.floor(Math.random() * 4);
      tasks.push({
        id:          `T${String(tid).padStart(3, '0')}`,
        name:        taskName,
        phase:       phase.phase,
        assignee:    '待分配',
        startDate:   addDays(phaseStart, i * dur),
        endDate:     addDays(phaseStart, (i + 1) * dur),
        duration:    dur,
        priority:    i < 2 ? '高' : (i < 4 ? '中' : '低'),
        status:      '未开始',
        progress:    0,
        dependencies: tid > 1 ? [`T${String(tid - 1).padStart(3, '0')}`] : [],
      });
      tid++;
      cumDays += dur;
    });
  });

  // 生成里程碑
  const milestones = (plan.milestones || []).map((m, i) => ({
    name:         m.name,
    targetDate:   m.targetDate || addDays(startDate, Math.round(cumDays / (plan.milestones?.length || 4) * (i + 1))),
    deliverables: m.deliverables || [],
    status:       '待开始',
  }));

  // 团队建议
  const team = (plan.resources?.requiredRoles || []).map(r => ({
    role:     r.role,
    count:    r.count,
    desc:     r.desc || '',
    assigned: false,
  }));

  // 项目 ID
  const projectId = `PRJ-${new Date().getFullYear()}-${String(Math.floor(100 + Math.random() * 900))}`;

  return {
    success: true,
    data: {
      projectId,
      projectName: name,
      projectType: plan.projectType || '内部研发',
      priority:    plan.priority || '高',
      status:      '规划中',
      startDate,
      endDate:     addDays(startDate, cumDays + 7),
      tasks,
      milestones,
      risks: plan.risks || [],
      team,
      deliverables: plan.deliverables || [],
    },
  };
}


/* ────────────────────────────────────────────
   工具函数
   ──────────────────────────────────────────── */

function extractTitle(raw) {
  if (!raw) return '新项目';
  // 去掉常见前缀
  raw = raw.replace(/^(项目简介[:：]?|项目名称[:：]?|关于)\s*/i, '').trim();
  if (raw.length <= 40) return raw;
  return raw.substring(0, 40) + '…';
}

function getNextMonday() {
  const d = new Date();
  const day = d.getDay();
  const diff = day === 0 ? 1 : (8 - day);
  d.setDate(d.getDate() + diff);
  return d.toISOString().slice(0, 10);
}

function addDays(dateStr, days) {
  const d = new Date(dateStr);
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}
