/**
 * ═══════════════════════════════════════════════════════════
 *  AI 模型配置中心 — PMO Dashboard
 * ═══════════════════════════════════════════════════════════
 *
 *  ┌────────────────────────────────────────────────────┐
 *  │  后端就绪时：自动调用后端 API（真实 AI）              │
 *  │  后端未启动时：自动降级为 Demo 模式（模拟数据）       │
 *  │                                                    │
 *  │  更换模型：修改 api/.env 中的 AI_MODEL 即可          │
 *  └────────────────────────────────────────────────────┘
 */

// ─── 后端 API 地址 ───
// 后端启动后会自动变为 true，无需手动修改
const API_BASE = 'http://localhost:3456';


/**
 * 调用 AI 接口（自动判断：后端可用则调真实 AI，否则用模拟数据）
 * @param {'expansion'|'breakdown'|'parse'} type  - 调用类型
 * @param {object} payload - 请求参数
 * @returns {Promise<object>} AI 返回的结构化数据
 */
async function callAI(type, payload) {
  const endpoints = {
    expansion: '/api/v1/project/expand',
    breakdown: '/api/v1/project/breakdown',
    parse:      '/api/v1/project/parse',
  };

  // ─── 先探测后端是否可用 ───
  if (typeof callAI._backendReady === 'undefined') {
    try {
      const r = await fetch(`${API_BASE}/api/v1/health`, { signal: AbortSignal.timeout(3000) });
      callAI._backendReady = r.ok;
    } catch {
      callAI._backendReady = false;
    }
  }

  // ─── 后端未就绪：使用模拟数据 ───
  if (!callAI._backendReady) {
    console.warn('[PMO] 后端未启动，使用 Demo 模式（模拟数据）');

    // 防御：检查 mock-data.js 是否已加载
    if (typeof getMockResponse !== 'function') {
      console.error('[PMO] mock-data.js 未加载，无法使用 Demo 模式。请检查 <script> 加载顺序：mock-data.js 必须在 model-config.js 之前。');
      throw new Error('Demo 模式不可用：模拟数据模块未加载。请确保 mock-data.js 在 model-config.js 之前引入。');
    }

    const ms = 1200 + Math.random() * 1500;
    await new Promise(r => setTimeout(r, ms));
    return getMockResponse(type, payload);
  }

  // ─── 正式模式：调用后端 AI API ───
  const resp = await fetch(`${API_BASE}${endpoints[type]}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  const data = await resp.json();

  if (!resp.ok) throw new Error(data.error || `请求失败 (${resp.status})`);
  return data;
}


/**
 * 下载内容为 Word 文档（浏览器端，无需后端）
 * @param {string} htmlContent - HTML 格式的文档内容
 * @param {string} filename    - 文件名（不含扩展名）
 */
function downloadAsWord(htmlContent, filename) {
  const tpl = `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<title>${filename}</title>
<style>
  body { font-family:"PingFang SC","Microsoft YaHei","Segoe UI",sans-serif; line-height:1.8; padding:40px 60px; color:#1D1D1F; }
  h1 { font-size:24pt; font-weight:bold; margin-bottom:16pt; }
  h2 { font-size:16pt; font-weight:bold; margin-top:24pt; margin-bottom:10pt; border-bottom:1pt solid #E5E5EA; padding-bottom:6pt; }
  h3 { font-size:13pt; font-weight:bold; margin-top:16pt; margin-bottom:8pt; }
  ul,ol { padding-left:24pt; } li { margin-bottom:4pt; }
  table { border-collapse:collapse; width:100%; margin:10pt 0; }
  th,td { border:1pt solid #D2D2D7; padding:8pt 10pt; font-size:10.5pt; }
  th { background:#F5F5F7; font-weight:bold; }
  .meta-row { display:flex; gap:20pt; margin:8pt 0; font-size:11pt; color:#6E6E73; }
</style>
</head>
<body>${htmlContent}</body>
</html>`;

  const blob = new Blob(['\ufeff' + tpl], { type: 'application/msword' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href     = url;
  a.download = `${filename}.doc`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
