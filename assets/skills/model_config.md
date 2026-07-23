---
name: model_config
description: 模型配置与切换
category: settings
platform: android
---

# 模型配置

## 能力
- 配置多个模型 Provider
- 自定义 API 端点
- 模型故障转移
- API Key 轮换

## 使用方式

### 查看当前配置
```
config(action="list")
```

### 配置 API Key
```
config(action="set", key="api_key_openai", value="sk-xxx")
config(action="set", key="api_key_deepseek", value="sk-xxx")
```

### 配置自定义模型
```
config(action="set", key="custom_model_endpoint", value="https://api.example.com/v1/chat/completions")
config(action="set", key="custom_model_api_key", value="your-key")
config(action="set", key="custom_model_name", value="your-model")
```

### 配置端点
```
config(action="set", key="endpoint_deepseek", value="https://api.deepseek.com/v1/chat/completions")
```

## 支持的 Provider
- OpenAI (gpt-4.1-mini)
- DeepSeek (deepseek-chat)
- Claude (claude-3-5-sonnet)
- 通义千问 (qwen-plus)
- 智谱 (glm-4-flash)
- Moonshot (moonshot-v1-8k)
- 小米 MiMo (MiMo-V2-Pro)
- 自定义 OpenAI 兼容 API

## 注意事项
- 自定义模型优先级最高
- 建议配置至少两个 Provider 做 fallback
- API Key 保存在 SecureStorage 中
