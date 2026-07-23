---
name: email
description: Gmail邮件问答
category: utility
platform: android
---

# Gmail 邮件问答

## 能力
- 读取邮件列表
- 基于邮件内容问答
- 邮件摘要

## 使用方式

### 读取邮件
```
GmailChatService.getMessages()
```

### 基于邮件问答
```
GmailChatService.ask("最近有什么重要邮件？")
```

## 注意事项
- 需要配置 Gmail API 或 IMAP
- 当前使用模拟数据（需接入真实 API）
- 支持多邮箱账户
