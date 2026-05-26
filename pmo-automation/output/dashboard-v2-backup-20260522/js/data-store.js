/**
 * ═══════════════════════════════════════════════════════════
 *  PMO Dashboard — 共享数据层
 * ═══════════════════════════════════════════════════════════
 *
 *  所有页面通过此文件读写数据，实现页面间互通。
 *  数据存储在 localStorage('pmo_projects')。
 *  首次访问时写入 5 个种子项目（演示数据）。
 *
 *  用法：
 *    PMOData.getAll()              → 获取所有项目
 *    PMOData.getById('PRJ-xxx')    → 获取单个项目
 *    PMOData.add(projectData)      → 新增项目
 *    PMOData.update(id, changes)   → 更新项目
 *    PMOData.getStats()            → 获取仪表板统计
 * ═══════════════════════════════════════════════════════════
 */

const PMOData = (() => {
    const STORAGE_KEY = 'pmo_projects';
    const SEED_KEY   = 'pmo_seeded';

    // ─── 种子数据（演示用，只在首次访问时写入）───
    const SEED_PROJECTS = [
        {
            projectId: 'PRJ-2026-001',
            projectName: '🤖 AI 智能客服升级',
            projectType: '内部研发',
            priority: '高',
            status: '进行中',
            startDate: '2026-03-15',
            endDate: '2026-05-31',
            manager: '张三',
            department: '技术部',
            progress: 35,
            alertText: '⚠️ 1 个紧急任务 · 3 个警告任务',
            tasks: [
                { id:'T001',name:'需求调研与分析',phase:'需求阶段',assignee:'张三',startDate:'2026-03-15',endDate:'2026-03-22',duration:7,priority:'高',status:'已完成',progress:100,dependencies:[] },
                { id:'T002',name:'竞品分析',phase:'需求阶段',assignee:'李四',startDate:'2026-03-18',endDate:'2026-03-25',duration:7,priority:'中',status:'已完成',progress:100,dependencies:[] },
                { id:'T003',name:'技术选型',phase:'需求阶段',assignee:'张三',startDate:'2026-03-25',endDate:'2026-03-28',duration:3,priority:'高',status:'已完成',progress:100,dependencies:['T001'] },
                { id:'T004',name:'需求文档编写',phase:'需求阶段',assignee:'李四',startDate:'2026-03-28',endDate:'2026-03-31',duration:3,priority:'中',status:'已完成',progress:100,dependencies:['T002'] },
                { id:'T005',name:'技术架构设计',phase:'设计阶段',assignee:'张三',startDate:'2026-04-01',endDate:'2026-04-08',duration:7,priority:'高',status:'进行中',progress:75,dependencies:['T003'] },
                { id:'T006',name:'数据库设计',phase:'设计阶段',assignee:'张三',startDate:'2026-04-05',endDate:'2026-04-10',duration:5,priority:'中',status:'进行中',progress:60,dependencies:['T003'] },
                { id:'T007',name:'API 接口设计',phase:'设计阶段',assignee:'张三',startDate:'2026-04-08',endDate:'2026-04-12',duration:4,priority:'中',status:'进行中',progress:40,dependencies:['T005'] },
                { id:'T008',name:'UI/UX 设计',phase:'设计阶段',assignee:'李四',startDate:'2026-04-05',endDate:'2026-04-10',duration:5,priority:'高',status:'进行中',progress:70,dependencies:['T004'] },
                { id:'T009',name:'设计评审',phase:'设计阶段',assignee:'张三',startDate:'2026-04-12',endDate:'2026-04-14',duration:2,priority:'高',status:'未开始',progress:0,dependencies:['T005','T006','T007','T008'] },
                { id:'T010',name:'核心模块开发',phase:'开发阶段',assignee:'张三',startDate:'2026-04-15',endDate:'2026-05-05',duration:20,priority:'高',status:'未开始',progress:0,dependencies:['T009'] },
            ],
            milestones: [
                { name:'需求分析完成',targetDate:'2026-03-31',deliverables:['需求规格说明书'],status:'已完成' },
                { name:'系统设计完成',targetDate:'2026-04-15',deliverables:['架构设计文档','数据库设计文档','UI 设计稿'],status:'进行中' },
                { name:'开发实施完成',targetDate:'2026-05-15',deliverables:['可运行系统','API 文档'],status:'待开始' },
                { name:'测试验收完成',targetDate:'2026-05-31',deliverables:['测试报告','验收报告'],status:'待开始' },
            ],
            risks: [
                { title:'资源过载 · 张三',level:'高',mitigation:'技术负责人负载 95%，负责任务 9 个，建议重新分配' },
                { title:'时间风险 · 技术架构设计',level:'中',mitigation:'T005 仅剩 2 天，进度 75%，需优先处理' },
                { title:'依赖风险 · 设计评审',level:'中',mitigation:'T009 依赖 T005-T008 完成，需密切关注' },
            ],
            team: [
                { role:'技术负责人',name:'张三',count:1,desc:'系统架构与核心开发',load:95 },
                { role:'产品经理',name:'李四',count:1,desc:'需求管理与 UI 设计',load:72 },
                { role:'测试负责人',name:'王五',count:1,desc:'测试用例与质量保障',load:65 },
            ],
            createdAt: '2026-03-15T08:00:00.000Z',
        },
        {
            projectId: 'PRJ-2026-002',
            projectName: '💼 CRM 系统迁移',
            projectType: '外部交付',
            priority: '高',
            status: '正常',
            startDate: '2026-04-01',
            endDate: '2026-06-30',
            manager: '李四',
            department: '技术部',
            progress: 55,
            alertText: '✅ 所有任务正常进行',
            tasks: [
                { id:'T001',name:'旧系统数据梳理',phase:'分析',assignee:'李四',startDate:'2026-04-01',endDate:'2026-04-10',duration:9,priority:'高',status:'已完成',progress:100,dependencies:[] },
                { id:'T002',name:'迁移方案设计',phase:'设计',assignee:'李四',startDate:'2026-04-10',endDate:'2026-04-18',duration:8,priority:'高',status:'已完成',progress:100,dependencies:['T001'] },
                { id:'T003',name:'数据迁移开发',phase:'开发',assignee:'李四',startDate:'2026-04-18',endDate:'2026-05-20',duration:32,priority:'高',status:'进行中',progress:55,dependencies:['T002'] },
                { id:'T004',name:'集成测试',phase:'测试',assignee:'王五',startDate:'2026-05-20',endDate:'2026-06-10',duration:21,priority:'中',status:'未开始',progress:0,dependencies:['T003'] },
                { id:'T005',name:'上线切换',phase:'部署',assignee:'李四',startDate:'2026-06-10',endDate:'2026-06-30',duration:20,priority:'高',status:'未开始',progress:0,dependencies:['T004'] },
            ],
            milestones: [
                { name:'方案评审通过',targetDate:'2026-04-18',deliverables:['迁移方案'],status:'已完成' },
                { name:'数据迁移完成',targetDate:'2026-05-20',deliverables:['迁移报告'],status:'进行中' },
                { name:'系统上线',targetDate:'2026-06-30',deliverables:['验收报告'],status:'待开始' },
            ],
            risks: [],
            team: [
                { role:'项目经理',name:'李四',count:1,desc:'整体迁移管理',load:60 },
                { role:'测试工程师',name:'王五',count:1,desc:'数据验证与测试',load:40 },
            ],
            createdAt: '2026-04-01T08:00:00.000Z',
        },
        {
            projectId: 'PRJ-2026-003',
            projectName: '📊 数据分析平台',
            projectType: '内部研发',
            priority: '中',
            status: '有风险',
            startDate: '2026-03-20',
            endDate: '2026-06-15',
            manager: '王五',
            department: '数据部',
            progress: 42,
            alertText: '⚠️ 资源冲突 · 进度滞后',
            tasks: [
                { id:'T001',name:'需求调研',phase:'需求',assignee:'王五',startDate:'2026-03-20',endDate:'2026-04-01',duration:12,priority:'高',status:'已完成',progress:100,dependencies:[] },
                { id:'T002',name:'数据架构设计',phase:'设计',assignee:'王五',startDate:'2026-04-01',endDate:'2026-04-15',duration:14,priority:'高',status:'已完成',progress:100,dependencies:['T001'] },
                { id:'T003',name:'数据采集模块',phase:'开发',assignee:'王五',startDate:'2026-04-15',endDate:'2026-05-15',duration:30,priority:'高',status:'进行中',progress:35,dependencies:['T002'] },
                { id:'T004',name:'可视化报表',phase:'开发',assignee:'王五',startDate:'2026-04-20',endDate:'2026-05-20',duration:30,priority:'中',status:'进行中',progress:20,dependencies:['T002'] },
                { id:'T005',name:'系统测试',phase:'测试',assignee:'王五',startDate:'2026-05-20',endDate:'2026-06-05',duration:16,priority:'中',status:'未开始',progress:0,dependencies:['T003','T004'] },
                { id:'T006',name:'上线部署',phase:'部署',assignee:'王五',startDate:'2026-06-05',endDate:'2026-06-15',duration:10,priority:'低',status:'未开始',progress:0,dependencies:['T005'] },
            ],
            milestones: [
                { name:'架构评审通过',targetDate:'2026-04-15',deliverables:['架构文档'],status:'已完成' },
                { name:'核心模块完成',targetDate:'2026-05-15',deliverables:['模块代码'],status:'进行中' },
                { name:'系统上线',targetDate:'2026-06-15',deliverables:['部署文档'],status:'待开始' },
            ],
            risks: [
                { title:'资源冲突',level:'中',mitigation:'王五同时负责两个项目，需协调资源' },
            ],
            team: [
                { role:'数据工程师',name:'王五',count:1,desc:'数据架构与开发',load:85 },
            ],
            createdAt: '2026-03-20T08:00:00.000Z',
        },
        {
            projectId: 'PRJ-2026-004',
            projectName: '📱 移动端应用开发',
            projectType: '外部交付',
            priority: '中',
            status: '正常',
            startDate: '2026-04-10',
            endDate: '2026-07-10',
            manager: '赵六',
            department: '产品部',
            progress: 20,
            alertText: '✅ 初期阶段，进展顺利',
            tasks: [
                { id:'T001',name:'产品原型设计',phase:'设计',assignee:'赵六',startDate:'2026-04-10',endDate:'2026-04-25',duration:15,priority:'高',status:'进行中',progress:70,dependencies:[] },
                { id:'T002',name:'技术方案',phase:'设计',assignee:'赵六',startDate:'2026-04-20',endDate:'2026-05-05',duration:15,priority:'高',status:'进行中',progress:30,dependencies:[] },
                { id:'T003',name:'前端开发',phase:'开发',assignee:'赵六',startDate:'2026-05-05',endDate:'2026-06-15',duration:41,priority:'高',status:'未开始',progress:0,dependencies:['T001','T002'] },
                { id:'T004',name:'后端开发',phase:'开发',assignee:'赵六',startDate:'2026-05-05',endDate:'2026-06-20',duration:46,priority:'高',status:'未开始',progress:0,dependencies:['T002'] },
                { id:'T005',name:'测试上线',phase:'测试',assignee:'赵六',startDate:'2026-06-20',endDate:'2026-07-10',duration:20,priority:'中',status:'未开始',progress:0,dependencies:['T003','T004'] },
            ],
            milestones: [
                { name:'原型评审',targetDate:'2026-04-25',deliverables:['原型稿'],status:'进行中' },
                { name:'开发完成',targetDate:'2026-06-20',deliverables:['应用代码'],status:'待开始' },
                { name:'上线发布',targetDate:'2026-07-10',deliverables:['发布包'],status:'待开始' },
            ],
            risks: [],
            team: [
                { role:'产品经理',name:'赵六',count:1,desc:'产品与项目管理',load:50 },
            ],
            createdAt: '2026-04-10T08:00:00.000Z',
        },
        {
            projectId: 'PRJ-2026-005',
            projectName: '🔒 安全合规审计',
            projectType: '管理改善',
            priority: '高',
            status: '已延期',
            startDate: '2026-03-01',
            endDate: '2026-04-30',
            manager: '钱七',
            department: '安全部',
            progress: 68,
            alertText: '🔴 已延期 5 天 · 需立即处理',
            tasks: [
                { id:'T001',name:'安全评估',phase:'评估',assignee:'钱七',startDate:'2026-03-01',endDate:'2026-03-15',duration:14,priority:'高',status:'已完成',progress:100,dependencies:[] },
                { id:'T002',name:'合规差距分析',phase:'分析',assignee:'钱七',startDate:'2026-03-15',endDate:'2026-04-01',duration:17,priority:'高',status:'已完成',progress:100,dependencies:['T001'] },
                { id:'T003',name:'整改方案制定',phase:'整改',assignee:'钱七',startDate:'2026-04-01',endDate:'2026-04-20',duration:19,priority:'高',status:'进行中',progress:80,dependencies:['T002'] },
                { id:'T004',name:'整改执行',phase:'整改',assignee:'钱七',startDate:'2026-04-20',endDate:'2026-04-30',duration:10,priority:'高',status:'进行中',progress:40,dependencies:['T003'] },
            ],
            milestones: [
                { name:'评估完成',targetDate:'2026-03-15',deliverables:['评估报告'],status:'已完成' },
                { name:'整改完成',targetDate:'2026-04-30',deliverables:['整改报告'],status:'进行中' },
            ],
            risks: [
                { title:'延期风险',level:'高',mitigation:'已延期 5 天，需加急处理剩余工作' },
            ],
            team: [
                { role:'安全工程师',name:'钱七',count:1,desc:'安全评估与整改',load:90 },
            ],
            createdAt: '2026-03-01T08:00:00.000Z',
        },
    ];


    // ─── 内部：确保种子数据已写入 ───
    function _ensureSeed() {
        if (localStorage.getItem(SEED_KEY)) return;
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(SEED_PROJECTS));
            localStorage.setItem(SEED_KEY, 'true');
        } catch (e) {
            console.error('[PMO] 种子数据写入失败:', e);
        }
    }


    // ─── 内部：读取原始数据 ───
    function _read() {
        _ensureSeed();
        try {
            return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
        } catch {
            return JSON.parse(JSON.stringify(SEED_PROJECTS));
        }
    }

    // ─── 内部：写入数据 ───
    function _write(projects) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(projects));
    }


    // ═══════════════════════════════
    //  公开 API
    // ═══════════════════════════════

    /** 获取所有项目 */
    function getAll() { return _read(); }

    /** 根据 ID 获取单个项目 */
    function getById(id) { return _read().find(p => p.projectId === id) || null; }

    /** 新增项目 */
    function add(project) {
        const list = _read();
        // 确保有默认字段
        project.createdAt = project.createdAt || new Date().toISOString();
        project.progress = project.progress || 0;
        project.status = project.status || '规划中';
        project.tasks = project.tasks || [];
        project.milestones = project.milestones || [];
        project.risks = project.risks || [];
        project.team = project.team || [];
        list.push(project);
        _write(list);
        return project;
    }

    /** 更新项目 */
    function update(id, changes) {
        const list = _read();
        const idx = list.findIndex(p => p.projectId === id);
        if (idx === -1) return null;
        list[idx] = { ...list[idx], ...changes, projectId: id };
        _write(list);
        return list[idx];
    }

    /** 删除项目 */
    function remove(id) {
        const list = _read().filter(p => p.projectId !== id);
        _write(list);
    }

    /** 获取仪表板统计数据 */
    function getStats() {
        const projects = _read();
        const total = projects.length;
        const active = projects.filter(p => p.status === '进行中' || p.status === '正常').length;
        const atRisk = projects.filter(p => p.status === '有风险').length;
        const delayed = projects.filter(p => p.status === '已延期').length;
        const planned = projects.filter(p => p.status === '规划中').length;

        const allTasks = projects.flatMap(p => p.tasks || []);
        const totalTasks = allTasks.length;
        const completedTasks = allTasks.filter(t => t.status === '已完成').length;
        const inProgressTasks = allTasks.filter(t => t.status === '进行中').length;

        // 收集所有团队成员（去重按 name）
        const memberMap = {};
        projects.forEach(p => (p.team || []).forEach(m => {
            if (!memberMap[m.name]) memberMap[m.name] = { name: m.name, role: m.role, load: 0, projects: 0 };
            memberMap[m.name].load = Math.max(memberMap[m.name].load, m.load || 0);
            memberMap[m.name].projects++;
        }));
        const members = Object.values(memberMap);

        // 收集所有风险（高/中级别）
        const risks = [];
        projects.forEach(p => (p.risks || []).forEach(r => {
            if (r.level === '高' || r.level === '中') {
                risks.push({ ...r, projectName: p.projectName, projectId: p.projectId });
            }
        }));

        return { total, active, atRisk, delayed, planned, totalTasks, completedTasks, inProgressTasks, members, risks, projects };
    }

    /** 获取项目的状态对应的 CSS class */
    function getStatusClass(status) {
        const map = {
            '正常': 'normal', '进行中': 'normal',
            '有风险': 'warning', '规划中': 'warning',
            '已延期': 'urgent',
        };
        return map[status] || 'normal';
    }

    /** 获取状态标签样式 */
    function getStatusPill(status) {
        const map = {
            '正常': 'pill-green', '进行中': 'pill-green',
            '有风险': 'pill-orange', '规划中': 'pill-orange',
            '已延期': 'pill-red',
        };
        return { cls: map[status] || 'pill-blue', text: status };
    }

    /** 重置为种子数据（调试用） */
    function reset() {
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(SEED_KEY);
        _ensureSeed();
    }

    return { getAll, getById, add, update, remove, getStats, getStatusClass, getStatusPill, reset };
})();
