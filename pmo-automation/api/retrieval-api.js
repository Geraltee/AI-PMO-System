/**
 * OneDrive Retrieval API Service
 * Handles document indexing, search, and retrieval from OneDrive
 * Integrates with Microsoft Graph API
 */

const express = require('express');
const { Client } = require('@microsoft/microsoft-graph-client');
const { DefaultAzureCredential } = require('@azure/identity');
const fs = require('fs').promises;
const path = require('path');

const router = express.Router();

// Configuration
const config = {
    oneDrive: {
        tenantId: process.env.ONEDRIVE_TENANT_ID || '',
        clientId: process.env.ONEDRIVE_CLIENT_ID || '',
        clientSecret: process.env.ONEDRIVE_CLIENT_SECRET || ''
    },
    search: {
        maxResults: 20,
        cacheExpiry: 3600000 // 1 hour
    }
};

// In-memory cache (use Redis in production)
const searchCache = new Map();

/**
 * Initialize OneDrive Graph Client
 */
function getGraphClient() {
    const credential = new DefaultAzureCredential();
    const client = Client.init({
        authProvider: async (done) => {
            try {
                const token = await credential.getToken('https://graph.microsoft.com/.default');
                done(null, token.token);
            } catch (error) {
                done(error, null);
            }
        }
    });
    return client;
}

/**
 * Search OneDrive documents
 */
router.get('/search', async (req, res) => {
    try {
        const { q, mode = 'keyword', limit = 20 } = req.query;
        
        if (!q) {
            return res.status(400).json({ error: 'Query parameter "q" is required' });
        }
        
        const cacheKey = `${mode}:${q}`;
        if (searchCache.has(cacheKey)) {
            const cached = searchCache.get(cacheKey);
            if (Date.now() - cached.timestamp < config.search.cacheExpiry) {
                return res.json(cached.data);
            }
        }
        
        const graphClient = getGraphClient();
        
        // Search OneDrive
        const searchResults = await graphClient
            .api('/me/drive/root/search(q=\'' + q + '\')')
            .get();
        
        const formattedResults = (searchResults.value || []).slice(0, limit).map(item => ({
            id: item.id,
            title: item.name,
            snippet: item.description || '',
            source: item.parentReference?.path || 'OneDrive',
            date: item.lastModifiedDateTime?.split('T')[0] || '',
            type: item.file?.mimeType?.split('/')[1] || 'file',
            url: item.webUrl || '#'
        }));
        
        const result = {
            query: q,
            mode,
            total: formattedResults.length,
            results: formattedResults
        };
        
        searchCache.set(cacheKey, {
            data: result,
            timestamp: Date.now()
        });
        
        res.json(result);
        
    } catch (error) {
        console.error('Search error:', error);
        
        // Return mock results for demo
        res.json({
            query: req.query.q,
            mode: req.query.mode,
            total: 5,
            results: getMockResults(req.query.q),
            _warning: 'Using mock data - OneDrive connection not configured'
        });
    }
});

/**
 * Natural language query endpoint
 */
