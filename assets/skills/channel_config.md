---
name: channel_config
description: 消息渠道配置（Telegram/Email）
category: settings
platform: android
---

# 渠道配置

## 能力
- 配置 Telegram Bot
- 配置 Email IMAP/SMTP
- 启用/禁用同步
- 手动触发同步

## Telegram 配置

### 设置 Bot Token
```
config(action="set", key="telegram_bot_token", value="your-bot-token")
```

### 启用同步
```
config(action="set", key="sync_telegram_enabled", value="true")
```

### 手动同步
通过 AutoFetchService 的 syncNow("telegram") 触发。

## Email 配置

### 设置 IMAP
```
config(action="set", key="email_imap_host", value="imap.gmail.com")
config(action="set", key="email_imap_port", value="993")
config(action="set", key="email_username", value="your-email@gmail.com")
config(action="set", key="email_password", value="your-password")
```

### 启用同步
```
config(action="set", key="sync_email_enabled", value="true")
```

## 注意事项
- Telegram Bot Token 从 @BotFather 获取
- Email 密码建议使用应用专用密码
- 同步数据存储在 memory/sync/ 目录
