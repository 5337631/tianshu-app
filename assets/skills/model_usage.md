---
name: model_usage
description: 模型使用统计
category: settings
platform: android
---

# 模型使用统计

## 能力
- 查看 API 调用次数
- Token 使用量统计
- 错误率监控

## 使用方式

### 查看配置
```
config(action="list")
```

### 查看最近错误
通过日志查看：
```
log(filter="ChatProvider", count=50)
log(filter="API", level="e")
```

## 注意事项
- Token 统计需要各 Provider API 支持
- 部分 Provider 不返回 usage 数据
- 可通过 config 检查各 Provider 配置状态
