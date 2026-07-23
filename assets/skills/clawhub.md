---
name: clawhub
description: 技能市场（搜索与安装技能）
category: settings
platform: android
---

# 技能市场

## 能力
- 搜索技能
- 查看技能详情
- 安装技能

## 使用方式

### 搜索技能
使用 SkillHubService 从 GitHub 搜索：
```
# 搜索相关技能
skill_hub(query="文件管理")
```

### 安装技能
从 GitHub 仓库安装：
```
# 下载并安装技能
skill_hub(action="install", repo="owner/repo", path="skills/my_skill.md")
```

### 查看已安装
```
file_operation(action="list", path="assets/skills")
```

## 注意事项
- 技能来源：GitHub 仓库
- 安装后存储在本地
- 用户可编辑已安装的技能
