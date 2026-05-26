/**
 * OneDrive 文档检索 API 服务
 * 支持文档链接存储、扫描、内容读取与智能检索
 * 基于谷歌学术/知网检索逻辑
 */

const fs = require('fs');
const path = require('path');

class OneDriveRetrievalService {
    constructor() {
        this.configPath = path.join(__dirname, 'onedrive-config.json');
        this.indexPath = path.join(__dirname, 'document-index.json');
        this.config = this.loadConfig();
        this.documentIndex = this.loadIndex();
    }

    /**
     * 加载配置
     */
    loadConfig() {
        try {
            if (fs.existsSync(this.configPath)) {
                return JSON.parse(fs.readFileSync(this.configPath, 'utf-8'));
            }
        } catch (error) {
            console.error('加载配置失败:', error);
        }
        return {
            oneDriveUrls: [],
            adminCredentials: null,
            lastSync: null,
            searchSettings: {
                includeSubfolders: true,
                searchContent: true,
                searchMetadata: false
            }
        };
    }

    /**
     * 加载文档索引
     */
    loadIndex() {
        try {
            if (fs.existsSync(this.indexPath)) {
                return JSON.parse(fs.readFileSync(this.indexPath, 'utf-8'));
            }
        } catch (error) {
            console.error('加载索引失败:', error);
        }
        return {
            documents: [],
            lastUpdated: null
        };
    }

    /**
     * 保存配置
     */
    saveConfig() {
        fs.writeFileSync(this.configPath, JSON.stringify(this.config, null, 2), 'utf-8');
    }

    /**
     * 保存索引
     */
    saveIndex() {
        this.documentIndex.lastUpdated = new Date().toISOString();
        fs.writeFileSync(this.indexPath, JSON.stringify(this.documentIndex, null, 2), 'utf-8');
    }

    /**
     * 添加 OneDrive 文档库 URL
     */
    addOneDriveUrl(url, name = '') {
        if (!this.config.oneDriveUrls.find(u => u.url === url)) {
            this.config.oneDriveUrls.push({
                url,
                name: name || url,
                addedAt: new Date().toISOString(),
                status: 'pending'
            });
            this.saveConfig();
            return true;
        }
        return false;
    }

    /**
     * 移除 OneDrive URL
     */
    removeOneDriveUrl(url) {
        const index = this.config.oneDriveUrls.findIndex(u => u.url === url);
        if (index !== -1) {
            this.config.oneDriveUrls.splice(index, 1);
            this.saveConfig();
            return true;
        }
        return false;
    }

    /**
     * 扫描 OneDrive 文档
     * 实际实现需要调用 Microsoft Graph API
     */
    async scanDocuments() {
        console.log('开始扫描 OneDrive 文档...');
        
        const allDocuments = [];

        for (const driveConfig of this.config.oneDriveUrls) {
            try {
                // TODO: 实际实现需要调用 Microsoft Graph API
                // GET https://graph.microsoft.com/v1.0/sites/{site-id}/drive/root/children
                console.log(`扫描: ${driveConfig.name}`);
                
                // 模拟扫描结果
                const mockDocs = this.generateMockDocuments(driveConfig.url);
                allDocuments.push(...mockDocs);
                
                driveConfig.status = 'success';
                driveConfig.lastScan = new Date().toISOString();
            } catch (error) {
                console.error(`扫描失败 ${driveConfig.url}:`, error);
                driveConfig.status = 'error';
            }
        }

        // 更新文档索引
        this.documentIndex.documents = allDocuments;
        this.documentIndex.lastUpdated = new Date().toISOString();
        this.saveIndex();
        this.saveConfig();

        return {
            total: allDocuments.length,
            success: allDocuments.length > 0,
            message: `扫描完成，共发现 ${allDocuments.length} 个文档`
        };
    }

