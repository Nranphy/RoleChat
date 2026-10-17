# 视觉参考与当前产品差异

早期以只读D:/Project/fluffychat源码为视觉参考，记录的参考提交为a0b9ed6f6。RoleChat独立实现，不复制Matrix账户、房间、加密、同步、通话和推送业务；原仓库保持只读。README保留参考感谢，应用界面不出现相关来源文案。

## 参考内容

参考过导航、会话列表、头像、消息组合、输入栏、菜单、主题和设置分区的组件组织及视觉参数。历史检索文件包括chat_list_view.dart、chat_list_body.dart、chat_input_row.dart、message.dart、avatar.dart、themes.dart及settings相关视图；它们属于外部参考仓库，不是本项目依赖。

## 当前实现落点

| 视觉职责 | RoleChat位置 |
| --- | --- |
| 主题与字段尺寸 | lib/presentation/theme |
| 导航与应用布局 | lib/app/layout |
| 会话与消息 | lib/presentation/features/chat |
| 头像、裁剪、统一菜单/弹窗 | lib/presentation/shared |
| 角色、群聊、设置 | lib/presentation/features对应目录 |

具体样式以当前AppTheme、FormMetrics及公共组件为准，用户后续要求优先于早期参考参数，不把历史审计中的尺寸当作当前强制值。

## 已确定的产品差异

无登录/Matrix账户、已读与免打扰。用户私聊/群聊对象为本地角色，资料包含身份、灵魂、记忆、样例和结构化行程；群资料另有background.md。导航仅聊天、角色、设置，无独立组件展览页。

角色卡不显示模型或简介，默认头像为首字配色；消息引用可跳转，菜单在气泡外按行hover显现。聊天顶部无hover背景；资料/设置内容面板、标签排列与编辑名称方式按用户要求统一。

这些是视觉参考后的独立设计，不承诺所有页面与参考项目像素一致。自动UI测试覆盖现有交互，人工验收依据02-ui与10-ui-preview；后续修改优先复用本项目组件，避免重新按笼统框架默认值实现。