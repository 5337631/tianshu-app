---
name: debugging
description: 调试与日志查看
category: development
platform: android
---

# 调试工具

## 能力
- 查看系统日志 (logcat)
- 按标签/级别过滤
- 查看应用崩溃信息
- 监控后台活动

## 使用方式

### 查看日志
```
log(filter="tianshu", count=50)
log(level="e", count=20)  ← 只看错误
log(filter="crash")  ← 查看崩溃
```

### 日志级别
- v (verbose) — 详细
- d (debug) — 调试
- i (info) — 信息
- w (warn) — 警告
- e (error) — 错误

### 调试流程
1. `log(filter="tianshu", level="e")` — 查看错误日志
2. `log(filter="exception")` — 查看异常
3. `execute_command(command="logcat -d | grep -i error")` — 高级过滤

## 注意事项
- 日志量大时建议用 filter 缩小范围
- 某些日志需要 root 权限
- 崩溃日志通常在 error 级别