    /**
     * 生成模拟文档（用于演示）
     */
    generateMockDocuments(baseUrl) {
        const fileTypes = ['docx', 'xlsx', 'pptx', 'pdf', 'doc', 'xls'];
        const mockDocs = [];
        
        for (let i = 0; i < 15; i++) {
            const type = fileTypes[Math.floor(Math.random() * fileTypes.length)];
            mockDocs.push({
                id: `doc-${Date.now()}-${i}`,
                title: `文档-${i + 1}.${type.toUpperCase()}`,
                url: `${baseUrl}/document-${i + 1}.${type}`,
                type: type,
                size: Math.floor(Math.random() * 10) * 1024 * 1024,
                createdDate: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
                modifiedDate: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
                path: `${baseUrl}/folder-${Math.floor(i / 3)}/document-${i + 1}.${type}`,
                content: this.generateMockContent(type),
                metadata: {
                    author: `用户${Math.floor(Math.random() * 5) + 1}`,
                    tags: ['项目文档', 'PMO', '报告'],
                    category: ['技术', '管理', '财务'][Math.floor(Math.random() * 3)]
                }
            });
        }

        return mockDocs;
    }

    /**
     * 生成模拟文档内容
     */
    generateMockContent(type) {
        const contents = {
            docx: '本文档包含项目需求分析、技术方案设计、实施计划等详细内容...',
            xlsx: '数据表格包含项目进度、资源分配、成本预算等关键指标...',
            pptx: '演示文稿展示项目里程碑、成果汇报、技术架构等内容...',
            pdf: 'PDF 文档包含正式报告、合同文件、规范标准等...',
            doc: 'Word 文档包含会议记录、需求说明、用户手册等...',
            xls: 'Excel 表格包含数据分析、财务报表、统计信息等...'
        };
        return contents[type] || '文档内容';
    }

    /**
     * 关键词搜索（类似谷歌学术/知网）
     */
    searchByKeyword(query, options = {}) {
        const {
            includeSubfolders = true,
            searchContent = true,
            searchMetadata = false,
            fileType = null,
            dateRange = null
        } = options;

        const queryTerms = query.toLowerCase().split(/\s+/).filter(t => t.length > 0);
        
        const results = this.documentIndex.documents.filter(doc => {
            // 文件类型过滤
            if (fileType && doc.type !== fileType) return false;
            
            // 日期范围过滤
            if (dateRange) {
                const docDate = new Date(doc.modifiedDate);
                if (dateRange.start && docDate < dateRange.start) return false;
                if (dateRange.end && docDate > dateRange.end) return false;
            }

            // 搜索匹配
            let score = 0;
            const searchText = [
                doc.title.toLowerCase(),
                searchContent ? doc.content.toLowerCase() : '',
                searchMetadata ? JSON.stringify(doc.metadata).toLowerCase() : ''
            ].join(' ');

            // 计算相关性得分
            queryTerms.forEach(term => {
                if (searchText.includes(term)) {
                    score += 1;
                    // 标题匹配权重更高
                    if (doc.title.toLowerCase().includes(term)) {
                        score += 2;
                    }
                }
            });

            return score > 0;
        }).map(doc => ({
            ...doc,
            relevanceScore: this.calculateRelevance(doc, queryTerms)
        })).sort((a, b) => b.relevanceScore - a.relevanceScore);

        return {
            query,
            total: results.length,
            results: results.slice(0, 50), // 限制返回数量
            searchTime: Date.now()
        };
    }

    /**
     * 自然语言提问（支持语义理解）
     */
    searchByNaturalLanguage(question) {
        // 提取问题中的关键词
        const keywords = this.extractKeywords(question);
        
        // 识别问题类型
        const questionType = this.identifyQuestionType(question);
        
        // 执行搜索
        const searchResults = this.searchByKeyword(keywords.join(' '));
        
        // 根据问题类型优化结果
        const optimizedResults = this.optimizeForQuestionType(searchResults.results, questionType);
        
        return {
            question,
            questionType,
            keywords,
            total: optimizedResults.length,
            results: optimizedResults.slice(0, 20),
            answer: this.generateAnswer(optimizedResults, questionType)
        };
    }

