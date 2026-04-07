# PMO 会话记录导入教程

**适用场景**: 将 `session-records/2026-04-07-session-summary.md` 导入到另一台电脑的 OpenClaw 系统中

**文档版本**: v1.0  
**最后更新**: 2026-04-07 11:18 EDT

---

## 📋 目录

1. [导入前准备](#1-导入前准备)
2. [方法一：Git 同步（推荐）](#2-方法一 git 同步推荐)
3. [方法二：手动复制文件](#3-方法二手动复制文件)
4. [方法三：通过 OpenClaw 会话发送](#4-方法三通过 openclaw 会话发送)
5. [导入后验证](#5-导入后验证)
6. [常见问题](#6-常见问题)

---

## 1. 导入前准备

### 1.1 确认目标环境

在目标电脑上检查：

```bash
# 检查 OpenClaw 是否安装
openclaw --version

# 检查工作区位置
openclaw status
```

### 1.2 确认工作区路径

默认工作区路径：
- **Windows**: `D:\AI-PMO-System` 或 `C:\Users\<用户名>\.openclaw\workspace`
- **macOS/Linux**: `~/openclaw-workspace`

### 1.3 需要准备的文件

**必需文件**:
```
session-records/2026-04-07-session-summary.md
```

**可选文件**（完整上下文）:
```
PMO-QUICK-IMPORT.md
memory/2026-04-07.md
pmo-automation/output/dashboard-with-retrieval/*.html
pmo-automation/data/project-tasks-PRJ-2026-001.json
pmo/memory/pmo-memory.md
```

---

## 2. 方法一：Git 同步（推荐）

### 适用场景
- 源和目标电脑都连接到同一个 Git 仓库
- 需要完整的版本历史

### 步骤

#### 步骤 1: 在源电脑上提交并推送

```bash
cd D:\AI-PMO-System

# 查看状态
git status

# 添加文件
git add session-records/2026-04-07-session-summary.md
git add PMO-QUICK-IMPORT.md

# 提交
git commit -m "添加 PMO 会话记录 (2026-04-07)"

# 推送到远程仓库
git push origin master
```

#### 步骤 2: 在目标电脑上拉取

```bash
# 进入工作区
cd <工作区路径>

# 拉取最新代码
git pull origin master

# 验证文件存在
ls session-records/2026-04-07-session-summary.md
```

#### 步骤 3: 在 OpenClaw 中读取

```
请读取 session-records/2026-04-07-session-summary.md 文件，了解今天的 PMO 任务检查和 Dashboard 开发记录。
```

### ✅ 优点
- 完整的版本历史
- 自动处理文件冲突
- 可追溯变更

### ⚠️ 注意事项
- 确保目标电脑有 Git 仓库访问权限
- 如有冲突需手动解决

---

## 3. 方法二：手动复制文件

### 适用场景
- 没有 Git 仓库
- 通过 U 盘/网络共享传输
- 快速单次导入

### 步骤

#### 步骤 1: 在源电脑上导出文件

**方式 A: 复制到 U 盘**
```bash
# 假设 U 盘路径为 E:\
mkdir E:\PMO-Import
copy D:\AI-PMO-System\session-records\2026-04-07-session-summary.md E:\PMO-Import\
copy D:\AI-PMO-System\PMO-QUICK-IMPORT.md E:\PMO-Import\
```

**方式 B: 打包为 ZIP**
```bash
# 使用 PowerShell 压缩
Compress-Archive -Path D:\AI-PMO-System\session-records\2026-04-07-session-summary.md, D:\AI-PMO-System\PMO-QUICK-IMPORT.md -DestinationPath D:\PMO-Import.zip
```

**方式 C: 网络共享**
```bash
# 复制到网络共享位置
copy D:\AI-PMO-System\session-records\2026-04-07-session-summary.md \\目标电脑\Share\
```

#### 步骤 2: 在目标电脑上导入

```bash
# 进入 OpenClaw 工作区
cd <工作区路径>

# 创建 session-records 目录（如果不存在）
mkdir session-records

# 复制文件
copy <源路径>\2026-04-07-session-summary.md session-records\
copy <源路径>\PMO-QUICK-IMPORT.md .\
```

#### 步骤 3: 验证导入

```bash
# 检查文件是否存在
dir session-records\2026-04-07-session-summary.md

# 查看文件内容
type session-records\2026-04-07-session-summary.md
```

### ✅ 优点
- 不需要 Git
- 简单直接
- 适合单次传输

### ⚠️ 注意事项
- 确保文件路径正确
- 注意文件编码（UTF-8）

---

## 4. 方法三：通过 OpenClaw 会话发送

### 适用场景
- 两台电脑都运行 OpenClaw
- 通过消息通道传输

### 步骤

#### 步骤 1: 在源电脑上发送

```
请将会话记录文件 session-records/2026-04-07-session-summary.md 的内容发送到目标 OpenClaw 会话。
```

或者使用 `sessions_send` 工具（如果有配置）：

```json
{
  "action": "send",
  "target": "目标会话 ID",
  "message": "PMO 会话记录已准备就绪，包含任务检查、邮件草稿、Dashboard 开发记录。"
}
```

#### 步骤 2: 在目标电脑上接收

目标 OpenClaw 会收到消息，然后：

```
请读取并保存 PMO 会话记录内容到 session-records/2026-04-07-session-summary.md
```

### ✅ 优点
- 实时传输
- 不需要物理介质

### ⚠️ 注意事项
- 需要配置会话间通信
- 大文件可能受限

---

## 5. 导入后验证

### 5.1 检查文件完整性

```bash
# 检查文件大小
ls -lh session-records/2026-04-07-session-summary.md

# 预期大小：约 6KB
```

### 5.2 读取文件内容

在 OpenClaw 中执行：

```
读取 session-records/2026-04-07-session-summary.md 文件，确认内容完整。
```

### 5.3 验证关键信息

确认文件中包含以下章节：
- [ ] PMO 任务到期检查
- [ ] 邮件草稿生成
- [ ] OpenClaw 配置更新
- [ ] Dashboard 选项卡跳转开发
- [ ] 文件清单
- [ ] 服务器配置

### 5.4 测试相关文件

如果导入了 Dashboard 文件：

```bash
# 启动服务器测试
cd pmo/web
powershell -ExecutionPolicy Bypass -File .\start-server.ps1

# 访问 http://localhost:5000/index.html
```

---

## 6. 常见问题

### Q1: 文件路径不存在？

**问题**: `session-records` 目录不存在

**解决**:
```bash
mkdir session-records
```

### Q2: 文件编码错误？

**问题**: 中文显示乱码

**解决**:
- 使用 UTF-8 编码保存文件
- 在编辑器中转换编码（Notepad++ / VSCode）

### Q3: Git 冲突？

**问题**: `git pull` 时出现冲突

**解决**:
```bash
# 查看冲突文件
git status

# 手动编辑解决冲突
# 然后标记为已解决
git add session-records/2026-04-07-session-summary.md

# 完成合并
git commit
```

### Q4: 文件太大无法传输？

**问题**: 需要传输完整项目文件

**解决**:
```bash
# 使用压缩
Compress-Archive -Path D:\AI-PMO-System\* -DestinationPath D:\AI-PMO-System-Full.zip

# 分卷压缩（如果支持）
```

### Q5: OpenClaw 无法读取文件？

**问题**: `read` 工具报错

**解决**:
1. 检查文件路径是否正确
2. 确认文件权限
3. 检查文件是否被其他程序占用

---

## 📞 获取帮助

如果导入过程中遇到问题：

1. **检查日志**: 查看 OpenClaw 会话历史
2. **验证文件**: 确认文件完整性和编码
3. **联系支持**: 提供错误信息和截图

---

## 📝 导入检查清单

导入完成后，确认以下项目：

- [ ] 文件已复制到正确位置
- [ ] 文件大小正确（约 6KB）
- [ ] 文件内容为 UTF-8 编码
- [ ] OpenClaw 可以读取文件
- [ ] 关键章节完整（任务检查/邮件/配置/Dashboard）
- [ ] （可选）Dashboard 可以正常访问
- [ ] （可选）Git 提交历史完整

---

## 🎯 快速命令参考

### 源电脑（导出）
```bash
cd D:\AI-PMO-System
git add session-records/2026-04-07-session-summary.md
git commit -m "添加 PMO 会话记录"
git push origin master
```

### 目标电脑（导入）
```bash
cd <工作区路径>
git pull origin master
cat session-records/2026-04-07-session-summary.md
```

---

**教程版本**: v1.0  
**创建时间**: 2026-04-07 11:18 EDT  
**适用系统**: Windows / macOS / Linux + OpenClaw
