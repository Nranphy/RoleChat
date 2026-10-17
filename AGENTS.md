# RoleChat 开发约定

开始开发前阅读 docs/ 目录中的产品、UI、架构和设计决定；最新用户要求优先。当前开发Flutter Web；按docs/16-final-architecture.md实现OPFS、导入导出、归档、配置及角色调度和工具循环。

## Git

- docs/ 暂时不纳入 Git 跟踪，不修改 .gitignore 来忽略它。
- 使用明确路径暂存；禁止 git add . 或 git add -A 导致 docs/ 被提交。
- 提交前检查暂存文件，确保不包含 docs/、凭据和构建产物。
- 自主管理本地提交，使用 feat:、fix:、chore: 等 Conventional Commits，按可审查功能划分提交。不自动推送远端。

## README

README.md 面向用户，只包含仓库名称、简短简介和对 FluffyChat UI 参考的感谢。开发技术细节放在 docs/；不要频繁修改 README。

## 实现

组件化实现统一主题、配色、响应式布局和各页面。生产数据来自OPFS及首次预设初始化，示例聊天数据只留在test/fixtures；不增加演示入口。保持真实模型流程与错误提示，不能将mock验证当作实机验收。

FluffyChat 仓库保持只读，不复制其业务代码，不修改其文件。RoleChat 独立实现 UI。

D:/agent-identity是用户只读人设源目录，禁止修改。项目使用assets/presets内复制的图片及适配后的提示词。OPFS根目录initialized.json为初始化标记：不存在时按PresetIds的固定UUIDv5补建缺失的五个预设角色、私聊与社团群聊，并补入群中缺少的预设成员，成功提交后写标记；存在时不做预设检查。用户创建使用UUIDv4，不按名字合并。同UUID资料、消息和归档状态保留，群中其他成员保留。清除标记后刷新可重新补缺；正常删除不回填。数据损坏须报错，不以预设覆盖。

修改后执行 Dart 格式化、Flutter 分析、必要行为测试及 Web 构建；验收覆盖窄宽屏和浅深主题。

## UI 组件边界

维护 UI 前阅读 docs/12-ui-component-structure.md。公共展示组件放在 shared/widgets，功能专用组件放在 features 对应目录；展示组件通过数据和回调交互，不依赖 PreviewStore 或直接访问本地存储。页面与编辑弹窗负责协调操作。保留各组件现有 hover、尺寸与保存行为，避免结构重构混入样式或功能修改。

## 模块边界

维护业务前阅读docs/17-modular-architecture.md。runtime通过AgentWorkspace访问数据，不反向导入app或features。通用ActivationScheduler及ActivationPolicy不依赖Flutter、聊天模型、SDK和存储；RoleActivation只做快照适配，AgentRunner只负责模型与工具循环。界面草稿通过PreviewStore保存入口提交，跨实体引用更新交给ProfileActions，文件生命周期交给WorkspaceLifecycle。重构不得引入按正文过滤消息或重置上下文重启预算的旧逻辑。

## 数据格式

当前为初期开发，无正式旧数据，允许经当前需求授权的破坏性变更。业务数据采用OPFS独立JSON、Markdown和JSONL文件，不保留profiles旧格式迁移。自定义弹窗统一使用shared/widgets/AppDialog；系统日期时间和关于窗口保持Flutter标准组件。

## 最新设计与交接

先阅读docs/16-final-architecture.md、docs/14-handoff.md及docs/04-data.md。用户已于2026-10-17授权按最终方案实现。业务存储、ZIP、归档及角色调度/原生工具循环已接入；后续维护需验证真实浏览器文件恢复和模型协议，不能将mock测试等同于真实模型验收。docs不跟踪，交接需另行包含该目录。