    /**
     * 提取关键词
     */
    extractKeywords(question) {
        // 简单的中文分词（实际应使用更复杂的 NLP 库）
        const stopWords = ['的', '了', '是', '在', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这'];
        
        return question
            .split(/[\s,，.。？?！!]+/)
            .filter(word => word.length > 1 && !stopWords.includes(word))
            .slice(0, 10);
    }

    /**
     * 识别问题类型
     */
    identifyQuestionType(question) {
        if (question.includes('什么') || question.includes('哪些')) return 'what';
        if (question.includes('怎么') || question.includes('如何')) return 'how';
        if (question.includes('为什么')) return 'why';
        if (question.includes('何时') || question.includes('什么时候')) return 'when';
        if (question.includes('谁') || question.includes('哪个')) return 'who';
        return 'general';
    }

    /**
     * 根据问题类型优化结果
     */
    optimizeForQuestionType(results, questionType) {
        // 根据不同问题类型调整排序策略
        if (questionType === 'what') {
            // 优先返回文档内容丰富的结果
            return results.sort((a, b) => b.content.length - a.content.length);
        } else if (questionType === 'how') {
            // 优先返回技术文档、方案类文档
            return results.filter(r => 
                r.title.includes('方案') || r.title.includes('技术') || r.type === 'pptx'
            ).concat(results.filter(r => 
                !r.title.includes('方案') && !r.title.includes('技术')
            ));
        }
        return results;
    }

    /**
     * 生成答案摘要
     */
    generateAnswer(results, questionType) {
        if (results.length === 0) {
            return '未找到相关文档，请尝试其他关键词或问题。';
        }

        const topDoc = results[0];
        let answer = `根据检索结果，找到 ${results.length} 个相关文档。\n\n`;
        answer += `最相关的文档是《${topDoc.title}》，\n`;
        answer += `主要内容：${topDoc.content.substring(0, 100)}...\n\n`;
        answer += `建议查看以下文档获取更多信息：\n`;
        
        results.slice(1, 4).forEach((doc, i) => {
            answer += `${i + 1}. 《${doc.title}》 (${doc.type.toUpperCase()})\n`;
        });

        return answer;
    }

    /**
     * 计算相关性得分
     */
    calculateRelevance(doc, queryTerms) {
        let score = 0;
        const titleLower = doc.title.toLowerCase();
        const contentLower = doc.content.toLowerCase();

        queryTerms.forEach(term => {
            // 标题完全匹配
            if (titleLower === term) score += 10;
            // 标题包含
            else if (titleLower.includes(term)) score += 5;
            // 内容包含
            else if (contentLower.includes(term)) score += 2;
            
            // 最近修改的文档权重更高
            const daysSinceModified = (Date.now() - new Date(doc.modifiedDate).getTime()) / (1000 * 60 * 60 * 24);
            if (daysSinceModified < 7) score += 3;
            else if (daysSinceModified < 30) score += 1;
        });

        return score;
    }

    /**
     * 读取文档内容
     */
    async readDocumentContent(documentId) {
        const doc = this.documentIndex.documents.find(d => d.id === documentId);
        if (!doc) {
            throw new Error('文档不存在');
        }

        // TODO: 实际实现需要调用 Microsoft Graph API 读取文档内容
        // GET https://graph.microsoft.com/v1.0/sites/{site-id}/drive/items/{item-id}/content
        
        return {
            id: doc.id,
            title: doc.title,
            content: doc.content,
            metadata: doc.metadata,
            url: doc.url
        };
    }

    /**
     * 获取统计信息
     */
    getStats() {
        const docs = this.documentIndex.documents;
        const typeCount = {};
        docs.forEach(doc => {
            typeCount[doc.type] = (typeCount[doc.type] || 0) + 1;
        });

        return {
            total: docs.length,
            byType: typeCount,
            lastUpdated: this.documentIndex.lastUpdated,
            configuredUrls: this.config.oneDriveUrls.length
        };
    }
}

// 导出服务实例
module.exports = new OneDriveRetrievalService();
