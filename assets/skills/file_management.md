---
name: file_management
description: 文件读写与管理
category: utility
platform: android
---

# 文件管理

## 能力
- 读取文件内容
- 写入/创建文件
- 精确编辑文件（diff模式）
- 列出目录
- 搜索文件
- 删除文件

## 使用方式

### 读取文件
```
file_operation(action="read", path="/sdcard/Download/notes.txt")
```

### 写入文件
```
file_operation(action="write", path="/sdcard/Download/todo.txt", content="1. 买菜\n2. 写代码")
```

### 精确编辑
```
edit_file(path="/sdcard/config.json", action="replace", old_text='"debug": false', new_text='"debug": true')
edit_file(path="/sdcard/config.json", action="append", new_text="new_setting: value")
```

### 列出目录
```
file_operation(action="list", path="/sdcard/Download")
```

### 搜索文件
```
file_operation(action="search", path="/sdcard", pattern="*.pdf")
```

## 常用路径
- `/sdcard/Download/` — 下载目录
- `/sdcard/Documents/` — 文档目录
- `/sdcard/DCIM/` — 相册
- `/sdcard/Android/data/` — 应用数据

## 注意事项
- 需要存储权限
- 系统文件需要 root 权限
- 编辑前建议先 read 备份
