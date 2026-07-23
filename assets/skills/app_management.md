---
name: app_management
description: 应用管理（列出/启动/停止/安装）
category: device
platform: android
---

# 应用管理

## 能力
- 列出已安装应用
- 启动应用
- 停止应用
- 获取应用信息
- 安装 APK

## 使用方式

### 列出应用
```
app_manager(action="list")
app_manager(action="list", query="微信")
```

### 启动应用
```
app_manager(action="launch", package="com.tencent.mm")
```

### 停止应用
```
app_manager(action="stop", package="com.tencent.mm")
```

### 获取应用信息
```
app_manager(action="info", package="com.tencent.mm")
```

### 安装 APK
```
app_manager(action="install", apk_path="/sdcard/Download/app.apk")
```

## 常用包名
- 微信：com.tencent.mm
- QQ：com.tencent.mobileqq
- 支付宝：com.eg.android.AlipayGphone
- 淘宝：com.taobao.taobao
- 抖音：com.ss.android.ugc.aweme
- 高德地图：com.autonavi.minimap
- 设置：com.android.settings

## 注意事项
- 安装 APK 需要"安装未知来源"权限
- 强制停止可能影响应用数据
