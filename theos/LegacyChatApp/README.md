# Legacy-Chatbox 0.1.0

Legacy-Chatbox is a small iOS 6 chat client built with Theos. The 0.1.0 release focuses on stable OpenAI-compatible chat on older devices rather than broad modern UIKit features.

## Supported Devices

- iPhone 4 / 4S, 3.5-inch portrait
- iPhone 5, 4-inch portrait
- iPad 4, portrait

## Main Features

- OpenAI-compatible provider configuration
- Editable system prompt
- Text chat with local conversation history
- Streamed assistant output when the provider supports it
- Temporary thinking display for reasoning responses, hidden when the final answer arrives
- Lightweight Markdown readability support
- Optional image input for providers that support multimodal chat messages

## Build

```sh
make
```

Install the generated package from `packages/` on a jailbroken iOS 6 device.

## Provider Setup

Open `Settings > Model Configurations` and add or edit a provider. `Base URL` should be the provider root, for example `https://api.deepseek.com`, while `Chat Path` should be the endpoint path, for example `/chat/completions`.

The bundled default provider does not include an API key. Enter your own key on device before sending messages.

## System Prompt

Open `Settings > System Prompt` to edit or clear the prompt sent before each request. The system prompt is inserted at request time and is not saved into conversation history.

## Known Limits

- Portrait is the supported orientation for this release.
- Markdown support is intentionally lightweight and is not a full Markdown renderer.
- Image input depends on provider support for OpenAI-compatible multimodal message payloads.
- Streaming quality depends on provider SSE behavior and old-device performance.
