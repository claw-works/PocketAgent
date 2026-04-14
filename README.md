# PocketAgent 🐾💣

> 一个跑在移动设备上的原生 AI Agent

把你的手机或平板变成一台永远在线的私人 AI 宿主机。

## 核心理念

**不需要服务器。不需要 Web Gateway。**

PocketAgent 直接运行在你的移动设备上，通过外部 Channel 服务器（Feishu、Telegram 等）收发消息，调用 LLM API 作为大脑，以设备原生能力作为"手脚"来完成任务。

```
Channel（Feishu / Telegram）
        ↓
  PocketAgent（Flutter App）
        ↓
  LLM API（Bedrock / OpenAI / LiteLLM）
        ↓
  设备原生工具 + Shortcuts
```

## 为什么是移动设备？

- 📱 随身携带，永远在线
- 🔋 接电源常驻，iPad Pro M1 算力完全够用
- 📷 相机、GPS、麦克风——这些是服务器没有的能力
- 🤖 Android 可接 Termux，获得真实 Linux 环境
- 🍎 iOS/iPad 可通过 Shortcuts 操控几乎任意 App

## 技术架构

### 核心模块

| 模块 | 说明 |
|------|------|
| Channel Connector | 连接 Feishu / Telegram 等消息平台 |
| LLM Engine | 调用 LLM API，处理 Tool Call 循环 |
| Tool Runtime | 执行原生工具，返回结果 |
| Skill System | 移动端专属技能体系 |
| Config Store | 密钥和配置，存储在设备 Keychain |

### 支持平台

- 🥇 **Android**（功能最完整，支持后台常驻、Termux 互操作）
- 🥈 **iOS / iPad**（核心功能支持，后台通过 Silent Push 保活）
- 🖥️ **macOS**（桌面版，后续考虑）

## 移动端原生工具（规划中）

### 通用（iOS + Android）
- 📷 拍照 / 读取照片库
- 📍 GPS 定位
- 📅 日历读写
- 📋 剪贴板读写
- 🔔 本地通知
- 🌐 打开网页 / URL Scheme
- 🎙️ 语音识别 / TTS

### Android 专属
- 🐧 Termux 互操作（真实 Linux shell）
- 📦 APK 直装，无需过审

### iOS / iPad 专属
- ⚡ Shortcuts（快捷指令）触发 — 间接控制任意 App
- 🔒 Keychain 安全存储

## 后台保活方案

### Android
- Foreground Service 常驻，WebSocket 不断线

### iOS
```
Channel Server 收到消息
        ↓
轻量中转服务发 APNs Silent Push
        ↓
App 被唤醒，重连 WebSocket，拉取消息
```

## 密钥管理

- 所有 API Key 由用户自己配置
- 存储在设备 Keychain（`flutter_secure_storage`）
- 不经过任何第三方服务器

## 技能体系

不移植 OpenClaw 现有技能，重新设计适合移动设备的技能：

- 移动端优先的交互方式
- 充分利用设备传感器和原生 API
- 轻量、快速、离线友好

## 开发路线图

- [ ] MVP：Flutter Android，接通 Feishu，调通 LLM，基础 Tool Call
- [ ] iOS / iPad 支持
- [ ] 移动端原生工具库
- [ ] Shortcuts 集成（iOS）
- [ ] Termux 互操作（Android）
- [ ] Silent Push 后台保活（iOS）
- [ ] 技能系统
- [ ] 多 Channel 支持（Telegram 等）

## 灵感来源

一台吃灰的 iPad Pro M1 顶配 + 一个想法：
> 为什么 AI Agent 一定要跑在服务器上？

---

Built with 💣 by [claw-works](https://github.com/claw-works)
