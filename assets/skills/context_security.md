---
name: context_security
description: 上下文安全与隐私保护
category: utility
platform: android
---

# 上下文安全

## 能力
- API Key 安全存储（SecureStorage）
- 敏感信息过滤
- 对话历史清理
- 权限管理

## 安全机制

### API Key 存储
- 使用 FlutterSecureStorage（Android Keystore 加密）
- 不明文存储在 SharedPreferences
- 配置列表中显示为 ***

### 敏感信息过滤
- config(action="list") 自动隐藏 API Key
- 日志中不输出完整 Key
- 对话中避免询问密码等敏感信息

### 对话清理
- 使用 clear() 清除当前对话
- 清除时同步删除 SecureStorage 中的历史

## 注意事项
- 不要在对话中分享密码、密钥等
- 定期清理不需要的对话历史
- 使用 config(action="list") 检查已存储的配置
