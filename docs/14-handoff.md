# 开发交接

开发目录D:/Project/RoleChat。首先阅读00-index、17-modular-architecture、16-final-architecture和04-data；FluffyChat与D:/agent-identity只读。本轮完成源码/测试目录规范化及文档全面核对，未改变业务文件格式和现有UI。

## 当前能力

Flutter Web聊天、角色、群聊、设置、头像裁剪、搜索/引用定位、API多模型配置与真实检测均已接入。角色初始化、OPFS文件恢复、ZIP冲突合并、归档及四项数据清理已实现。

Agent初始化后自动调度，周期检查和行程切换驱动；同角色串行、不同角色并行。原生工具发送公开纯文本，支持历史/记忆检索和文档自动更新。新消息刷新上下文但保留已执行过程；预算跨刷新累计，不按正文去重。

缺少initialized.json时按固定UUIDv5补建五个预设、私聊与社团群，保留已有同UUID内容；有标记不补回用户删除的数据。预设图片和适配文本来自assets/presets，无预设Key或假消息。

## 新代码入口

| 入口 | 位置 |
| --- | --- |
| 启动 | lib/main.dart |
| 应用Widget和状态装配 | lib/app/role_chat_app.dart、lib/app/app_store.dart |
| 页面/公共UI | lib/presentation |
| 通用激活 | lib/core/activation |
| 角色激活适配/默认策略 | lib/application/agents/activation |
| 执行和上下文 | lib/application/agents/execution |
| 工作区/模型端口 | lib/application/agents/ports |
| 工具声明/执行/文档 | lib/application/agents/tools |
| 接口检测端口 | lib/application/apis/ports |
| 业务数据与规则 | lib/domain/models、lib/domain/services、lib/domain/serialization |
| SDK/接口检测实现 | lib/infrastructure/ai |
| OPFS/提交/初始化 | lib/infrastructure/storage、lib/infrastructure/presets |
| ZIP/下载 | lib/infrastructure/transfer |
| 浏览器/日志实现 | lib/infrastructure/platform、lib/infrastructure/diagnostics |

旧PreviewStore、preview_models及旧目录路径均已替换，不保留兼容转发。内部导入统一package:rolechat；依赖边界测试防止应用层引用SDK、平台或UI实现。

## 验证与启动

在项目目录执行dart format lib test、flutter analyze、flutter test、flutter build web --release。生产产物build/web；node scripts/preview.mjs提供http://127.0.0.1:4173/。Windows后台预览进程应隐藏启动。

test按core/application/domain/infrastructure/app/presentation/architecture组织，fixtures只有假数据。目录重构后完整94项测试、静态分析和Web release构建通过；用例仍可自动发现。架构测试同时验证分层、规范URI、路径存在和生产源码可达性。浅深主题、窄宽屏、长消息和文件恢复有既有回归。

本轮未调用付费模型接口。此前浏览器已验证基本OPFS和界面；供应商工具协议、长期后台冻结、配额、ZIP实际上传下载须实机验收，不把mock或release构建等同全部平台验证。

F12 Console按RoleChat runtime筛选定期检查、概率、激活、模型请求、工具与失败日志。查看finishReason定位无工具响应；不会永久停用模型，60秒冷却后允许新检查。勿把真实Key或聊天正文加到日志。

## 维护重点

AppStore仍集中可变状态和通知；AgentWorkspace接口权限较宽；工具成功与持久化确认尚未形成统一事务；保存仍提交整工作区快照。后续优化这些问题时保持本轮目录依赖，不把逻辑放回弹窗或通用调度器。

docs纳入Git跟踪，不改.gitignore，交接以仓库文档为准。README仅用户简介及参考感谢，不加开发内容。分段写文件，明确路径暂存，Conventional Commits，仅在用户授权后push，不提交凭据或构建产物。
