/**
 * AI PMO Dashboard - Information Retrieval Module
 * Integrates with OneDrive for document search and retrieval
 * Supports keyword search and natural language queries
 */

class OneDriveRetrievalModule {
    constructor(config = {}) {
        this.config = {
            oneDriveTenant: config.oneDriveTenant || '',
            oneDriveClientId: config.oneDriveClientId || '',
            apiEndpoint: config.apiEndpoint || '/api/retrieval',
            maxResults: config.maxResults || 20,
            ...config
        };
        
        this.searchMode = 'keyword'; // 'keyword' or 'natural'
        this.isConnected = false;
        this.cache = new Map();
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.checkConnection();
        this.loadQuickLinks();
    }
    
    bindEvents() {
        const searchBtn = document.getElementById('retrieval-search-btn');
        const searchInput = document.getElementById('retrieval-search-input');
        const modeTabs = document.querySelectorAll('.mode-tab');
        
        if (searchBtn) {
            searchBtn.addEventListener('click', () => this.search());
        }
        
        if (searchInput) {
            searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.search();
            });
        }
        
        modeTabs.forEach(tab => {
            tab.addEventListener('click', (e) => {
                modeTabs.forEach(t => t.classList.remove('active'));
                e.target.classList.add('active');
                this.searchMode = e.target.dataset.mode;
            });
        });
    }
    
    async checkConnection() {
        const statusEl = document.getElementById('onedrive-status-indicator');
        const statusText = document.getElementById('onedrive-status-text');
        
        try {
            // Simulate connection check (replace with actual OneDrive API call)
            await this.simulateDelay(500);
            this.isConnected = true;
            
            if (statusEl) {
                statusEl.classList.remove('disconnected');
            }
            if (statusText) {
                statusText.textContent = 'OneDrive 已连接';
            }
        } catch (error) {
            this.isConnected = false;
            if (statusEl) {
                statusEl.classList.add('disconnected');
            }
            if (statusText) {
                statusText.textContent = 'OneDrive 未连接';
            }
        }
    }
    
    async search(query = null) {
        const input = document.getElementById('retrieval-search-input');
        const resultsArea = document.getElementById('retrieval-results');
        
        const searchTerm = query || input?.value?.trim();
        
        if (!searchTerm) {
            this.showPlaceholder('请输入搜索关键词或问题');
            return;
        }
        
        this.showLoading();
        
        try {
            // Check cache first
            const cacheKey = `${this.searchMode}:${searchTerm}`;
            if (this.cache.has(cacheKey)) {
                const cached = this.cache.get(cacheKey);
                this.displayResults(cached.results, searchTerm);
                return;
            }
            
            // Simulate API call (replace with actual OneDrive/academic search)
            await this.simulateDelay(1000);
            
            const results = await this.performSearch(searchTerm);
            
            // Cache results
            this.cache.set(cacheKey, {
                results,
                timestamp: Date.now()
            });
            
            this.displayResults(results, searchTerm);
            
        } catch (error) {
            console.error('Search error:', error);
            this.showError('搜索失败，请稍后重试');
        }
    }
    
    async performSearch(query) {
        // Mock results - replace with actual OneDrive Graph API calls
        const mockResults = [
            {
                id: '1',
                title: 'AI 智能客服系统需求文档 v2.0',
                snippet: '本文档详细描述了 AI 智能客服升级项目的功能需求、技术架构和实施方案...',
                source: 'OneDrive/Projects/AI-Customer-Service/',
                date: '2026-04-02',
                type: 'docx',
                url: '#'
            },
            {
                id: '2',
                title: '客服系统技术架构设计',
                snippet: '系统采用微服务架构，包含 NLP 引擎、知识库、对话管理等核心模块...',
                source: 'OneDrive/Technical/Architecture/',
                date: '2026-03-28',
                type: 'pptx',
                url: '#'
            },
            {
                id: '3',
                title: '竞品分析报告 - 智能客服市场',
                snippet: '对市场上主流智能客服解决方案的对比分析，包括功能、价格、用户评价等...',
                source: 'OneDrive/Research/Market-Analysis/',
                date: '2026-03-15',
                type: 'pdf',
                url: '#'
            },
            {
                id: '4',
                title: '用户调研数据汇总',
                snippet: '收集了 500+ 用户对现有客服系统的反馈，满意度评分及改进建议...',
                source: 'OneDrive/Research/User-Data/',
                date: '2026-03-10',
                type: 'xlsx',
                url: '#'
            },
            {
                id: '5',
                title: '项目里程碑计划表',
                snippet: 'PRJ-2026-001 项目各阶段时间节点、负责人和交付物清单...',
                source: 'OneDrive/PMO/PRJ-2026-001/',
                date: '2026-04-04',
                type: 'xlsx',
                url: '#'
            }
        ];
        
        // Filter based on query (simple keyword matching)
        const keywords = query.toLowerCase().split(/\s+/);
        const filtered = mockResults.filter(item => {
            const text = (item.title + item.snippet).toLowerCase();
            return keywords.some(kw => text.includes(kw));
        });
        
        return filtered.length > 0 ? filtered : mockResults.slice(0, 3);
    }
    
    displayResults(results, query) {
        const resultsArea = document.getElementById('retrieval-results');
        if (!resultsArea) return;
        
        resultsArea.innerHTML = `
            <div style="margin-bottom: 10px; font-size: 12px; color: rgba(255,255,255,0.7);">
                找到 ${results.length} 个相关文档 - 搜索："${query}"
            </div>
        `;
        
        results.forEach(result => {
            const itemEl = document.createElement('div');
            itemEl.className = 'result-item';
            itemEl.innerHTML = `
                <h4>${this.highlightMatch(result.title, query)}</h4>
                <p>${result.snippet}</p>
                <div class="result-meta">
                    <span class="result-source">${result.source}</span>
                    <span class="result-date">${result.date}</span>
                </div>
            `;
            
            itemEl.addEventListener('click', () => {
                window.open(result.url, '_blank');
            });
            
            resultsArea.appendChild(itemEl);
        });
    }
    
    highlightMatch(text, query) {
        const keywords = query.split(/\s+/).filter(k => k.length > 1);
        let highlighted = text;
        keywords.forEach(kw => {
            const regex = new RegExp(`(${kw})`, 'gi');
            highlighted = highlighted.replace(regex, '<mark style="background: rgba(255,255,0,0.3); color: white;">$1</mark>');
        });
        return highlighted;
    }
    
    showLoading() {
        const resultsArea = document.getElementById('retrieval-results');
        if (!resultsArea) return;
        
        resultsArea.innerHTML = `
            <div class="loading-spinner">
                <div class="spinner"></div>
                <span>正在搜索 OneDrive 文档...</span>
            </div>
        `;
    }
    
    showPlaceholder(message) {
        const resultsArea = document.getElementById('retrieval-results');
        if (!resultsArea) return;
        
        resultsArea.innerHTML = `
            <div class="results-placeholder">
                <p>${message}</p>
            </div>
        `;
    }
    
    showError(message) {
        const resultsArea = document.getElementById('retrieval-results');
        if (!resultsArea) return;
        
        resultsArea.innerHTML = `
            <div style="text-align: center; padding: 30px; color: #f87171;">
                ⚠️ ${message}
            </div>
        `;
    }
    
    loadQuickLinks() {
        const quickLinksEl = document.getElementById('retrieval-quick-links');
        if (!quickLinksEl) return;
        
        const quickLinks = [
            { label: '📄 需求文档', query: '需求 文档 requirement' },
            { label: '🏗️ 技术架构', query: '架构 设计 architecture' },
            { label: '📊 项目计划', query: '计划 里程碑 timeline' },
            { label: '📈 市场报告', query: '市场 竞品 analysis' }
        ];
        
        quickLinksEl.innerHTML = quickLinks.map(link => 
            `<a href="#" class="quick-link" data-query="${link.query}">${link.label}</a>`
        ).join('');
        
        quickLinksEl.querySelectorAll('.quick-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const input = document.getElementById('retrieval-search-input');
                if (input) {
                    input.value = e.target.dataset.query;
                    this.search(e.target.dataset.query);
                }
            });
        });
    }
    
    simulateDelay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.retrievalModule = new OneDriveRetrievalModule({
        oneDriveTenant: 'your-tenant-id',
        oneDriveClientId: 'your-client-id'
    });
});
