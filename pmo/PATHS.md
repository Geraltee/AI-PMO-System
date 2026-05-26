# 📍 AI PMO 系统 - 路径速查

## ✅ 系统已安装到 D 盘

---

## 🏠 核心路径

```
D:\AI-PMO-System\pmo\
```

---

## 📁 完整目录结构

```
D:\AI-PMO-System\pmo\
│
├── 📄 README.md                  # 系统说明
├── 📄 QUICKSTART.md              # 快速入门指南
├── 📄 INSTALL_LOCATION.md        # 位置说明
├── 📄 PATHS.md                   # 本文件（路径速查）
│
├── 📂 projects\                  # 项目档案
│   └── PRJ-2026-001.md           # 示例项目
│
├── 📂 templates\                 # 模板文件
│   ├── project-template.md       # 项目模板
│   ├── weekly-report.md          # 周报模板
│   └── risk-log.md               # 风险日志模板
│
├── 📂 memory\                    # PMO 记忆库
│   └── pmo-memory.md             # 跨项目记忆
│
├── 📂 config\                    # 配置
│   └── cron-jobs.json            # 定时任务配置
│
└── 📂 scripts\                   # 脚本
    └── pmo-core.ps1              # 主脚本
```

---

## 🚀 快速启动命令

```powershell
# 1. 打开 PowerShell
# Win + R → 输入 powershell → 回车

# 2. 进入 PMO 目录
cd D:\AI-PMO-System\pmo\scripts

# 3. 查看帮助
.\pmo-core.ps1 help

# 4. 查看项目状态
.\pmo-core.ps1 status

# 5. 创建新项目
.\pmo-core.ps1 new "项目名称"

# 6. 查看项目详情
.\pmo-core.ps1 show PRJ-2026-001
```

---

## 📌 常用路径速查

| 用途 | 路径 |
|------|------|
| **主目录** | `D:\AI-PMO-System\pmo\` |
| **脚本目录** | `D:\AI-PMO-System\pmo\scripts\` |
| **项目档案** | `D:\AI-PMO-System\pmo\projects\` |
| **模板文件** | `D:\AI-PMO-System\pmo\templates\` |
| **配置文件** | `D:\AI-PMO-System\pmo\config\` |
| **记忆库** | `D:\AI-PMO-System\pmo\memory\` |

---

## 🔗 创建桌面快捷方式

### 方法 1：PowerShell 快捷方式

1. 右键桌面 → 新建 → 快捷方式
2. 输入位置：
   ```
   powershell -NoExit -Command "cd D:\AI-PMO-System\pmo\scripts"
   ```
3. 命名：`AI PMO 系统`
4. 完成！双击即可打开

### 方法 2：添加到 PowerShell 配置文件

```powershell
# 在 PowerShell 中运行
echo "Set-Alias pmo D:\AI-PMO-System\pmo\scripts\pmo-core.ps1" >> $PROFILE

# 重启 PowerShell 后可直接使用
pmo status
pmo new "项目名"
```

---

## ⏰ 定时任务配置

配置文件位置：
```
D:\AI-PMO-System\pmo\config\cron-jobs.json
```

激活命令：
```bash
openclaw cron add --job D:\AI-PMO-System\pmo\config\cron-jobs.json
```

---

## 📞 需要帮助？

- **快速入门**：`D:\AI-PMO-System\pmo\QUICKSTART.md`
- **系统说明**：`D:\AI-PMO-System\pmo\README.md`
- **架构文档**：`D:\AI-PMO-System\pmo\ARCHITECTURE.md`

---

**版本**: v0.1.0  
**安装日期**: 2026-04-03  
**安装位置**: `D:\AI-PMO-System\pmo\`

---

🎉 祝使用愉快！
