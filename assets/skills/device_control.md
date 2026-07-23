---
name: device_control
description: Android设备操控（Playwright模式）
category: device
platform: android
---

# 设备操控

## 能力
- 获取屏幕UI树（snapshot）
- 点击元素（tap）
- 输入文字（type）
- 滚动屏幕（scroll）
- 按系统按键（press）
- 打开应用（open）

## 工作流程

### 标准操作流程
1. **snapshot** — 获取当前屏幕UI树，查看有哪些元素
2. **定位目标** — 从UI树中找到目标元素的ref编号或text/resourceId
3. **执行操作** — 用tap/type/scroll操作目标元素
4. **验证结果** — 再次snapshot确认操作成功

### 操作示例

#### 打开微信发消息
```
1. device(action="open", package="com.tencent.mm")
2. 等待2秒
3. device(action="snapshot")  ← 查看界面
4. device(action="tap", text="搜索")  ← 点击搜索
5. device(action="type", text="张三")  ← 输入联系人
6. device(action="snapshot")  ← 查看搜索结果
7. device(action="tap", text="张三")  ← 点击联系人
8. device(action="type", text="明天见")  ← 输入消息
9. device(action="tap", text="发送")  ← 发送
```

#### 滚动浏览列表
```
1. device(action="snapshot")
2. device(action="scroll", direction="down")
3. device(action="snapshot")  ← 查看新内容
```

## 注意事项
- 每次操作后建议snapshot验证结果
- 元素可能需要滚动才能看到
- 某些应用可能有反自动化机制
- 操作间隔建议300-500ms，避免过快
