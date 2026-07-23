---
name: data_processing
description: 数据处理与格式转换
category: development
platform: android
---

# 数据处理

## 能力
- JSON 解析与格式化
- CSV 处理
- 文本处理（提取、替换、统计）
- Base64 编解码

## 使用方式

### JSON 处理
```
code(language="JavaScript", code='
  const data = {"name": "天枢", "version": 1};
  console.log(JSON.stringify(data, null, 2));
')
```

### CSV 处理
```
file_operation(action="read", path="/sdcard/data.csv")
# 然后用代码处理
```

### 文本统计
```
execute_command(command="wc -l /sdcard/notes.txt")
execute_command(command="grep -c '关键词' /sdcard/file.txt")
```

### Base64
```
execute_command(command="echo 'Hello' | base64")
execute_command(command="echo 'SGVsbG8=' | base64 -d")
```

## 注意事项
- 大文件处理可能较慢
- 建议先用 head/tail 查看文件内容
