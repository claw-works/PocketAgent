# PocketAgent 🐾💣

> Your private AI agent — controls your device directly.

[中文文档](README_CN.md)

Cross-platform AI Agent app — phone, desktop, any device. LLM drives native capabilities directly, no cloud relay.

```
You speak
  ↓
PocketAgent (Flutter App)
  ↓
LLM (Bedrock / OpenAI / Anthropic / Gemini)
  ↓
Tool Call loop (up to 20 rounds)
  ↓
Controls your device / browser / other apps
```

## Key Features

- 🔄 **Multi-round Agent loop** — LLM autonomously calls tools, observes results, continues until task is done
- 🌊 **Streaming output** — All 4 providers support real streaming, token by token
- 🔧 **12+ native tools** — Camera, GPS, calendar, clipboard, notifications, speech, shell, browser control...
- 🎯 **Skill system** — Markdown-based knowledge + SOPs, AI-driven execution, install from GitHub
- 🌐 **Browser control** — Chrome DevTools Protocol: navigate, click, fill forms, screenshot, execute JS
- 📱 **Screen control** — Android Accessibility Service for cross-app UI automation
- 🎨 **Synthwave theme** — Neon dark UI, Material 3

## How It Differs from Siri / Gemini

| | Siri / Gemini | PocketAgent |
|--|--|--|
| LLM | Vendor locked | Your choice, switch anytime |
| Privacy | Uploaded to vendor servers | Fully local, you control |
| Tool extension | Closed | Open, write your own Skills |
| Multi-round | Single turn | Up to 20 autonomous Agent rounds |
| Browser control | ❌ | ✅ Full CDP control |
| Cross-platform | Single platform | Android / iOS / macOS / Windows |

## LLM Providers

All 4 support streaming + tool calling:

| Provider | Protocol | Default Model |
|----------|----------|---------------|
| **OpenAI** | SSE | gpt-4o-mini |
| **Anthropic** | SSE | claude-sonnet-4-20250514 |
| **Bedrock** | AWS Event Stream binary | anthropic.claude-sonnet-4-20250514-v1:0 |
| **Gemini** | SSE | gemini-2.0-flash |

Base URL is configurable — works with LiteLLM, GLM, any OpenAI-compatible API.

## Tool Matrix

| Tool | macOS | Windows | Android | iOS |
|------|-------|---------|---------|-----|
| 📋 Clipboard | ✅ | ✅ | ✅ | ✅ |
| 📷 Camera | stub | stub | ✅ | stub |
| 📍 GPS | stub | stub | ✅ | stub |
| 📅 Calendar | stub | stub | ✅ | stub |
| 🔔 Notifications | stub | stub | ✅ | stub |
| 🎙️ Speech | stub | stub | ✅ | stub |
| 🌐 Open URL/App | ✅ `open` | ✅ `start` | ✅ Intent | stub |
| 💻 Shell | ✅ bash + AppleScript | ✅ cmd + PowerShell | ✅ Termux | ❌ |
| 🌐 Browser (CDP) | ✅ | ✅ | ❌ | ❌ |
| 📱 Screen control | AppleScript | ❌ | ✅ Accessibility | ❌ |
| 🎯 Skill automation | ✅ | ✅ | ✅ | ✅ |
| ⚡ iOS Shortcuts | ❌ | ❌ | ❌ | stub |

## Skill System

Skills are markdown files that give the AI knowledge and operational guides:

```
~/.pocketagent/skills/
└── shopping_assistant/
    ├── skill.md              # Role, strategy, context
    ├── search_product.md     # SOP 1
    └── checkout.md           # SOP 2
```

**skill.md** defines the AI's role and strategy. SOP files describe step-by-step operation guides with selector references. The AI reads these and executes using available tools — browser CDP, shell, screen control, or whatever fits the platform.

Skills are tool-agnostic: the same SOP works whether the AI uses Chrome CDP on desktop, Accessibility Service on Android, or future screenshot+vision.

