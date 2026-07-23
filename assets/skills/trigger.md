---
name: trigger
description: 场景触发与自动化
category: ai
platform: android
---

# 场景触发

## 能力
- 定时触发（每天固定时间）
- 位置触发（到达/离开某地）
- 触发动作：勿扰/闹钟/通知/启动APP/发消息/TTS/亮度

## 使用方式

### 创建定时规则
```
TriggerService.addRule(TriggerRule(
  id: "morning_alarm",
  name: "早安提醒",
  type: "time",
  time: "07:00",
  action: "播报天气和日程",
  actionType: "tts",
  actionParams: {"text": "早上好！新的一天开始了。"},
))
```

### 创建位置规则
```
TriggerService.addRule(TriggerRule(
  id: "work_arrive",
  name: "到公司提醒",
  type: "location",
  locationName: "公司",
  latitude: 39.9,
  longitude: 116.4,
  radius: 500,
  action: "发送工作消息",
  actionType: "notification",
))
```

### 支持的动作类型
- `dnd` — 勿扰模式
- `alarm` — 设置闹钟
- `notification` — 发送通知
- `launch_app` — 启动应用
- `send_message` — 发送消息
- `tts` — 语音播报
- `brightness` — 调节亮度

## 预设规则
- 22:00 — 睡前自动（勿扰）
- 07:00 — 晨间问候（TTS）
- 08:30 — 上班提醒（通知）
- 11:45 — 午餐推荐（通知）

## 注意事项
- 定时规则每分钟检查一次
- 同一天同一规则只触发一次
- 位置触发需要定位权限
