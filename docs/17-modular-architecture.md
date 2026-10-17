# 代码目录、依赖与扩展

本轮按职责重排源码和测试，使用显式迁移清单核对目标冲突与导入后移动。内部导入统一package:rolechat；不保留旧路径转发文件。业务文件布局和界面交互不因目录改变。

## 源码树

```text
lib/
  main.dart
  app/
    app_store.dart
    role_chat_app.dart
    layout/
  core/
    activation/              激活快照、队列、策略接口
    diagnostics/             日志回调协议
  domain/
    models/                  role_profile、conversation、api_profile、schedule_entry
                             models导出入口、workspace_data、workspace_cleanup
    services/                profile_actions、conversation_messages、schedule_policy
    serialization/           schedule_codec
  application/
    agents/
      agent_runtime.dart     时钟与派发协调
      activation/            role_activation、roleplay_activation_policy
      execution/             runner、execution、binding、context_builder、model_request_gate
      ports/                 agent_workspace、agent_gateway
      tools/                 tool_definitions、agent_tools、agent_documents
    apis/ports/              api_checker及检测结果
  infrastructure/
    ai/                      SDK gateway、模型可用性检测、客户端工厂
    storage/                 OPFS、仓库、Codec、生命周期与打开适配
    presets/                 预设资源加载
    transfer/                ZIP、UUID重映射、下载适配
    platform/                浏览器时区/可见性及stub
    diagnostics/             Console日志实现
  presentation/
    features/                chat、agents、groups、settings、data
    shared/                  图片选择与公共widgets
    controllers/             API检测请求状态
    theme/                   AppTheme、FormMetrics
```

业务模型由models.dart作为规范导出入口；这是领域模型聚合，不是旧preview_models的兼容路径。AppStore取代PreviewStore。main只启动，RoleChatApp独立成文件；真实示例仅在test/fixtures/sample_data.dart，不打包为生产聊天数据。

## 依赖规则

| 层 | 允许的项目依赖 |
| --- | --- |
| core | core，且不认识聊天/Flutter/SDK/存储 |
| domain | domain、core |
| application | application、domain、core |
| infrastructure | infrastructure及应用端口、domain、core |
| presentation | 公共展示、业务模型、应用端口和AppStore界面协调入口 |
| app/main | 启动装配边界，可组合具体实现和界面 |

presentation的导入导出弹窗可以使用专用transfer文件适配，普通展示组件不能读写OPFS或调用SDK。AppStore仍是集中状态门面，不能因此把presentation和app描述成严格无依赖的两个独立包。

core/domain/application禁止Flutter、HTTP/SDK及浏览器实现依赖；infrastructure禁止反向导入app/presentation；presentation不导入AI实现。test/architecture/dependency_rules_test.dart验证这些方向、规范URI及本地路径存在性。
## 激活与执行链路

AppStore装配SDK模型实现、浏览器可见性和Console日志后注入AgentRuntime。RoleActivation将聊天/行程转为ActivationSnapshot；ActivationScheduler只决定到期任务，ActivationPolicy由角色默认策略或测试策略实现。新增来源统一送ActivationRequest，不让具体模型进入core。

AgentRunner消费激活任务并等待ModelRequestGate额度；获得额度后进入处理中。AgentExecution保留已执行过程和累计预算，AgentBinding捕获模型配置并验证是否仍有效，AgentDocuments处理白名单/哈希/锁。通用激活不执行这些副作用。

```text
页面 → AppStore → 领域资料/消息服务 → 存储适配
              → AgentRuntime → 激活快照/策略/队列 → AgentRunner
                   AgentWorkspace端口 ← AppStore       → AgentGateway端口 ← SDK适配
                                                       → 工具与文档规则
检测页面 → ApiChecker端口 ← ModelAvailabilityChecker
```

API探测界面只依赖ApiChecker和ModelCheckResult，生产实现由AppStore提供；不在Widget里new SDK客户端。OpenAIClientFactory统一正常调用与探测的URL和请求策略。

## 测试结构

```text
test/
  architecture/       层次、路径及生产源码可达性
  core/activation/    通用队列、概率0、策略替换、串行/合并
  domain/services/    资料关联和消息规则
  application/agents/ 上下文重处理、工具过程、额度和失效
  infrastructure/     OPFS/初始化/清理/ZIP/接口探测
  app/                应用状态行为
  presentation/       页面、控件、主题和响应式交互
  fixtures/           test_store和sample_data，只用于测试
```

## 扩展方法

- 新激活策略：实现core的ActivationPolicy，在应用层装配；规则需要聊天信息时只改RoleActivation快照适配。
- 新模型传输：实现AgentGateway，放infrastructure/ai并在app注入；应用流程不导入实现。
- 新检测服务：实现ApiChecker，界面和请求状态控制器无需变化。
- 新工具：固定声明、执行分派、业务规则分别维护，不把HTTP或UI塞进工具Schema。
- 新文件格式或存储：改infrastructure/storage，行程纯结构校验归domain/serialization；不在页面拼文件路径。
- 新UI：先复用presentation/shared与theme，再放对应features；不恢复旧的根目录pages/widgets。

## 已知边界

AppStore通知仍较集中，工作区端口暴露可变集合；工具回执与持久化成功没有统一事务，普通保存仍编码整工作区。下一步优化应围绕真实状态/事务/性能需求，不为减少文件行数增加无职责代理层。

本轮改变组织和适配注入，不改变OPFS格式、调度默认、正文处理或已有交互。自动测试与release构建不能替代供应商协议、CORS和目标浏览器实机验收。交付状态见14-handoff，docs纳入Git跟踪。