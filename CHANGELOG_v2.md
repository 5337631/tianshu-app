# 天枢 v2.0 更新日志
## 对齐 HermesApp 功能完整实现
**日期**: 2026-07-23

---

## 一、功能对齐总览

| 模块 | 原有 | 新增 | 状态 |
|------|------|------|------|
| 工具系统 | 25个 | 45个 | ✅ |
| 提供商 | 3个 | 7个 | ✅ |
| 消息渠道 | 1个 | 3个 | ✅ |
| 技能系统 | 31个内置 | +ClawHub+Recorder | ✅ |
| 设置页面 | 8个入口 | 18个入口 | ✅ |

---

## 二、新增文件清单

### 服务层 (10个)
| 文件 | 功能 |
|------|------|
| `lib/services/termux_service.dart` | Termux SSH 连接池，自动路由Shell |
| `lib/services/feishu_service.dart` | 飞书消息渠道，WebSocket连接 |
| `lib/services/discord_service.dart` | Discord消息渠道，Gateway v10 |
| `lib/services/clawhub_service.dart` | ClawHub技能市场，搜索/安装/更新/卸载 |
| `lib/services/skill_recorder_service.dart` | 操作录制，自动生成Skill |
| `lib/services/model_router.dart` | 模型智能路由，Fallback/轮换/黑白名单 |
| `lib/services/context_manager.dart` | 4层Context防护 |
| `lib/services/model_service.dart` | 动态获取模型列表 |
| `lib/screens/terminal_screen.dart` | 终端界面，Termux/Shell切换 |
| `lib/screens/effects_demo_screen.dart` | Uiverse特效演示 |

### 设置界面 (10个)
| 文件 | 功能 |
|------|------|
| `lib/screens/settings/prompt_template_screen.dart` | 提示词管理，5套预设模板 |
| `lib/screens/settings/display_settings_screen.dart` | 显示设置，全局选项 |
| `lib/screens/settings/emoji_settings_screen.dart` | 自定义表情管理 |
| `lib/screens/settings/context_summary_screen.dart` | 上下文总结配置 |
| `lib/screens/settings/external_api_screen.dart` | 外部HTTP聊天设置 |
| `lib/screens/settings/feature_config_screen.dart` | 功能模块开关 |
| `lib/screens/settings/gateway_screen.dart` | 飞书/Discord网关配置 |
| `lib/screens/settings/mnn_download_screen.dart` | MNN本地模型下载 |
| `lib/screens/settings/update_screen.dart` | 检查更新 |
| `lib/screens/settings/about_screen.dart` | 关于页面 |

### UI组件 (2个)
| 文件 | 功能 |
|------|------|
| `lib/widgets/uiverse_effects.dart` | 8种Uiverse特效组件 |
| `lib/screens/explore_screen_enhanced.dart` | 增强版探索页 |

---

## 三、修改文件清单

### 核心服务
| 文件 | 改动 |
|------|------|
| `lib/services/ai_service.dart` | +MiMo/DeepSeek/OpenRouter支持，+8个新工具 |
| `lib/services/agent_team_service.dart` | +8个新工具执行逻辑 |
| `lib/utils/tool_definitions.dart` | 工具从25个扩展到45个 |
| `lib/utils/method_channel_helper.dart` | +Playwright/相机/JS/配置通道 |
| `lib/main.dart` | +TermuxService初始化 |

### 界面文件
| 文件 | 改动 |
|------|------|
| `lib/screens/home_screen.dart` | +Uiverse特效落地 |
| `lib/screens/model_config_screen.dart` | 重写，支持动态模型列表 |
| `lib/screens/settings/main_settings_screen.dart` | 10个空占位全部填补 |

---

## 四、新增工具清单 (20个)

### Playwright模式
| 工具 | 说明 |
|------|------|
| `device` | 统一入口：snapshot/tap/type/scroll/press/open |

### Android专属
| 工具 | 说明 |
|------|------|
| `install_app` | 安装APK |
| `start_activity` | 启动Activity |
| `eye` | 摄像头拍照 |
| `log` | 查看系统日志 |

### 文件操作
| 工具 | 说明 |
|------|------|
| `edit_file` | 精确diff编辑 |
| `javascript` | 执行JS代码 |

### 记忆/配置
| 工具 | 说明 |
|------|------|
| `memory_get` | 精确读取记忆 |
| `config_get` | 读取配置项 |
| `config_set` | 写入配置项 |

### 技能管理
| 工具 | 说明 |
|------|------|
| `skills_search` | 搜索ClawHub技能 |
| `skills_install` | 安装技能 |
| `skills_update` | 更新技能 |
| `skills_uninstall` | 卸载技能 |

---

## 五、提供商支持

| 提供商 | API端点 | 状态 |
|--------|---------|------|
| OpenAI | api.openai.com | ✅ |
| Anthropic | api.anthropic.com | ✅ |
| Gemini | generativelanguage.googleapis.com | ✅ |
| **MiMo (小米)** | api.xiaomi.com | ✅ 新增 |
| **DeepSeek** | api.deepseek.com | ✅ 新增 |
| **OpenRouter** | openrouter.ai | ✅ 新增 |
| **自定义** | 用户自定义 | ✅ 新增 |

---

## 六、Uiverse特效组件

| 组件 | 效果 | 落地位置 |
|------|------|----------|
| `GradientGlowButton` | 渐变发光按钮 | 首页浮动按钮 |
| `GlassCard` | 毛玻璃卡片 | 首页独白/活动 |
| `LiquidGlassButton` | 液态玻璃按钮 | 首页快捷操作 |
| `GradientBorderCard` | 渐变边框 | 特效演示 |
| `NeonText` | 霓虹灯文字 | 特效演示 |
| `HoverCard` | 悬浮动画 | 特效演示 |
| `PulseDot` | 脉冲圆点 | 特效演示 |
| `ShimmerBorder` | 流光边框 | 首页预判卡片 |

---

## 七、设置页面完成状态

| 分类 | 功能 | 入口 |
|------|------|------|
| 账号 | GitHub账号 | ✅ |
| AI模型 | 模型配置 | ✅ |
| | 模型参数 | ✅ |
| | 提示词管理 | ✅ 新增 |
| | Token用量 | ✅ |
| 外观 | 主题设置 | ✅ |
| | 显示设置 | ✅ 新增 |
| | 自定义表情 | ✅ 新增 |
| | 特效演示 | ✅ 新增 |
| 语音 | 语音服务 | ✅ |
| 聊天 | 聊天历史 | ✅ |
| | 备份与恢复 | ✅ |
| | 上下文总结 | ✅ 新增 |
| | 外部HTTP聊天 | ✅ 新增 |
| 工具 | 工具权限 | ✅ |
| | 功能配置 | ✅ 新增 |
| | 终端 | ✅ 新增 |
| 系统 | Hermes网关 | ✅ 新增 |
| | MNN模型下载 | ✅ 新增 |
| | 检查更新 | ✅ 新增 |
| | 关于 | ✅ 新增 |

---

## 八、已知问题

1. `image_picker` 需要Android权限配置
2. ClawHub API需联网，离线不可用
3. Termux SSH需安装Termux应用
4. 飞书/Discord需各自申请开发者账号
5. 部分工具的Android原生层需配合实现

---

## 九、后续计划

1. 完善Android原生层（Playwright完整实现）
2. 飞书39个工具完整集成
3. Skill Recorder悬浮窗实际联动
4. 记忆图谱节点详情交互
5. 语音输入优化

---

**构建版本**: v2.0.0
**Flutter版本**: 3.29.3
**目标平台**: Android 8.0+
