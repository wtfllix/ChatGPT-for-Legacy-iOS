# Legacy-Chatbox

Legacy-Chatbox is a lightweight AI chat client for legacy iOS devices. The current release focuses on iOS 6-era hardware, a Theos build pipeline, OpenAI-compatible providers, and a simple interface that feels at home on older UIKit.

## Status

`0.1.0` is the first release of the Theos-based app.

The original Xcode project remains in this repository for reference, but active release work lives in:

```sh
theos/LegacyChatApp
```

## Supported Devices

- iPhone 4 / 4S on iOS 6, portrait
- iPhone 5 on iOS 6, portrait
- iPad 4 on iOS 6, portrait

## Features

- OpenAI-compatible provider configuration
- Multiple saved provider/model profiles
- Optional editable system prompt
- Local conversation history
- Streamed assistant output when the provider supports SSE
- Temporary thinking/reasoning display with final-answer replacement
- Lightweight Markdown readability support
- Image input for providers that support multimodal OpenAI-compatible messages
- iOS 6-style navigation, buttons, launch images, and app icons

## Build

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

## Provider Setup

Open `Settings > Model Configurations` on device and add a provider:

- `Base URL` should be the provider root, for example `https://api.deepseek.com`.
- `Chat Path` should be only the endpoint path, for example `/chat/completions`.
- `Model` should be the exact provider model name.
- `API Key` is stored locally on device.

The bundled default provider does not include an API key.

## System Prompt

`Settings > System Prompt` lets users edit or clear the prompt sent before each request. The prompt is inserted into API requests at runtime and is not saved into conversation history.

Default prompt:

```text
You are a concise, helpful assistant in a legacy iOS chat app. Prefer clear, direct answers. Use simple Markdown only when it improves readability, and avoid complex tables or deeply nested formatting.
```

## Known Limits

- Portrait is the supported orientation for `0.1.0`.
- Markdown support is intentionally lightweight, not a full Markdown renderer.
- Image input depends on provider-side multimodal support.
- Streaming quality depends on provider SSE behavior and old-device performance.
- No cloud sync; provider profiles and conversations are local to the device.

## Release Testing

Use the checklist in:

```sh
theos/LegacyChatApp/RELEASE_CHECKLIST.md
```

## Repository

https://github.com/wtfllix/ChatGPT-for-Legacy-iOS
