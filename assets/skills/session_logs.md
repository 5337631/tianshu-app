---
name: session_logs
description: 会话日志管理
category: utility
platform: android
---

# 会话日志

## 能力
- 查看历史对话
- 导出对话记录
- 搜索对话内容

## 使用方式

### 查看历史
对话历史保存在 SecureStorage 中，重启 app 后自动加载。

### 导出对话
```
file_operation(action="read", path="conversations/2026-07-13")
```

### 搜索对话
使用记忆搜索功能：
```
memory_search(query="上次讨论的代码")
```

## 注意事项
- 最近 100 条对话自动保存
- 对话按日期存储在 conversations/ 目录
- 敏感对话建议手动删除
