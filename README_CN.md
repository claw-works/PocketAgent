# PocketAgent 🐾💣

> 你的私人 AI Agent，直接操控你的设备。

[English](README.md)

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
- 🎯 **Skill 系统** — Markdown 知识库 + SOP 操作指南，AI 自主执行，可从 GitHub 安装
- 🧠 **自主学习** — AI 在使用过程中自动创建和更新 Skill，积累操作经验
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
| 自主学习 | ❌ | ✅ 自动积累操作经验 |
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

## Skill 系统

Skill 是 Markdown 格式的知识库和操作指南，AI 读取后自主执行：

```
~/.pocketagent/skills/
└── shopping_assistant/
    ├── skill.md              # 角色、策略、上下文
    ├── search_product.md     # SOP 1：搜索商品
    └── checkout.md           # SOP 2：结账
```

**skill.md** 定义 AI 的角色和策略，SOP 文件描述操作步骤和选择器参考。AI 根据当前平台自动选择合适的工具执行——桌面用 CDP 操控浏览器，Android 用 Accessibility 操控 App，未来可用截图+视觉识别。

Skill 与工具解耦：同一个 SOP 在不同平台用不同工具执行。

### 自主学习

AI 在使用过程中可以自动：
- **创建新 Skill** — 当用户反复执行类似操作时，AI 主动提炼为 Skill
- **更新现有 Skill** — 当 SOP 中的选择器失效或流程变化时，AI 自动修正
- **积累经验** — 将成功的操作模式保存为可复用的知识

## 数据存储

- **SQLite**（drift）— 聊天记录和操作日志
- **JSON 文件** — 配置（Agent 配置、LLM 配置）
- **文件系统** — Skill（Markdown 文件）

```
~/.pocketagent/           # 桌面端
  ├── data/
  │   ├── pocket_agent.db   # SQLite：聊天 + 操作日志
  │   ├── agent_config.json
  │   └── llm_config.json
  ├── skills/               # Markdown 技能
  └── chrome_profile/       # Chrome 持久化数据
```

移动端基础路径为 App 文档目录。

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
- [x] Markdown Skill 系统
- [x] SQLite 持久化（drift）
- [x] Agent 人设配置
- [x] Synthwave 主题 UI
- [ ] Skill 自主学习（自动创建/更新）
- [ ] 流式 TTS
- [ ] iOS Shortcuts 集成
- [ ] 本地模型支持（llama.cpp / MLC-LLM）
- [ ] Channel 接入（Feishu / Telegram）
- [ ] Vision（截图 → LLM 看图理解页面）
- [ ] 响应式布局（桌面三栏 / 平板双栏 / 手机 Tab）

## 灵感来源

一台吃灰的 iPad Pro M1 顶配 + 一个问题：

> 为什么 AI Agent 一定要跑在服务器上？

---

Built with 💣 by [claw-works](https://github.com/claw-works)
