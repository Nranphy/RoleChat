# Dart与Flutter开发规范

本规范适用于D:/Project/RoleChat。Flutter负责界面，Dart负责应用流程和业务规则；D:/Project/fluffychat及D:/agent-identity保持只读。开始前阅读00-index、14-handoff和17-modular-architecture。

## 结构与依赖

core放通用机制；domain放模型、业务规则和结构校验；application放执行流程及端口；infrastructure实现SDK/浏览器/OPFS；presentation放页面、展示组件和主题；app负责状态协调与具体实现装配。

core不依赖聊天/Flutter/SDK；domain不依赖application以上层；application不导入基础设施或UI；infrastructure不导入app或presentation。页面通过AppStore和应用端口操作，普通展示组件只收数据/回调。导入导出的用户文件交互可使用专用transfer适配。

内部统一package:rolechat/导入，包括条件导入与导出。新文件按对应职责放置；不要恢复旧runtime/data/services混合目录，也不保留旧路径转发文件。通用机制和业务默认策略分开。

## 编码与异步

文件lower_snake_case，类型UpperCamelCase，成员lowerCamelCase；使用空安全、final/const和dart format。业务集合当前仍可变，不把“以后改不可变”写成已完成。

计时器、订阅、控制器和请求资源有明确所有者和关闭入口。异步操作后使用BuildContext前检查mounted；重复保存/检测应禁止。正式模型请求不自动重试，在途旧请求不强制取消，副作用通过代次/配置/权限校验失效。

激活只保留暂停、激活、处理中；时间/随机/gateway/日志通过注入测试。工具过程与累计预算跨上下文更新保留，不按消息正文去重。按调用ID处理技术幂等，文件更新检查哈希和用户锁。

## UI与数据

统一AppTheme、FormMetrics、ContentPage、AppDialog及ProfileDialogFrame。表单控制器属于展示层，跨实体引用更新属于domain服务；文件IO和Codec属于适配层。修改样式前看02-ui和12-ui-component-structure。

只维护当前文件格式，不加版本后缀或迁移兼容。真实凭据不进入源码、文档、日志、测试快照或Git；测试使用假的Key和可控gateway。初始化标记行为见04-data，不能因角色数量或名称变化擅自重置用户资料。

## 验证与提交

常规执行dart format lib test、flutter analyze、flutter test；交付执行flutter build web --release。test按对应层次组织，test/architecture自动限制层次依赖。UI测试覆盖浅深主题及窄宽屏，实机平台测试另行记录。

分段写文件，按可审查职责提交feat/fix/refactor等Conventional Commits，仅在用户授权后push。明确路径暂存，不使用git add .或-A；docs纳入Git跟踪，不修改.gitignore。README只保留用户介绍与感谢，不写技术交接内容。新增或改动职责时同步相关文档，避免仅追加补丁式历史造成矛盾。