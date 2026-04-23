# Legacy-Chatbox

[中文](#中文) | [English](#english)

## 中文

Legacy-Chatbox 是一个面向旧 iOS 设备的轻量 AI 聊天客户端。当前版本以 iOS 6 时代设备、Theos 打包流程、OpenAI-compatible provider 和接近老 UIKit 的简洁界面为重点。

### 状态

`0.1.0` 是第一个基于 Theos 的正式发布版本。

原始 Xcode 工程仍保留在仓库中作为参考，当前活跃发布版本位于：

```sh
theos/LegacyChatApp
```

### 支持设备

- iPhone 4 / 4S，iOS 6，竖屏
- iPhone 5，iOS 6，竖屏
- iPad 4，iOS 6，竖屏

### 功能

- OpenAI-compatible provider 配置
- 多个 provider / model 配置保存与切换
- 可编辑的 system prompt
- 本地会话历史
- provider 支持 SSE 时的流式输出
- reasoning / thinking 临时显示，并在最终答案出现后隐藏或替换
- 轻量 Markdown 可读性增强
- 支持 multimodal OpenAI-compatible 消息的 provider 可使用图片输入
- iOS 6 风格导航栏、按钮、启动图和图标

### 构建

安装 Theos 后，在 app 目录中构建：

```sh
cd theos/LegacyChatApp
make package FINALPACKAGE=1
```

生成的 `.deb` 位于：

```sh
theos/LegacyChatApp/packages/
```

请将 `.deb` 安装到已越狱的 iOS 6 设备上。

### Provider 配置

在设备上打开 `Settings > Model Configurations` 并添加 provider：

- `Base URL` 应填写服务根地址，例如 `https://api.deepseek.com`。
- `Chat Path` 只填写接口路径，例如 `/chat/completions`。
- `Model` 填写 provider 对应的准确模型名。
- `API Key` 只保存在本机设备上。

默认 provider 不包含 API key。

### System Prompt

`Settings > System Prompt` 可以编辑或清空每次请求前发送的 system prompt。它只会在请求时临时插入，不会保存进会话历史。

默认 prompt：

```text
You are a concise, helpful assistant in a legacy iOS chat app. Prefer clear, direct answers. Use simple Markdown only when it improves readability, and avoid complex tables or deeply nested formatting.
```

### 已知限制

- `0.1.0` 仅支持竖屏。
- Markdown 是轻量可读性增强，不是完整 Markdown 渲染器。
- 图片输入取决于 provider 是否支持 multimodal。
- 流式输出体验取决于 provider 的 SSE 兼容性和旧设备性能。
- 没有云同步；provider 配置和会话历史只保存在本机。

### 发布测试

测试清单位于：

```sh
theos/LegacyChatApp/RELEASE_CHECKLIST.md
```

### 仓库

https://github.com/wtfllix/ChatGPT-for-Legacy-iOS

## English

Legacy-Chatbox is a lightweight AI chat client for legacy iOS devices. The current release focuses on iOS 6-era hardware, a Theos build pipeline, OpenAI-compatible providers, and a simple interface that feels at home on older UIKit.

### Status

`0.1.0` is the first release of the Theos-based app.

The original Xcode project remains in this repository for reference, but active release work lives in:

```sh
theos/LegacyChatApp
```

### Supported Devices

- iPhone 4 / 4S on iOS 6, portrait
- iPhone 5 on iOS 6, portrait
- iPad 4 on iOS 6, portrait

### Features

- OpenAI-compatible provider configuration
- Multiple saved provider/model profiles
- Optional editable system prompt
- Local conversation history
- Streamed assistant output when the provider supports SSE
- Temporary thinking/reasoning display with final-answer replacement
- Lightweight Markdown readability support
- Image input for providers that support multimodal OpenAI-compatible messages
- iOS 6-style navigation, buttons, launch images, and app icons

### Build

Install Theos, then build from the app directory:

```sh
cd theos/LegacyChatApp
make package FINALPACKAGE=1
```

The generated `.deb` will be placed in:

```sh
theos/LegacyChatApp/packages/
```

Install the package on a jailbroken iOS 6 device.

### Provider Setup

Open `Settings > Model Configurations` on device and add a provider:

- `Base URL` should be the provider root, for example `https://api.deepseek.com`.
- `Chat Path` should be only the endpoint path, for example `/chat/completions`.
- `Model` should be the exact provider model name.
- `API Key` is stored locally on device.

The bundled default provider does not include an API key.

### System Prompt

`Settings > System Prompt` lets users edit or clear the prompt sent before each request. The prompt is inserted into API requests at runtime and is not saved into conversation history.

Default prompt:

```text
You are a concise, helpful assistant in a legacy iOS chat app. Prefer clear, direct answers. Use simple Markdown only when it improves readability, and avoid complex tables or deeply nested formatting.
```

### Known Limits

- Portrait is the supported orientation for `0.1.0`.
- Markdown support is intentionally lightweight, not a full Markdown renderer.
- Image input depends on provider-side multimodal support.
- Streaming quality depends on provider SSE behavior and old-device performance.
- No cloud sync; provider profiles and conversations are local to the device.

### Release Testing

Use the checklist in:

```sh
theos/LegacyChatApp/RELEASE_CHECKLIST.md
```

### Repository

https://github.com/wtfllix/ChatGPT-for-Legacy-iOS
