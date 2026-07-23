---
name: screenshot
description: 屏幕截图与OCR
category: device
platform: android
---

# 屏幕截图

## 能力
- 截取当前屏幕
- 保存截图到文件
- 配合设备操控使用

## 使用方式

### 截图
```
take_screenshot()
take_screenshot(save_path="/sdcard/Download/screenshot.png")
```

### 配合设备操控
```
1. take_screenshot()  ← 先截图查看
2. device(action="snapshot")  ← 获取UI树
3. device(action="tap", ref=5)  ← 操作
4. take_screenshot()  ← 验证结果
```

## 注意事项
- 需要屏幕录制权限
- 截图包含状态栏和导航栏
- 某些应用可能禁止截图（银行类）
