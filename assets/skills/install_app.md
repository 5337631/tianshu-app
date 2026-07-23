---
name: install_app
description: 应用安装管理
category: device
platform: android
---

# 应用安装

## 能力
- 安装 APK 文件
- 检查应用是否已安装
- 启动已安装应用

## 使用方式

### 安装 APK
```
app_manager(action="install", apk_path="/sdcard/Download/app.apk")
```

### 检查应用
```
app_manager(action="list", query="应用名")
```

### 安装流程
1. 下载 APK 到 `/sdcard/Download/`
2. 执行 `app_manager(action="install", apk_path="...")`
3. 确认安装
4. 启动应用

## 注意事项
- 需要开启"安装未知来源"权限
- 系统会弹出安装确认框
- 建议从可信来源下载 APK
