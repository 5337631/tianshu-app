---
name: code_execution
description: 代码执行与调试
category: development
platform: android
---

# 代码执行

## 能力
- 执行 Shell 命令
- 执行 JavaScript 代码
- 执行 Python 代码（需 Termux）
- 语法验证

## 使用方式

### Shell 命令
使用 `execute_command` 工具：
```
execute_command(command="ls -la /sdcard")
execute_command(command="cat /proc/version")
execute_command(command="df -h")
```

### JavaScript
使用 `code` 工具，language="JavaScript"：
```
code(language="JavaScript", code='console.log("Hello!")')
code(language="JavaScript", code='const x = 1 + 2; console.log(x)')
```

### Python（需安装 Termux）
```
execute_command(command="python3 -c 'print(1+1)'")
```

## 支持的语言
- Shell（直接可用）
- JavaScript（内置求值器 + Node.js fallback）
- Python（需 Termux）
- Dart（需 Termux）
- SQL（语法验证）

## 注意事项
- Shell 命令有 30 秒超时
- 敏感命令（rm -rf）会触发安全检查
- 建议先用 echo 测试命令是否正确
