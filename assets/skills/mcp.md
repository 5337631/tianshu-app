---
name: mcp
description: MCP Server（暴露能力给外部Agent）
category: development
platform: android
---

# MCP Server

## 能力
- 通过 HTTP 暴露工具给外部 Agent
- 兼容 Claude Desktop / Cursor
- 支持 JSON-RPC 协议

## 使用方式

### 启动 Server
```dart
final server = McpHttpServer();
await server.start(port: 8753);
```

### 暴露的工具
- `get_screen_info` — 获取屏幕 UI 树
- `tap_element` — 点击元素
- `type_text` — 输入文字
- `scroll_screen` — 滚动屏幕
- `press_key` — 按系统按键
- `take_screenshot` — 截图
- `launch_app` — 启动应用

### 连接方式
外部 Agent 通过 HTTP 连接到 `http://127.0.0.1:8753`

## 注意事项
- 默认监听 localhost
- 仅本机可访问（安全）
- 端口可在配置中修改