Install skills from URL:
```
AI → skill(install_url, url: "https://example.com/my_skill.md")
```

Or drop markdown files into `~/.pocketagent/skills/your_skill/`.

## Data Storage

- **SQLite** (via drift) for chat history and activity log
- **JSON files** for configuration (agent config, LLM config)
- **Filesystem** for skills (markdown files)

```
~/.pocketagent/           # Desktop
  ├── data/
  │   ├── pocket_agent.db   # SQLite: chats + activity
  │   ├── agent_config.json
  │   └── llm_config.json
  ├── skills/               # Markdown skills
  └── chrome_profile/       # Persistent Chrome data
```

On mobile, base path is the app's documents directory.

## Architecture

```
lib/
├── main.dart
├── app.dart
├── models/
│   └── message.dart
├── services/
│   ├── llm_service.dart              # Dispatcher + Agent loop
│   ├── llm_config_store.dart         # Per-provider config
│   ├── agent_config.dart             # Agent persona + skill injection
│   ├── chat_store.dart               # SQLite chat persistence
│   ├── activity_log.dart             # SQLite activity log
│   ├── tool_registry.dart            # Tool registration + toggle
│   ├── cdp_client.dart               # Chrome DevTools Protocol
│   ├── pa_paths.dart                 # Cross-platform path management
│   ├── db/
│   │   └── database.dart             # Drift SQLite schema
│   ├── providers/
│   │   ├── llm_provider.dart         # Abstract interface
│   │   ├── openai_provider.dart      # SSE streaming
│   │   ├── anthropic_provider.dart   # SSE streaming
│   │   ├── bedrock_provider.dart     # AWS Event Stream
│   │   └── gemini_provider.dart      # SSE streaming
│   ├── aws/
│   │   ├── crc32.dart                # CRC32 checksum
│   │   └── event_stream_decoder.dart # AWS binary protocol
│   ├── skill/
│   │   └── skill_registry.dart       # Load/install/manage skills
│   └── platform/
│       ├── termux_bridge.dart
│       ├── android_intent_bridge.dart
│       └── accessibility_bridge.dart
├── tools/                            # 12+ tools
│   ├── base_tool.dart
│   ├── browser_tool.dart             # CDP
│   ├── macos_tool.dart
│   ├── windows_tool.dart
│   ├── termux_tool.dart
│   ├── screen_control_tool.dart
│   ├── skill_tool.dart
│   └── ...
└── ui/                               # Synthwave theme
```

## Quick Start

```bash
git clone https://github.com/claw-works/PocketAgent.git
cd PocketAgent
flutter create . --org com.clawworks --project-name pocket_agent
flutter run -d macos    # or -d windows / -d chrome / connect phone
```

Open Settings → Model Config → Select provider → Enter API Key → Start chatting.

## Roadmap

- [x] Chat UI + Streaming
- [x] 4 LLM Providers (OpenAI / Anthropic / Bedrock / Gemini)
- [x] Tool Call Agent loop (up to 20 rounds)
- [x] 12+ native tools
- [x] Android interop (Termux + Intent + Accessibility)
- [x] macOS interop (Shell + AppleScript)
- [x] Windows interop (cmd + PowerShell)
- [x] Browser control (Chrome DevTools Protocol)
- [x] Markdown Skill system
- [x] SQLite persistence (drift)
- [x] Agent persona config
- [x] Synthwave theme UI
- [ ] Streaming TTS
- [ ] iOS Shortcuts integration
- [ ] Local model support (llama.cpp / MLC-LLM)
- [ ] Channel integration (Feishu / Telegram)
- [ ] Vision (screenshot → LLM image understanding)
- [ ] Responsive layout (desktop 3-column / tablet 2-column / mobile tabs)

## Inspiration

An idle iPad Pro M1 top spec + one question:

> Why must AI Agents run on servers?

---

Built with 💣 by [claw-works](https://github.com/claw-works)
