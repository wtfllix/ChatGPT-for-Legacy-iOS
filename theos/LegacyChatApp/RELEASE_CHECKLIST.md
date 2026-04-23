# 0.1 RC 发布测试清单

请在每台目标设备上先删除旧版 app，再安装新版后执行这份清单。

## 目标设备

- iPhone 4 / 4S，iOS 6
- iPhone 5，iOS 6
- iPad 4，iOS 6

## 启动检查

- App 启动后没有顶部或底部黑边。
- 顶部导航正确显示 `Chats`、`Chat`、`Settings`。
- 竖屏布局能铺满设备屏幕，没有明显拉伸或兼容模式留白。

## Provider 配置

- 打开 `Settings > Model Configurations`。
- 新增一个 provider，填写 Base URL、Chat Path、Model 和 API Key。
- 保存后重新进入该 provider，确认所有字段都能正确回填。
- 切换当前 provider，确认聊天请求使用的是选中的配置。

## 聊天功能

- 新建聊天，确认不会自动插入第一条占位消息。
- 发送一条短文本消息，确认能收到回复。
- 发送一条较长 prompt，确认输出过程中聊天列表仍然可以滚动。
- 退出聊天后从 `Chats` 重新进入，确认完整历史消息仍然存在。

## Thinking 与 Markdown

- 使用支持 reasoning / thinking 的模型，或使用会返回 thinking 内容的 provider。
- 确认 thinking 输出有明显的独立样式提示。
- 确认最终答案出现后，thinking 内容会被替换或隐藏。
- 让模型输出标题、列表、粗体、代码和链接，确认显示结果仍然可读。

## 图片输入

- 从相册选择一张图片作为输入。
- 发送前确认底部能看到图片预览。
- 发送后确认本地用户消息保留图片缩略图。
- 如果 provider 支持图片输入，确认能收到正常 assistant 回复。

## 设备布局

- iPhone 4 / 4S：底部输入栏对齐正常，按钮和输入框都能稳定点击。
- iPhone 5：App 使用完整 4 寸高度，聊天区域自然利用更高屏幕。
- iPad 4：聊天页和设置页使用居中可读宽度，而不是内容横向铺满整屏。

## 阻塞发布的问题

- 启动即崩溃。
- Provider 配置无法保存或无法回填。
- 基本文本聊天无法发送。
- 会话历史丢失最终 assistant 输出。
- iPhone 5 或 iPad 4 以兼容模式启动，出现明显黑边。
