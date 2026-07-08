/**
 * ═══════════════════════════════════════════════════════════
 *  AI 模型配置中心 — PMO Dashboard v3.0
 * ═══════════════════════════════════════════════════════════
 *
 *  ┌────────────────────────────────────────────────────┐
 *  │  始终调用后端 API（真实 AI），不使用模拟数据       │
 *  │  后端部署在 Render：https://pmo-ai-api.onrender.com │
 *  │                                                    │
 *  │  更换模型：修改 Render 环境变量 AI_MODEL 即可       │
 *  │  v3.0 新增：SOP 文档生成接口                       │
 *  └────────────────────────────────────────────────────┘
 */

// ─── 后端 API 地址（Render 云端部署） ───
const API_BASE = 'https://pmo-ai-api.onrender.com';

// ─── 健康检查重试配置 ───
const HEALTH_CHECK_TIMEOUT = 15000;  // 单次超时 15 秒
const HEALTH_CHECK_RETRIES = 2;      // 最多重试 2 次（共 3 次）
const API_CALL_TIMEOUT = 120000;     // AI 调用超时 120 秒


/**
 * 健康检查：探测后端是否可用，支持重试
 * @returns {Promise<boolean>} true = 可用
 */
async function _checkHealth() {
    for (let attempt = 1; attempt <= HEALTH_CHECK_RETRIES + 1; attempt++) {
        try {
            const r = await fetch(`${API_BASE}/api/v1/health`, {
                signal: AbortSignal.timeout(HEALTH_CHECK_TIMEOUT)
            });
            if (r.ok) return true;
        } catch (e) {
            console.warn(`[PMO] 健康检查第 ${attempt} 次失败: ${e.message}`);
            if (attempt <= HEALTH_CHECK_RETRIES) {
                // 等待 2 秒后重试（Render 冷启动可能需要时间）
                await new Promise(r => setTimeout(r, 2000));
            }
        }
    }
    return false;
}


/**
 * 调用 AI 接口
 * @param {'expansion'|'breakdown'|'parse'|'sop'} type  - 调用类型
 * @param {object} payload - 请求参数
 * @returns {Promise<object>} AI 返回的结构化数据
 */
async function callAI(type, payload) {
    const endpoints = {
        expansion: '/api/v1/project/expand',
        breakdown: '/api/v1/project/breakdown',
        parse:      '/api/v1/project/parse',
        sop:        '/api/v1/project/sop',
    };

    const url = `${API_BASE}${endpoints[type]}`;

    // ─── 调用后端 AI API（带超时） ───
    try {
        const resp = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
            signal: AbortSignal.timeout(API_CALL_TIMEOUT),
        });

        const data = await resp.json();

        if (!resp.ok) {
            const errMsg = data.error || `请求失败 (${resp.status})`;
            // 针对常见错误给出友好提示
            if (resp.status === 429) {
                throw new Error('AI 服务请求过于频繁，请等待 30 秒后重试');
            }
            if (resp.status === 503) {
                throw new Error('AI 服务暂时不可用，Render 可能正在冷启动，请等待 30 秒后刷新页面重试');
            }
            throw new Error(errMsg);
        }
        return data;
    } catch (err) {
        // 区分网络错误和业务错误
        if (err.name === 'TimeoutError' || err.name === 'AbortError') {
            throw new Error('AI 请求超时，可能是 Render 服务正在冷启动，请等待 30 秒后刷新页面重试');
        }
        if (err.message.includes('Failed to fetch') || err.message.includes('NetworkError')) {
            throw new Error('无法连接到 AI 服务，请检查网络连接。如果 Render 服务已休眠，首次请求可能需要 30 秒唤醒');
        }
        throw err;
    }
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
