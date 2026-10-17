# 应用架构

当前代码按职责分层，详细文件树和扩展入口见17-modular-architecture.md；应用已接入OPFS、导入导出及Agent模型工具循环。

## 目录与职责

| 目录 | 职责 |
| --- | --- |
| lib/app | AppStore、RoleChatApp、导航布局及适配器装配 |
| lib/presentation | 功能页面、公共展示组件、检测状态控制器和主题 |
| lib/application | Agent协调、执行、上下文、工具、应用端口与角色激活适配 |
| lib/domain | 纯业务模型、资料/消息/行程规则和行程JSON校验 |
| lib/core | 与聊天/SDK无关的通用激活队列、策略接口和日志回调 |
| lib/infrastructure | SDK、接口探测、OPFS、预设资源、ZIP、浏览器及日志实现 |

main.dart负责环境初始化、许可证加载、打开文件系统和启动；RoleChatApp独立为应用Widget。AppStore处于装配边界，实例化SDK和浏览器适配后注入应用层。应用流程依赖端口，不直接创建平台客户端。

## 依赖方向

core仅依赖Dart/core，domain依赖domain/core，application依赖application/domain/core。infrastructure可以实现应用端口，不能导入app或presentation。presentation通过AppStore操作状态，模型探测只使用ApiChecker端口，不导入SDK或AI实现。

导入导出弹窗当前会调用专门的ZIP/下载适配，属于用户文件交互边界；没有把存储或网络协议放入普通展示组件。AppStore仍集中可观察状态，不宣称所有状态均已按功能隔离。

## Agent运行链路

AppStore → AgentRuntime → RoleActivation快照 → ActivationScheduler/ActivationPolicy → ActivationRequest → AgentRunner → AgentGateway及工具。

激活队列只认识ID、时刻、概率与统计；RoleplayActivationPolicy是应用层默认策略。角色同一时刻最多处理一个会话，不同角色可并行，ModelRequestGate另行约束API/模型并发。

AgentExecution跨上下文代次保存已执行assistant/tool过程和累计请求预算；旧HTTP不强行取消，旧未提交结果失效。文件更新检查哈希与用户锁。日志通过回调提供，生产日志由infrastructure/diagnostics输出到Console。

## 数据链路

页面草稿 → AppStore保存入口 → ProfileActions关联更新 → WorkspaceRepository编码排队 → WorkspaceStorage/OPFS快照提交。用户与角色消息共用ConversationMessages，文件格式不依赖UI。

WorkspaceLifecycle负责标记初始化和清理。WorkspaceData在domain/models；ScheduleCodec在domain/serialization，不再要求业务规则依赖整个文件仓库。

## 约束与余项

保持三态、文件结构、无旧格式迁移、无云端后端和原UI。共享可变集合、较粗通知粒度、工具成功与持久化确认的事务边界，以及整工作区快照的写入成本仍是后续改进项。

依赖方向和内部package导入由test/architecture/dependency_rules_test.dart自动检查。行为回归和平台验证见14-handoff.md。