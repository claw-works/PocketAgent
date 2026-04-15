# PocketAgent 🐾💣

> 你的私人 AI Agent，直接操控你的设备。

跨平台 AI Agent 应用——手机、桌面、任何设备。LLM 直接驱动本机能力，不依赖云端中转。

```
你说话
  ↓
PocketAgent（Flutter App）
  ↓
LLM（Bedrock / OpenAI / Anthropic / Gemini）
  ↓
Tool Call 循环（最多 20 轮）
  ↓
直接操控本机 / 浏览器 / 其他 App
```

## 核心特性

- 🔄 **多轮 Agent 循环** — LLM 自主调用工具、观察结果、继续执行，直到任务完成
- 🌊 **流式输出** — 四个 Provider 全部支持 Streaming，逐字显示
- 🔧 **12+ 本机工具** — 相机、GPS、日历、剪贴板、通知、语音、Shell、浏览器操控...
- 🎯 **Skill 系统** — 预定义 SOP 自动化，精准 CSS 选择器操作，可从 GitHub 安装
- 🌐 **浏览器操控** — Chrome DevTools Protocol，导航/点击/填表/截图/执行 JS
- 📱 **屏幕操控** — Android Accessibility Service，跨 App UI 自动化
- 🎨 **Synthwave 主题** — 霓虹暗色 UI，Material 3

## 和 Siri / Gemini 的区别

| | Siri / Gemini | PocketAgent |
|--|--|--|
| LLM | 厂商锁定 | 自己配，随时换 |
| 数据隐私 | 上传厂商服务器 | 完全本地，自己掌控 |
| 工具扩展 | 封闭 | 开放，自己写 Skill |
| 多轮执行 | 单轮 | 最多 20 轮自主 Agent 循环 |
| 浏览器操控 | ❌ | ✅ CDP 完整操控 |
| 跨平台 | 单平台 | Android / iOS / macOS / Windows |

## LLM 支持

四个 Provider，全部支持 Streaming + Tool Call：

| Provider | 协议 | 默认模型 |
|----------|------|---------|
| **OpenAI** | SSE | gpt-4o-mini |
| **Anthropic** | SSE | claude-sonnet-4-20250514 |
| **Bedrock** | AWS Event Stream 二进制协议 | anthropic.claude-sonnet-4-20250514-v1:0 |
| **Gemini** | SSE | gemini-2.0-flash |

Base URL 可自定义，兼容 LiteLLM、GLM、任何 OpenAI 兼容 API。

## 工具矩阵

| 工具 | macOS | Windows | Android | iOS |
|------|-------|---------|---------|-----|
| 📋 剪贴板 | ✅ | ✅ | ✅ | ✅ |
| 📷 相机 | stub | stub | ✅ | stub |
| 📍 GPS | stub | stub | ✅ | stub |
| 📅 日历 | stub | stub | ✅ | stub |
| 🔔 通知 | stub | stub | ✅ | stub |
| 🎙️ 语音 | stub | stub | ✅ | stub |
| 🌐 打开 URL/App | ✅ `open` | ✅ `start` | ✅ Intent | stub |
| 💻 Shell | ✅ bash + AppleScript | ✅ cmd + PowerShell | ✅ Termux | ❌ |
| 🌐 浏览器 (CDP) | ✅ | ✅ | ❌ | ❌ |
| 📱 屏幕操控 | AppleScript | ❌ | ✅ Accessibility | ❌ |
| 🎯 Skill 自动化 | ✅ | ✅ | ✅ | ✅ |
| ⚡ iOS 快捷指令 | ❌ | ❌ | ❌ | stub |

## Skill 系统

预定义浏览器 SOP 自动化，用 JSON 描述步骤：

```json
{
  "name": "google_search",
  "description": "在 Google 搜索关键词",
  "params": [{"name": "query", "required": true}],
  "steps": [
    {"action": "navigate", "url": "https://www.google.com"},
    {"action": "wait", "seconds": 1},
    {"action": "type_text", "selector": "textarea[name=q]", "text": "{{query}}"},
    {"action": "press_key", "key": "Enter"},
    {"action": "wait", "seconds": 2},
    {"action": "query_all", "selector": "h3", "save_as": "results", "limit": 5},
    {"action": "return", "value": "{{results}}"}
  ]
}
```

