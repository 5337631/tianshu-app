---
name: config
description: 配置管理（读写应用设置）
category: utility
platform: android
---

# 配置管理

## 能力
- 读取配置项
- 写入配置项
- 列出所有配置
- 重置配置

## 使用方式

### 读取配置
```
config(action="get", key="api_key_openai")
```

### 写入配置
```
config(action="set", key="theme", value="dark")
```

### 列出配置
```
config(action="list")
```

### 重置配置
```
config(action="reset", key="theme")
config(action="reset")  ← 重置所有
```

## 常用配置项
- `api_key_*` — API 密钥
- `custom_model_*` — 自定义模型设置
- `sync_*` — 同步设置
- `email_*` — 邮件配置

## 注意事项
- API Key 等敏感信息在 list 时显示为 ***
- 重置操作不可撤销
