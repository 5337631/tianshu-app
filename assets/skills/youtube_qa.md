---
name: youtube_qa
description: YouTube视频问答
category: utility
platform: android
---

# YouTube 视频问答

## 能力
- 提取 YouTube 视频转录
- 基于转录内容问答
- 视频内容摘要

## 使用方式

### 提取转录
```
YoutubeChatService.getTranscript("https://youtube.com/watch?v=xxx")
```

### 基于转录问答
```
YoutubeChatService.ask(transcript, "这个视频的主要观点是什么？")
```

## 注意事项
- 需要视频有公开字幕
- 转录可能不完整
- 支持中英文字幕
