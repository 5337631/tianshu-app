---
name: sql_qa
description: SQL数据库问答
category: utility
platform: android
---

# SQL 数据库问答

## 能力
- 连接 SQLite 数据库
- 自然语言查询
- SQL 语法验证

## 使用方式

### 连接数据库
```
SqlChatService.connect("/sdcard/data/mydb.db")
```

### 自然语言查询
```
SqlChatService.ask("查询所有用户中年龄大于18的")
```

### SQL 语法验证
```
code(language="SQL", code="SELECT * FROM users WHERE age > 18")
```

## 注意事项
- 支持 SQLite 格式
- 自然语言会转换为 SQL 查询
- 建议先用语法验证确认查询正确
