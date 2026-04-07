# AI PMO Web 服务器 - Python Flask 版本
# 自动读取项目文件并提供 API

from flask import Flask, send_from_directory, jsonify
from flask_cors import CORS
import os
import re
from datetime import datetime

app = Flask(__name__)
CORS(app)

PMO_ROOT = r"D:\AI-PMO-System\pmo"
PROJECTS_DIR = os.path.join(PMO_ROOT, "projects")

def parse_project_file(filepath):
    """解析 Markdown 项目文件"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    project = {
        'id': '未知',
        'name': '未知',
        'status': 'green',
        'priority': 'P2',
        'owner': '待填写',
        'created': '未知',
        'updated': '未知',
        'progress': 0,
        'milestones': [],
        'risks': []
    }
    
    # 提取项目名称
    match = re.search(r'# 项目档案：(.+)', content)
    if match:
        project['name'] = match.group(1).strip()
    
    # 提取项目 ID
    match = re.search(r'项目 ID \| ([\w-]+)', content)
    if match:
        project['id'] = match.group(1)
    
    # 提取状态
    if '🟢' in content:
        project['status'] = 'green'
    elif '🟡' in content:
        project['status'] = 'yellow'
    elif '🔴' in content:
        project['status'] = 'red'
    
    # 提取优先级
    match = re.search(r'优先级 \| (P[0-3])', content)
    if match:
        project['priority'] = match.group(1)
    
    # 提取负责人
    match = re.search(r'项目负责人 \| (.+)', content)
    if match:
        project['owner'] = match.group(1).strip()
    
    # 提取创建日期
    match = re.search(r'创建日期 \| (.+)', content)
    if match:
        project['created'] = match.group(1).strip()
    
    # 提取最后更新
    match = re.search(r'\*最后更新：(.+)\*', content)
    if match:
        project['updated'] = match.group(1).strip()
    
    # 提取里程碑
    milestone_pattern = r'\| (M\d+: .+?) \| (.+?) \| (.+?) \| (.+?) \|'
    for match in re.finditer(milestone_pattern, content):
        status_text = match.group(4).strip()
        status = 'pending'
        if '已完成' in status_text or '✅' in status_text:
            status = 'done'
        elif '进行中' in status_text or '🔄' in status_text:
            status = 'active'
        
        project['milestones'].append({
            'name': match.group(1).strip(),
            'date': match.group(2).strip(),
            'actual': match.group(3).strip(),
            'status': status
        })
    
    # 提取风险
    risk_pattern = r'\| (.+?) \| (高 | 中|低) \| (高 | 中|低) \| (.+?) \| (.+?) \|'
    for match in re.finditer(risk_pattern, content):
        if match.group(1).strip() and '风险描述' not in match.group(1):
            project['risks'].append({
                'desc': match.group(1).strip(),
                'impact': match.group(2).strip(),
                'prob': match.group(3).strip(),
                'mitigation': match.group(4).strip(),
                'owner': match.group(5).strip()
            })
    
    # 计算进度（基于里程碑完成情况）
    if project['milestones']:
        done = sum(1 for m in project['milestones'] if m['status'] == 'done')
        project['progress'] = int((done / len(project['milestones'])) * 100)
    
    return project

@app.route('/')
def dashboard():
    """提供仪表板页面"""
    return send_from_directory('.', 'dashboard.html')

@app.route('/api/projects')
def get_projects():
    """获取所有项目 API"""
    projects = []
    
    if not os.path.exists(PROJECTS_DIR):
        return jsonify({'error': 'Projects directory not found', 'projects': []})
    
    for filename in os.listdir(PROJECTS_DIR):
        if filename.endswith('.md'):
            filepath = os.path.join(PROJECTS_DIR, filename)
            try:
                project = parse_project_file(filepath)
                projects.append(project)
            except Exception as e:
                print(f"Error parsing {filename}: {e}")
    
    return jsonify({
        'success': True,
        'count': len(projects),
        'projects': projects
    })

@app.route('/api/projects/<project_id>')
def get_project(project_id):
    """获取单个项目详情 API"""
    filepath = os.path.join(PROJECTS_DIR, f"{project_id}.md")
    
    if not os.path.exists(filepath):
        return jsonify({'error': 'Project not found'}), 404
    
    project = parse_project_file(filepath)
    return jsonify({'success': True, 'project': project})

@app.route('/api/stats')
def get_stats():
    """获取统计信息 API"""
    projects = []
    
    for filename in os.listdir(PROJECTS_DIR):
        if filename.endswith('.md'):
            filepath = os.path.join(PROJECTS_DIR, filename)
            try:
                project = parse_project_file(filepath)
                projects.append(project)
            except:
                pass
    
    stats = {
        'total': len(projects),
        'green': sum(1 for p in projects if p['status'] == 'green'),
        'yellow': sum(1 for p in projects if p['status'] == 'yellow'),
        'red': sum(1 for p in projects if p['status'] == 'red'),
        'total_risks': sum(len(p['risks']) for p in projects),
        'avg_progress': int(sum(p['progress'] for p in projects) / len(projects)) if projects else 0
    }
    
    return jsonify({'success': True, 'stats': stats})

if __name__ == '__main__':
    print("=" * 50)
    print("🚀 AI PMO Web Server 启动中...")
    print("=" * 50)
    print(f"📁 项目目录：{PROJECTS_DIR}")
    print(f"🌐 访问地址：http://localhost:5000")
    print(f"📊 API 端点：http://localhost:5000/api/projects")
    print("=" * 50)
    
    app.run(debug=True, port=5000, host='0.0.0.0')
