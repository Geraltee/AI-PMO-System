# 📍 AI PMO 系统 - 位置说明

## ✅ 安装完成！

AI PMO 系统已部署到 D 盘。

---

## 📁 系统位置

```
D:\AI-PMO-System\pmo\
```

---

## 🗂️ 完整目录结构

```
D:\AI-PMO-System\pmo\
│
├── README.md                 # 系统说明
├── QUICKSTART.md             # 快速入门指南
├── ARCHITECTURE.md           # 架构文档
│
├── projects\                 # 项目档案
│   └── PRJ-2026-001.md       # 示例项目
│
├── templates\                # 模板文件
│   ├── project-template.md   # 项目模板
│   ├── weekly-report.md      # 周报模板
│   └── risk-log.md           # 风险日志模板
│
├── memory\                   # PMO 记忆库
│   └── pmo-memory.md         # 跨项目记忆
│
├── config\                   # 配置
│   └── cron-jobs.json        # 定时任务配置
│
└── scripts\                  # 脚本
    ├── pmo.ps1               # 主入口脚本
    └── pmo-core.ps1          # 核心功能脚本
```

---

## 🚀 快速开始

### 1. 打开 PowerShell

右键点击开始菜单 → Windows PowerShell

### 2. 进入 PMO 目录

```powershell
cd D:\AI-PMO-System\pmo\scripts
```

### 3. 查看帮助

```powershell
.\pmo-core.ps1 help
```

### 4. 查看项目状态

```powershell
.\pmo-core.ps1 status
```

### 5. 创建新项目

```powershell
.\pmo-core.ps1 new "你的项目名称"
```

---

## 📝 常用命令速查

| 命令 | 说明 |
|------|------|
| `.\pmo-core.ps1 help` | 显示帮助 |
| `.\pmo-core.ps1 status` | 查看所有项目 |
| `.\pmo-core.ps1 new "项目名"` | 创建新项目 |
| `.\pmo-core.ps1 show PRJ-XXX` | 查看项目详情 |
| `.\pmo-core.ps1 report` | 生成周报 |

---

## 🔗 快捷方式

你可以创建 PowerShell 快捷方式：

```powershell
# 添加到 PowerShell 配置文件
echo "Set-Alias pmo D:\AI-PMO-System\pmo\scripts\pmo-core.ps1" >> $PROFILE

# 重启 PowerShell 后可以直接使用
pmo status
pmo new "项目名"
```

或者创建桌面快捷方式：
1. 右键桌面 → 新建 → 快捷方式
2. 输入：`powershell -NoExit -Command "cd D:\AI-PMO-System\pmo\scripts"`
3. 命名：`AI PMO 系统`

---

## 💡 与 OpenClaw 集成

如果需要与 OpenClaw 深度集成（定时任务、AI 问答等）：

1. **PMO 系统位置：**
   ```
   D:\AI-PMO-System\pmo\
   ```

2. **在 OpenClaw 中访问 PMO 文件：**
   ```
   D:\AI-PMO-System\pmo\projects\
   D:\AI-PMO-System\pmo\config\cron-jobs.json
   ```

3. **激活定时任务：**
   ```bash
   openclaw cron add --job D:\AI-PMO-System\pmo\config\cron-jobs.json
   ```

---

## 📞 需要帮助？

- 查看 `D:\AI-PMO-System\pmo\QUICKSTART.md` 获取详细入门指南
- 查看 `D:\AI-PMO-System\pmo\README.md` 了解系统功能
- 询问 AI 助手获取指导

---

**系统版本**: v0.1.0-alpha  
**安装日期**: 2026-04-03  
**安装位置**: `D:\AI-PMO-System\pmo\`

---

🎉 祝使用愉快！