Skills 存储在 `~/.pocketagent/skills/`，支持从 GitHub 安装：

```
~/.pocketagent/
├── chrome_profile/     # Chrome 持久化数据（Cookie、登录态）
└── skills/
    ├── google_search/
    │   └── skill.json
    └── login_admin/
        └── skill.json
```

### Skill Step Actions

`navigate` `wait` `query` `query_all` `query_text` `click` `click_text` `type_text` `press_key` `get_text` `execute_js` `save` `return`

## 架构

```
lib/
├── main.dart
├── app.dart
├── models/
│   └── message.dart
├── services/
│   ├── llm_service.dart              # 统一调度 + Agent 循环
│   ├── llm_config_store.dart         # 每 Provider 独立配置
│   ├── agent_config.dart             # Agent 人设/语音/语言
│   ├── chat_store.dart               # 对话持久化
│   ├── activity_log.dart             # 工具执行日志
│   ├── tool_registry.dart            # 工具注册 + 开关
│   ├── cdp_client.dart               # Chrome DevTools Protocol
│   ├── providers/
│   │   ├── llm_provider.dart         # 抽象接口
│   │   ├── openai_provider.dart      # SSE Streaming
│   │   ├── anthropic_provider.dart   # SSE Streaming
│   │   ├── bedrock_provider.dart     # AWS Event Stream
│   │   └── gemini_provider.dart      # SSE Streaming
│   ├── aws/
│   │   ├── crc32.dart                # CRC32 校验
│   │   └── event_stream_decoder.dart # AWS 二进制协议解码
│   ├── skill/
│   │   ├── skill_model.dart          # Skill 定义
│   │   ├── skill_runner.dart         # 步骤执行引擎
│   │   └── skill_registry.dart       # 加载/安装/管理
│   └── platform/
│       ├── termux_bridge.dart        # Android Termux
│       ├── android_intent_bridge.dart
│       └── accessibility_bridge.dart # Android 屏幕操控
├── tools/
│   ├── base_tool.dart                # Tool 抽象基类
│   ├── clipboard_tool.dart
│   ├── camera_tool.dart
│   ├── gps_tool.dart
│   ├── calendar_tool.dart
│   ├── notification_tool.dart
│   ├── app_launcher_tool.dart
│   ├── speech_tool.dart
│   ├── device_info_tool.dart
│   ├── termux_tool.dart              # Android
│   ├── screen_control_tool.dart      # Android Accessibility
│   ├── shortcuts_tool.dart           # iOS
│   ├── macos_tool.dart               # macOS
│   ├── windows_tool.dart             # Windows
│   ├── browser_tool.dart             # CDP
│   └── skill_tool.dart               # Skill 执行
└── ui/                               # Synthwave 主题 UI
```

## 快速开始

```bash
git clone https://github.com/claw-works/PocketAgent.git
cd PocketAgent
flutter create . --org com.clawworks --project-name pocket_agent
flutter run -d macos    # 或 -d windows / -d chrome / 连接手机
```

打开设置 → 模型配置 → 选择 Provider → 填入 API Key → 开始聊天。

## 开发路线图

- [x] Chat UI + Streaming
- [x] 4 个 LLM Provider（OpenAI / Anthropic / Bedrock / Gemini）
- [x] Tool Call Agent 循环（最多 20 轮）
- [x] 12+ 本机工具
- [x] Android 互操作（Termux + Intent + Accessibility）
- [x] macOS 互操作（Shell + AppleScript）
- [x] Windows 互操作（cmd + PowerShell）
- [x] 浏览器操控（Chrome DevTools Protocol）
- [x] Skill 系统（预定义 SOP + GitHub 安装）
- [x] 对话持久化 + 操作日志
- [x] Agent 人设配置
- [x] Synthwave 主题 UI
- [ ] 流式 TTS（边输出边朗读）
- [ ] iOS Shortcuts 集成
- [ ] 本地模型支持（llama.cpp / MLC-LLM）
- [ ] Channel 接入（Feishu / Telegram）
- [ ] Vision（截图 → LLM 看图理解页面）

## 灵感来源

一台吃灰的 iPad Pro M1 顶配 + 一个问题：

> 为什么 AI Agent 一定要跑在服务器上？

---

Built with 💣 by [claw-works](https://github.com/claw-works)
