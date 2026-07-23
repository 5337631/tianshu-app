---
name: background_thinking
description: 后台思考（Subconscious）
category: ai
platform: android
---

# 后台思考

## 能力
- 对话分析（提取用户习惯）
- 知识整理（去重、合并、关联）
- 索引优化

## 工作原理

### 对话分析（每日）
- 分析最近 7 天的对话
- 提取关键词频率
- 识别常用功能
- 识别活跃时间段
- 更新 user/preferences.md

### 知识整理（每周）
- 检查重复内容
- 合并相似文件
- 生成知识索引
- 优化搜索效率

### 索引优化（每次空闲）
- 重建文件缓存
- 更新索引文件

## 触发条件
- 空闲 10 分钟后自动执行
- 每日/每周调度
- 可手动触发：`SubconsciousService.runNow()`

## 注意事项
- 后台任务在空闲时执行
- 不影响前台使用
- 结果保存在 Memory Tree 中
