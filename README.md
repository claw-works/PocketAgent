# PocketAgent 🐾💣

> 手机上的私人 AI，直接操控你的手机。

把你的 Android 手机或 iPad 变成一台真正的 AI Agent 宿主机——不依赖云端服务器，不经过任何中转，LLM 直接驱动设备本身的能力。

## 核心理念

**本机对话，本机执行。**

打开 App，跟 AI 说话，AI 直接操控这台设备完成任务。相机、日历、GPS、快捷指令——这些都是 Agent 的手脚。

```
你说话
  ↓
PocketAgent（Flutter App）
  ↓
LLM（Bedrock / OpenAI / LiteLLM / 本地模型）
  ↓
直接操控本机
```

## 和 Siri / Gemini 的区别

| | Siri / Gemini | PocketAgent |
|--|--|--|
| LLM | 厂商锁定 | 自己配，随时换 |
| 数据隐私 | 上传厂商服务器 | 完全本地，自己掌控 |
| 工具扩展 | 封闭，不能自定义 | 开放，自己写技能 |
| 远程接入 | ❌ | ✅ 可选（Feishu / Telegram）|

## 本机工具（规划中）

### 通用（iOS + Android）
- 📷 拍照 / 读取照片库 / 图像分析
- 📍 GPS 定位
- 📅 日历 / 提醒事项读写
- 📋 剪贴板读写
- 🔔 本地通知
- 🌐 打开网页 / 唤起其他 App
- 🎙️ 语音识别 / TTS 朗读

### Android 专属
- 🐧 Termux 互操作 — 真实 Linux shell，执行脚本
- 📦 APK 直装，无需 App Store 审核

### iOS / iPad 专属
- ⚡ Shortcuts（快捷指令）触发 — 间接操控任意 App
- 🔒 Keychain 安全存储密钥

## 可选：远程 Channel 接入

不在手边时，可以通过外部消息平台远程控制：

```
Feishu / Telegram
       ↓
  PocketAgent
       ↓
  操控设备
```

这是补充能力，不是核心依赖。

## 密钥管理

- 所有 API Key 由用户自己配置，存储在设备 Keychain
- 不经过任何第三方服务器

## 支持平台

- 🥇 **Android**（后台 Foreground Service 常驻，功能最完整）
- 🥈 **iOS / iPad**（核心功能完整，后台通过 Silent Push 保活）
- 🖥️ **macOS**（后续考虑）

## 开发路线图

- [ ] MVP：Flutter Android，Chat UI，接通 LLM，基础 Tool Call
- [ ] 本机工具库（相机、日历、GPS、剪贴板）
- [ ] iOS / iPad 支持
- [ ] Shortcuts 集成（iOS）
- [ ] Termux 互操作（Android）
- [ ] 技能系统
- [ ] 可选 Channel 接入（Feishu / Telegram）
- [ ] 本地模型支持

## 灵感来源

一台吃灰的 iPad Pro M1 顶配 + 一个问题：

> 为什么 AI Agent 一定要跑在服务器上？

---

Built with 💣 by [claw-works](https://github.com/claw-works)
