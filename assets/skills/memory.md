---
name: memory
description: 记忆系统（长期记忆存储与检索）
category: utility
platform: android
---

# 记忆系统

## 能力
- 搜索记忆（关键词+全文+标签混合搜索）
- 读取记忆文件
- 写入记忆文件
- 保存对话摘要

## 使用方式

### 搜索记忆
当用户要求回忆、查找之前的信息时：
```
memory_search(query="上次讨论的方案")
```

### 读取记忆
```
memory_get(path="user/preferences.md")
```

### 写入记忆
```
file_operation(action="write", path="memory/notes/重要决定.md", content="# 重要决定\n...")
```

### 保存对话
对话结束后自动保存到 `conversations/` 目录。

## 记忆目录结构
```
memory/
├── user/
│   ├── preferences.md    ← 用户偏好
│   └── goals.md          ← 目标与待办
├── conversations/        ← 对话记录
├── knowledge/            ← 知识库
├── sync/                 ← 同步数据
└── index.md              ← 索引
```

## 注意事项
- 记忆文件使用 Markdown 格式
- 支持中文关键词搜索（2-4字分词）
- 搜索结果按相关度排序
