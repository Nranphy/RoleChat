# RoleChat 文档入口

本目录描述当前实现与已确认规则，已随目录分层重构全面核对。docs纳入Git跟踪，与实现同步提交；README仅面向用户。

## 推荐阅读顺序

1. [交接与运行](14-handoff.md)：当前实现、验证边界和启动方式。
2. [代码结构与依赖](17-modular-architecture.md)：源码、测试目录和扩展入口。
3. [最终方案](16-final-architecture.md)：调度、上下文、权限及默认值。
4. [本地数据](04-data.md)：OPFS文件、初始化、导入导出和清理。
5. [开发规范](08-development.md)：修改代码与验证约定。

## 专项说明

| 文档 | 内容 |
| --- | --- |
| 01-product.md | 产品范围与已实现功能 |
| 02-ui.md | 现行UI与交互规则 |
| 03-architecture.md | 分层及运行流程 |
| 05-scheduling.md | 激活机制、概率与三态 |
| 06-role-runtime.md | 上下文、工具、执行会话与权限 |
| 07-platforms.md | Web运行、发布和浏览器限制 |
| 09-decisions.md | 关键决定及替代方案 |
| 10-ui-preview.md | UI验收清单；文件名沿用早期命名，应用已无预览Tab |
| 11-fluffychat-ui-audit.md | 视觉参考来源与产品差异 |
| 12-ui-component-structure.md | 展示组件目录与边界 |
| 13-dead-code-cleanup.md | 清理结果与维护约束 |
| 15-open-questions.md | 已明确事项、方案默认及待验证扩展 |

已实现不等于所有浏览器和第三方模型均已实机验收。需求冲突时以用户最新明确要求为准，再同步相关专题和交接文档，避免留下互相矛盾的旧描述。
