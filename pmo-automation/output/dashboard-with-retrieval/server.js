/**
 * PMO Dashboard — 本地数据同步服务器
 *
 * 功能：
 *   1. 提供静态文件服务（Dashboard 前端）
 *   2. 提供 REST API 读写项目数据（持久化到 JSON 文件）
 *   3. Dashboard 修改数据后自动同步到此文件，周报自动化直接读取
 *
 * 启动：
 *   cd /Users/yudu/Downloads/AI-PMO-System/pmo-automation/output/dashboard-with-retrieval
 *   node server.js
 *   # 默认端口 3456，可通过 PORT 环境变量覆盖
 *   # 数据文件：./data/dashboard-data.json
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3456;
const DASHBOARD_DIR = __dirname;
const DATA_DIR = path.join(DASHBOARD_DIR, 'data');
const DATA_FILE = path.join(DATA_DIR, 'dashboard-data.json');

// 确保数据目录存在
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

// ─── MIME 类型映射 ───
const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js':   'application/javascript; charset=utf-8',
    '.css':  'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.svg':  'image/svg+xml',
    '.ico':  'image/x-icon',
};

// ─── 数据读写 ───
function readData() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            return JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8'));
        }
    } catch (e) {
        console.error('[PMO Server] 读取数据文件失败:', e.message);
    }
    return [];
}

function writeData(projects) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(projects, null, 2), 'utf-8');
}

// ─── 请求处理 ───
function handler(req, res) {
    const parsed = url.parse(req.url, true);
    const pathname = parsed.pathname;

    // API 路由
    if (pathname === '/api/data') {
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method === 'OPTIONS') {
            res.writeHead(204);
            res.end();
            return;
        }

        if (req.method === 'GET') {
            const data = readData();
            res.writeHead(200);
            res.end(JSON.stringify({ ok: true, data: data, updatedAt: fs.existsSync(DATA_FILE) ? fs.statSync(DATA_FILE).mtime.toISOString() : null }));
            console.log(`[PMO Server] GET /api/data → ${data.length} 个项目`);
            return;
        }

        if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => body += chunk);
            req.on('end', () => {
                try {
                    const projects = JSON.parse(body);
                    writeData(projects);
                    console.log(`[PMO Server] POST /api/data → 已保存 ${projects.length} 个项目`);
                    res.writeHead(200);
                    res.end(JSON.stringify({ ok: true, saved: projects.length }));
                } catch (e) {
                    res.writeHead(400);
                    res.end(JSON.stringify({ ok: false, error: e.message }));
                }
            });
            return;
        }
    }

    // 静态文件服务
    let filePath;
    if (pathname === '/') {
        filePath = path.join(DASHBOARD_DIR, 'index.html');
    } else {
        // 防止路径穿越
        const safePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
        filePath = path.join(DASHBOARD_DIR, safePath);
    }

    const ext = path.extname(filePath).toLowerCase();
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
        res.writeHead(404);
        res.end('Not Found');
        return;
    }

    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    fs.createReadStream(filePath).pipe(res);
}

// ─── 启动 ───
const server = http.createServer(handler);
server.listen(PORT, () => {
    console.log('');
    console.log('  ══════════════════════════════════════');
    console.log('  PMO Dashboard Server');
    console.log('  ══════════════════════════════════════');
    console.log(`  地址: http://localhost:${PORT}`);
    console.log(`  数据: ${DATA_FILE}`);
    console.log('  ══════════════════════════════════════');
    console.log('');
});
