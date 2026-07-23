---
name: tts
description: 语音播报（文字转语音）
category: utility
platform: android
---

# 语音播报

## 能力
- 将文字转换为语音
- 支持中英文
- 可调节语速

## 使用方式

### 播报文字
```
tts(text="你好，我是天枢")
tts(text="今天天气晴朗，温度25度", language="zh", rate=1.0)
```

### 场景示例
- 早安播报：天气+日程+新闻
- 任务提醒：语音通知
- 无障碍朗读：朗读屏幕内容

## 注意事项
- 使用 Android TTS 引擎
- 需要安装 TTS 数据包（中文/英文）
- 语速范围 0.1~2.0
