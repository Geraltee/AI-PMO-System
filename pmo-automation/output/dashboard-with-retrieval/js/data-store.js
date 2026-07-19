/**
 * ═══════════════════════════════════════════════════════════
 *  PMO Dashboard — 共享数据层 v3.0
 * ═══════════════════════════════════════════════════════════
 *
 *  核心升级：
 *  - milestone 增加 decisionPoint / owner / priority / gatingCriteria / relatedTaskIds
 *  - task 增加 milestone / deliverable / riskPoints
 *  - project 增加 sopDocument / meta / sopRules
 *  - 新增 adjustTeam() 团队动态调整方法
 *
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
                { id:'T001',name:'需求调研与分析',phase:'需求阶段',milestone:'需求分析完成',assignee:'张三',startDate:'2026-03-15',endDate:'2026-03-22',duration:7,priority:'高',status:'已完成',progress:100,dependencies:[],deliverable:'需求调研报告',riskPoints:['调研对象配合度不确定'] },
                { id:'T002',name:'竞品分析',phase:'需求阶段',milestone:'需求分析完成',assignee:'李四',startDate:'2026-03-18',endDate:'2026-03-25',duration:7,priority:'中',status:'已完成',progress:100,dependencies:[],deliverable:'竞品分析报告',riskPoints:['竞品信息获取渠道有限'] },
                { id:'T003',name:'技术选型',phase:'需求阶段',milestone:'需求分析完成',assignee:'张三',startDate:'2026-03-25',endDate:'2026-03-28',duration:3,priority:'高',status:'已完成',progress:100,dependencies:['T001'],deliverable:'技术选型文档',riskPoints:['新技术成熟度风险'] },
                { id:'T004',name:'需求文档编写',phase:'需求阶段',milestone:'需求分析完成',assignee:'李四',startDate:'2026-03-28',endDate:'2026-03-31',duration:3,priority:'中',status:'已完成',progress:100,dependencies:['T002'],deliverable:'需求规格说明书',riskPoints:['需求变更频繁'] },
                { id:'T005',name:'技术架构设计',phase:'设计阶段',milestone:'系统设计完成',assignee:'张三',startDate:'2026-04-01',endDate:'2026-04-08',duration:7,priority:'高',status:'进行中',progress:75,dependencies:['T003'],deliverable:'架构设计文档',riskPoints:['架构复杂度超预期'] },
                { id:'T006',name:'数据库设计',phase:'设计阶段',milestone:'系统设计完成',assignee:'张三',startDate:'2026-04-05',endDate:'2026-04-10',duration:5,priority:'中',status:'进行中',progress:60,dependencies:['T003'],deliverable:'数据库设计文档',riskPoints:['数据模型需反复调整'] },
                { id:'T007',name:'API 接口设计',phase:'设计阶段',milestone:'系统设计完成',assignee:'张三',startDate:'2026-04-08',endDate:'2026-04-12',duration:4,priority:'中',status:'进行中',progress:40,dependencies:['T005'],deliverable:'API 接口文档',riskPoints:[] },
                { id:'T008',name:'UI/UX 设计',phase:'设计阶段',milestone:'系统设计完成',assignee:'李四',startDate:'2026-04-05',endDate:'2026-04-10',duration:5,priority:'高',status:'进行中',progress:70,dependencies:['T004'],deliverable:'UI 设计稿',riskPoints:['设计评审意见分歧'] },
                { id:'T009',name:'设计评审',phase:'设计阶段',milestone:'系统设计完成',assignee:'张三',startDate:'2026-04-12',endDate:'2026-04-14',duration:2,priority:'高',status:'未开始',progress:0,dependencies:['T005','T006','T007','T008'],deliverable:'评审纪要',riskPoints:['评审不通过需返工'] },
                { id:'T010',name:'核心模块开发',phase:'开发阶段',milestone:'开发实施完成',assignee:'张三',startDate:'2026-04-15',endDate:'2026-05-05',duration:20,priority:'高',status:'未开始',progress:0,dependencies:['T009'],deliverable:'可运行系统',riskPoints:['技术难点攻克超时','资源过载'] },
            ],
            milestones: [
                { name:'需求分析完成', decisionPoint:'需求是否完整覆盖业务需求，方案是否通过评审', targetDate:'2026-03-31', deliverables:['需求规格说明书'], owner:'张三', priority:'高', status:'已完成', gatingCriteria:'需求文档需获得产品负责人签字', relatedTaskIds:['T001','T002','T004'] },
                { name:'系统设计完成', decisionPoint:'技术架构是否满足非功能需求，设计方案是否通过技术评审', targetDate:'2026-04-15', deliverables:['架构设计文档','数据库设计文档','UI 设计稿'], owner:'张三', priority:'高', status:'进行中', gatingCriteria:'设计评审通过，无重大技术风险遗留', relatedTaskIds:['T005','T006','T007','T008','T009'] },
                { name:'开发实施完成', decisionPoint:'核心功能是否全部实现并通过单元测试', targetDate:'2026-05-15', deliverables:['可运行系统','API 文档'], owner:'张三', priority:'高', status:'待开始', gatingCriteria:'代码覆盖率 > 80%，核心用例全部通过', relatedTaskIds:['T010'] },
                { name:'测试验收完成', decisionPoint:'是否满足验收标准，是否可发布上线', targetDate:'2026-05-31', deliverables:['测试报告','验收报告'], owner:'王五', priority:'高', status:'待开始', gatingCriteria:'零 P0/P1 缺陷，性能达标', relatedTaskIds:[] },
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


    // ─── 清空模式标记（v2 — 真实数据模式）───
    const CLEAN_VERSION = 'v2-clean';

    // ─── 内部：确保数据初始化 ───
    function _ensureSeed() {
        const version = localStorage.getItem(SEED_KEY);
        if (version === CLEAN_VERSION) return;  // 已经是清空模式，不动
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify([]));  // 清空所有项目数据
            localStorage.setItem(SEED_KEY, CLEAN_VERSION);
        } catch (e) {
            console.error('[PMO] 初始化失败:', e);
        }
    }


    // ─── 内部：读取原始数据 ───
    function _read() {
        _ensureSeed();
        let projects;
        try {
            projects = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
        } catch {
            projects = JSON.parse(JSON.stringify(SEED_PROJECTS));
        }
        // 修复历史遗留的重复 / 缺失 projectId（自动自愈，无需用户手动清空数据）
        const repaired = _repairIds(projects);
        if (repaired.changed) _write(repaired.projects);
        return repaired.projects;
    }

    // ─── 生成唯一项目编号（按年份递增，确保不与已有项目冲突）───
    function _genProjectId(list) {
        const year = new Date().getFullYear();
        const prefix = `PRJ-${year}-`;
        const seqs = (list || [])
            .map(p => p.projectId)
            .filter(id => typeof id === 'string' && id.indexOf(prefix) === 0)
            .map(id => parseInt(id.slice(prefix.length), 10))
            .filter(n => !isNaN(n));
        let next = (seqs.length ? Math.max.apply(null, seqs) : 0) + 1;
        let id = `${prefix}${String(next).padStart(3, '0')}`;
        // 兜底：极端情况下仍冲突，追加时间戳后缀
        let guard = 0;
        while ((list || []).some(p => p.projectId === id) && guard < 100) {
            id = `${prefix}${String(next).padStart(3, '0')}-${String(Date.now()).slice(-4)}`;
            guard++;
        }
        return id;
    }

    // ─── 修复重复 / 缺失的项目编号 ───
    function _repairIds(projects) {
        const seen = {};
        let changed = false;
        (projects || []).forEach(p => {
            let id = p.projectId;
            if (!id || seen[id]) {
                id = _genProjectId(projects); // 基于当前列表生成唯一 ID
                p.projectId = id;
                changed = true;
            }
            seen[id] = true;
        });
        return { projects, changed };
    }

    // ─── 内部：写入数据 ───
    function _write(projects) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(projects));
        _syncToServer(projects);  // 自动同步到服务器文件
    }

    // ─── 数据同步：将 localStorage 数据 POST 到本地服务器 ───
    // 服务器将数据保存到 data/dashboard-data.json，供自动化周报读取
    // 如果服务器未启动，静默失败，不影响正常使用
    const SYNC_URL = '/api/data';
    let _syncPending = false;

    function _syncToServer(projects) {
        if (_syncPending) return;  // 防抖：上一次同步未完成时跳过
        _syncPending = true;
        fetch(SYNC_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(projects),
        }).then(resp => {
            if (resp.ok) console.log('[PMO] 数据已同步到服务器');
        }).catch(() => {
            // 服务器未启动时静默忽略
        }).finally(() => {
            _syncPending = false;
        });
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
        // 自动生成唯一项目编号，避免 AI 返回的 ID 与已有项目重复（导致详情页张冠李戴）
        if (!project.projectId || list.some(p => p.projectId === project.projectId)) {
            project.projectId = _genProjectId(list);
        }
        project.createdAt = project.createdAt || new Date().toISOString();
        project.progress = project.progress || 0;
        project.status = project.status || '规划中';
        project.tasks = project.tasks || [];
        project.milestones = project.milestones || [];
        project.risks = project.risks || [];
        project.team = project.team || [];
        // v3.0 新字段
        project.sopDocument = project.sopDocument || null;
        project.meta = project.meta || {};
        project.sopRules = project.sopRules || {};
        // 确保里程碑有新字段
        project.milestones.forEach(m => {
            m.decisionPoint = m.decisionPoint || '';
            m.owner = m.owner || '';
            m.priority = m.priority || '中';
            m.gatingCriteria = m.gatingCriteria || '';
            m.relatedTaskIds = m.relatedTaskIds || [];
        });
        // 确保任务有新字段
        project.tasks.forEach(t => {
            t.milestone = t.milestone || '';
            t.deliverable = t.deliverable || '';
            t.riskPoints = t.riskPoints || [];
        });
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

    /** 重置为空白数据（调试用） */
    function reset() {
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(SEED_KEY);
        _ensureSeed();
    }

    /** 恢复为种子演示数据（需要从备份恢复） */
    function restoreSeed() {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(SEED_PROJECTS));
        localStorage.setItem(SEED_KEY, 'v1-seeded');
    }

    /**
     * 团队动态调整：增减成员时自动重分配任务
     * @param {string} projectId - 项目 ID
     * @param {Array} newTeam - 新的团队列表
     * @param {string} action - 'add' | 'remove' | 'replace'
     * @returns {object|null} 更新后的项目，或 null
     *
     * 核心规则：
     * - 仅重新分配「未开始」的任务
     * - 已开始/已完成的任务保持不变（保护已有工作成果）
     * - 被移除成员的未完成任务自动分配给同角色成员或项目 owner
     */
    function adjustTeam(projectId, newTeam, action) {
        const list = _read();
        const idx = list.findIndex(p => p.projectId === projectId);
        if (idx === -1) return null;

        const project = list[idx];
        const oldTeam = project.team || [];
        const tasks = project.tasks || [];

        // 记录被移除的成员
        const removedMembers = [];
        const addedMembers = [];

        if (action === 'remove') {
            // newTeam 是要移除的成员列表
            const removeNames = newTeam.map(m => m.name || m.role);
            removedMembers.push(...oldTeam.filter(m => removeNames.includes(m.name || m.role)));
            project.team = oldTeam.filter(m => !removeNames.includes(m.name || m.role));
        } else if (action === 'add') {
            project.team = [...oldTeam, ...newTeam];
            addedMembers.push(...newTeam);
        } else if (action === 'replace') {
            const oldNames = oldTeam.map(m => m.name || m.role);
            const newNames = newTeam.map(m => m.name || m.role);
            removedMembers.push(...oldTeam.filter(m => !newNames.includes(m.name || m.role)));
            addedMembers.push(...newTeam.filter(m => !oldNames.includes(m.name || m.role)));
            project.team = newTeam;
        }

        // 重新分配「未开始」的任务：被移除成员的任务转移
        if (removedMembers.length > 0) {
            const removeNames = removedMembers.map(m => m.name || m.role);
            tasks.forEach(task => {
                if (task.status === '未开始' && removeNames.includes(task.assignee)) {
                    // 优先分配给同角色成员
                    const sameRole = project.team.find(m => m.role === removedMembers.find(r => (r.name || r.role) === task.assignee)?.role && (m.name || m.role) !== task.assignee);
                    if (sameRole) {
                        task.assignee = sameRole.name || sameRole.role;
                    } else if (project.team.length > 0) {
                        task.assignee = project.team[0].name || project.team[0].role;
                    }
                }
            });
        }

        // 重算每个成员的负载
        const taskCounts = {};
        tasks.filter(t => t.status !== '已完成').forEach(t => {
            taskCounts[t.assignee] = (taskCounts[t.assignee] || 0) + 1;
        });
        const totalActive = tasks.filter(t => t.status !== '已完成').length || 1;
        project.team.forEach(m => {
            const name = m.name || m.role;
            const count = taskCounts[name] || 0;
            m.load = Math.round((count / totalActive) * 100);
            m.assigned = count > 0;
        });

        project.tasks = tasks;
        list[idx] = project;
        _write(list);
        return project;
    }

    /**
     * 更新项目 SOP 文档
     * @param {string} projectId - 项目 ID
     * @param {object} sopData - SOP 文档数据
     * @returns {object|null}
     */
    function updateSOP(projectId, sopData) {
        const list = _read();
        const idx = list.findIndex(p => p.projectId === projectId);
        if (idx === -1) return null;
        list[idx].sopDocument = sopData;
        _write(list);
        return list[idx];
    }

    return { getAll, getById, add, update, remove, getStats, getStatusClass, getStatusPill, reset, restoreSeed, adjustTeam, updateSOP };
})();
