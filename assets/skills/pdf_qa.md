---
name: pdf_qa
description: PDF文档问答
category: utility
platform: android
---

# PDF 文档问答

## 能力
- 选取 PDF 文件
- 提取文本内容
- 基于文档内容问答

## 使用方式

### 上传 PDF
```
PdfChatService.pickAndExtract()
```

### 基于文档问答
```
PdfChatService.ask("这个文档的主要内容是什么？")
```

## 注意事项
- 支持文本 PDF（不支持扫描件）
- 文本提取使用字符过滤方式
- 扫描件需要 OCR 组件支持
