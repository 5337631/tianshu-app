---
name: skill_creator
description: 技能创建与录制
category: development
platform: android
---

# 技能创建

## 能力
- 录制用户操作
- 自动生成 SKILL.md
- 从文本描述创建技能

## 使用方式

### 录制操作
1. 启动录制：`SkillRecorder.startRecording()`
2. 在手机上操作（点击、输入、滚动）
3. SkillRecorder 自动记录 UI 变化
4. 停止录制：`SkillRecorder.stopRecording()`
5. 自动生成 SKILL.md 文档

### 手动创建技能
在 `assets/skills/` 目录创建 Markdown 文件：
```markdown
---
name: my_skill
description: 我的自定义技能
category: custom
platform: android
---

# 技能标题

## 能力
- 能力1
- 能力2

## 使用方式
...
```

### 技能文件格式
- YAML frontmatter：name, description, category, platform
- Markdown 正文：能力说明、使用方式、注意事项
- 存储位置：`assets/skills/` (内置) 或 `/sdcard/天枢/skills/` (用户)

## 注意事项
- 录制时需要无障碍服务权限
- 自动生成的技能可能需要手动调整
- 用户技能优先级高于内置技能
