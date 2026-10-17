# UI组件目录与边界

所有界面位于lib/presentation，应用装配/布局位于lib/app。业务层模型无Flutter依赖，SDK和存储实现不进入普通展示组件。

## 功能目录

| 目录 | 主要职责 |
| --- | --- |
| presentation/features/chat | 会话列表、聊天协调、消息列表/气泡、输入和搜索 |
| presentation/features/agents | 角色列表与资料弹窗；editing保存行程草稿，widgets负责各Tab和字段 |
| presentation/features/groups | 群资料弹窗、基础/背景/成员展示 |
| presentation/features/settings | 设置、API编辑、模型参数表单、清理入口 |
| presentation/features/data | 归档及ZIP导入导出交互 |
| presentation/controllers | ApiCheckController处理请求状态和过期结果 |
| presentation/shared | 图片选择及可复用widgets |
| presentation/theme | AppTheme和FormMetrics |
| app/layout | AppShell与RoleNavigationRail |

## 公共展示层

- ContentPage：角色、设置内容宽度、外框和边距。
- AppDialog：自定义弹窗统一外壳；系统选择器/关于页保留标准组件。
- ProfileDialogFrame、ProfileDialogTab：资料Tab、滚动与保存操作。
- ProfileIdentityHeader、ProfileName、AvatarField、RoleAvatar：资料头、名称编辑与头像。
- AnchoredSelect、FieldAction：字段锚定菜单及轮廓内hover。
- EditorSectionNote、EditorEmptyState、EditableEntryCard：样例、行程说明、空态及卡片。
- DocumentEditorTab：identity.md、soul.md、memory.md及background.md编辑。
- SettingsSection、SettingsRow、SectionCard、CheckResultNote：设置与结果提示。

展示组件通过值、控制器和回调交互，不读取AppStore、不调度、不直接保存OPFS。页面持有草稿、控制器和校验；提交走AppStore，再由domain/services/ProfileActions维护引用及保存顺序。

## 聊天组件

ChatView协调发送、引用和定位，ChatTimeline处理长列表、初始底部和目标滚动；搜索结果、气泡引用、输入区引用共用同一定位入口。消息ID稳定，删除后引用快照保留并提示无法定位。

MessageBubble处理连续关系、文字自适应和行hover；MessageReferencePreview统一发送者色与内容。ConversationTile整行单层选中/hover，子标题无独立点击层。不得重新引入IntrinsicHeight导致长气泡裁切。

## 头像与编辑

RoleAvatar仅imageData内容变化时更换MemoryImage，名称/主题/尺寸重建复用图片；gaplessPlayback保留上一帧。有图透明背景，无图才显示首字配色，损坏图像用错误图标。

角色Tab为基础、样例、身份、灵魂、记忆、行程；群为基础、背景、成员。已有资料名称提交即时保存；其余草稿按保存按钮提交。图片裁剪取消不替换原图。

## 检测与文件交互

页面只依赖application/apis/ports/ApiChecker，生产实现由AppStore装配；ApiCheckController使修改后的旧响应失效，关闭后不更新UI。页面不导入AI实现或SDK。

导入导出弹窗使用专门的infrastructure/transfer适配做ZIP/下载交互；普通卡片和表单不承担文件协议。样式验收与行为清单见02-ui、10-ui-preview，测试位于test/presentation。