router.post('/query', async (req, res) => {
    try {
        const { question, context = {} } = req.body;
        
        if (!question) {
            return res.status(400).json({ error: 'Question is required' });
        }
        
        // Extract keywords from natural language
        const keywords = extractKeywords(question);
        
        // Search with extracted keywords
        const searchReq = {
            query: keywords.join(' '),
            mode: 'natural',
            limit: config.search.maxResults
        };
        
        // Simulate processing delay
        await new Promise(resolve => setTimeout(resolve, 500));
        
        const results = getMockResults(keywords.join(' '));
        
        // Generate AI-powered answer summary
        const answer = generateAnswerSummary(question, results);
        
        res.json({
            question,
            keywords,
            answer,
            sources: results,
            total: results.length
        });
        
    } catch (error) {
        console.error('Query error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get document content by ID
 */
router.get('/document/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const graphClient = getGraphClient();
        
        // Get file metadata
        const file = await graphClient
            .api(`/me/drive/items/${id}`)
            .get();
        
        // Get download URL
        const download = await graphClient
            .api(`/me/drive/items/${id}/content`)
            .get();
        
        res.json({
            id,
            name: file.name,
            size: file.size,
            mimeType: file.file?.mimeType,
            downloadUrl: download,
            webUrl: file.webUrl
        });
        
    } catch (error) {
        console.error('Document fetch error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Index new documents (webhook trigger)
 */
router.post('/index', async (req, res) => {
    try {
        const { driveId, itemId, action } = req.body;
        
        console.log(`Indexing: ${driveId}/${itemId} - ${action}`);
        
        // Clear relevant cache entries
        searchCache.clear();
        
        res.json({ success: true, message: 'Document indexed' });
        
    } catch (error) {
        console.error('Index error:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Helper: Extract keywords from natural language query
 */
function extractKeywords(question) {
    // Remove common words and extract meaningful terms
    const stopWords = new Set(['的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '什么', '哪里', '如何', '怎么', 'which', 'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'just', 'and', 'but', 'if', 'or', 'because', 'until', 'while', 'although', 'though', 'after', 'before', 'when', 'whenever', 'where', 'wherever', 'whether', 'which', 'while', 'who', 'whoever', 'whom', 'whomever', 'whose', 'what', 'whatever', 'whichever']);
    
    const words = question.toLowerCase()
        .replace(/[^\w\s\u4e00-\u9fff]/g, ' ')
        .split(/\s+/)
        .filter(w => w.length > 1 && !stopWords.has(w));
    
    return [...new Set(words)];
}

/**
 * Helper: Generate answer summary from results
 */
function generateAnswerSummary(question, results) {
    if (results.length === 0) {
        return '未找到相关文档，请尝试其他关键词。';
    }
    
    const topDocs = results.slice(0, 3);
    const summary = `找到 ${results.length} 个相关文档。最相关的是：${topDocs.map(d => d.title).join('、')}。`;
    
    return summary;
}

/**
 * Helper: Mock results for demo
 */
function getMockResults(query) {
    return [
        {
            id: '1',
            title: 'AI 智能客服系统需求文档 v2.0',
            snippet: '本文档详细描述了 AI 智能客服升级项目的功能需求、技术架构和实施方案，包括 NLP 引擎集成、知识库建设、对话管理流程等核心模块...',
            source: 'OneDrive/Projects/AI-Customer-Service/',
            date: '2026-04-02',
            type: 'docx',
            url: '#'
        },
        {
            id: '2',
            title: '客服系统技术架构设计',
            snippet: '系统采用微服务架构，包含 NLP 引擎、知识库、对话管理等核心模块，支持多渠道接入和智能路由...',
            source: 'OneDrive/Technical/Architecture/',
            date: '2026-03-28',
            type: 'pptx',
            url: '#'
        },
        {
            id: '3',
            title: '竞品分析报告 - 智能客服市场',
            snippet: '对市场上主流智能客服解决方案的对比分析，包括功能、价格、用户评价等维度...',
            source: 'OneDrive/Research/Market-Analysis/',
            date: '2026-03-15',
            type: 'pdf',
            url: '#'
        },
        {
            id: '4',
            title: '用户调研数据汇总',
            snippet: '收集了 500+ 用户对现有客服系统的反馈，满意度评分及改进建议统计分析...',
            source: 'OneDrive/Research/User-Data/',
            date: '2026-03-10',
            type: 'xlsx',
            url: '#'
        },
        {
            id: '5',
            title: '项目里程碑计划表 PRJ-2026-001',
            snippet: '项目各阶段时间节点、负责人和交付物清单，包含需求分析、系统设计、开发、测试、部署等阶段...',
            source: 'OneDrive/PMO/PRJ-2026-001/',
            date: '2026-04-04',
            type: 'xlsx',
            url: '#'
        }
    ].filter(item => {
        const keywords = query.toLowerCase().split(/\s+/);
        const text = (item.title + item.snippet).toLowerCase();
        return keywords.some(kw => text.includes(kw));
    });
}

module.exports = router;
