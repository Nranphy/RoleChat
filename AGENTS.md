# RoleChat 开发约定

开始开发前阅读 docs/ 目录中的产品、UI、架构和设计决定；最新用户要求优先。当前只开发 Flutter Web 的 UI 与展示交互，仅接口及模型检测可调用配置的外部 API；聊天与角色调度仍不接入模型。

## Git

- docs/ 暂时不纳入 Git 跟踪，不修改 .gitignore 来忽略它。
- 使用明确路径暂存；禁止 git add . 或 git add -A 导致 docs/ 被提交。
- 提交前检查暂存文件，确保不包含 docs/、凭据和构建产物。
- 自主管理本地提交，使用 feat:、fix:、chore: 等 Conventional Commits，按可审查功能划分提交。不自动推送远端。

## README

README.md 面向用户，只包含仓库名称、简短简介和对 FluffyChat UI 参考的感谢。开发技术细节放在 docs/；不要频繁修改 README。

## 实现

组件化实现统一主题、配色、响应式布局和各页面。使用本地展示数据，提供可操作的 UI 预览入口，覆盖正常、空、错误与加载状态。演示行为明确标注，不假装已经连接模型。

FluffyChat 仓库保持只读，不复制其业务代码，不修改其文件。RoleChat 独立实现 UI。

修改后执行 Dart 格式化、Flutter 分析、必要行为测试及 Web 构建；验收覆盖窄宽屏和浅深主题。

## UI 组件边界

维护 UI 前阅读 docs/12-ui-component-structure.md。公共展示组件放在 shared/widgets，功能专用组件放在 features 对应目录；展示组件通过数据和回调交互，不依赖 PreviewStore 或直接访问本地存储。页面与编辑弹窗负责协调操作。保留各组件现有 hover、尺寸与保存行为，避免结构重构混入样式或功能修改。

## 数据格式

当前为初期开发，无正式旧数据，允许经当前需求授权的破坏性变更。资料使用profiles，仅结构化行程；不添加早期预览格式迁移。API配置和聊天记录仍为运行时内存数据。自定义弹窗统一使用shared/widgets/AppDialog；系统日期时间和关于窗口保持Flutter标准组件。

## 最新设计与交接

先阅读docs/14-handoff.md及docs/04-data.md。已确认后续采用浏览器OPFS，config.json存通用/API配置，角色与群聊独立目录存profile.json、Markdown和messages.jsonl；提供导入导出，角色/群聊自动UUID且前端不可见。用户当前明确要求暂不实现这些功能，仅同步文档，须等待恢复开发指示。现有localStorage/内存实现不代表目标方案已落地。docs不跟踪，交接需另行包含该目录。
