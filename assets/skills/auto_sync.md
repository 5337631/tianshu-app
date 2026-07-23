---
name: auto_sync
description: 自动同步（Telegram/Email）
category: ai
platform: android
---

# 自动同步

## 能力
- Telegram 消息同步
- Email 邮件同步
- 晨间简报生成

## 使用方式

### 启用同步
```
# 启用 Telegram 同步
config(action="set", key="sync_telegram_enabled", value="true")

# 启用 Email 同步
config(action="set", key="sync_email_enabled", value="true")
```

### 手动同步
```
AutoFetchService.syncNow("telegram")
AutoFetchService.syncNow("email")
```

### 晨间简报
```
AutoFetchService.generateMorningBriefing()
```

## 同步频率
- Telegram：每 5 分钟检查
- Email：每 60 分钟检查
- 同步间隔可配置

## 数据存储
- Telegram：`memory/sync/telegram-YYYY-MM-DD.md`
- Email：`memory/sync/email-YYYY-MM-DD.md`

## 注意事项
- 需要配置 Bot Token / IMAP 凭证
- 同步数据存储在本地 Memory Tree
- 支持离线查看已同步内容
