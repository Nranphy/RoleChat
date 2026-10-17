# Agent上下文、执行和工具

应用层实现位于lib/application/agents；模型端口在ports，SDK实现位于lib/infrastructure/ai。SDK负责协议传输，应用自行执行调度、权限和工具循环。

## 资料与上下文

identity.md声明身份，仅用户编辑。soul.md控制性格/观念，memory.md记录该角色跨私聊、群聊共用的记忆；后两者及结构化行程可自动更新，也可被用户锁定。群背景使用background.md，QA样例仅作为风格参考，不伪造历史消息。

请求组织为：固定系统提示、固定tools参数、规范化共享会话历史、后置当前角色/文档/时间/活动、已执行的工具过程。tools是API字段，其真实模板顺序和缓存由提供方决定，不承诺不同Key/模型/服务之间共享缓存。

共享历史使用消息ID、序号、发送者及姓名快照、固定时间和正文，不按不同角色重映射历史身份。previous_view_sequence和check_kind区分新消息处理与自主查看旧历史；定期检查可以沉默或开启新话题，不要求重新回答旧消息。

历史达到模型高水位后批量裁去旧段，保留较新内容；不删除存储。资料、工具和输出均预留预算。当前采用UTF-8字节保守估算，不是精确tokenizer。

## 执行会话

AgentRunner负责请求和工具循环，AgentExecution保存本次处理已执行的assistant调用、tool结果、调用ID回执和累计请求数。目标会话他人新消息到来后，旧HTTP自然结束，未执行的旧返回失效；重建最新基础上下文后附上已执行过程继续，不从空工具过程重跑。

只记录已执行调用和配对结果，支持Chat Completions及Responses。最大工具轮数覆盖重处理前后的请求，不重置；finish后不执行同批后续工具。相同工具调用ID复用原结果，ID参数冲突报错；不按正文相同过滤独立消息。

处理开始推进游标，失败不回退。历史工具可读取处理期间的新消息。同角色串行、其他角色并发；配置、成员、归档或数据epoch变化均可禁止旧副作用提交。

## 固定工具

| 工具 | 当前输入和行为 |
| --- | --- |
| send_message | text；当前会话发送纯文本，去首尾空白，非空且不超过8000字符 |
| search_history | conversation_id、query；只访问角色当前参与且未归档的会话，空查询取最近消息，倒序最多50条 |
| search_memory | query；当前角色memory.md逐行关键词匹配，最多50行，无embedding |
| read_document | name；白名单soul.md、memory.md、schedule.json，返回正文和哈希 |
| update_document | name、content、expected_hash；校验哈希、锁及结构，正文最多200000字符 |
| finish | 无参数；允许不发言并结束本次处理 |

声明在tools/tool_definitions.dart，分派在tools/agent_tools.dart，文档校验在tools/agent_documents.dart。所有副作用先检查当前代次和会话权限。没有任意OPFS路径、shell、任意网络或身份修改工具。

当前成员关系决定历史权限，刚加入也可读取该会话早期历史；退出后不能读取。记忆属于角色，不按群聊/私聊隔离。只保留当前文档，不保存修订历史；冲突要求重新读取，不静默覆盖。

## 模型与错误

原生工具调用是运行前提，公开消息只通过send_message，最终模型正文不自动展示，无Markdown渲染和流式草稿。请求使用tool_choice required；一次没有工具调用不等于永久不支持：记录finishReason、提示原因，并对相同API/模型暂缓60秒后允许新检查。额度不足时提示增加最大输出tokens。

接口检测与正式角色运行分开；探测成功不等于工具协议必然兼容。失败提示某角色试图发消息但失败。日志不记录Key、提示词、工具参数或聊天正文；通过runId、调用ID和消息ID关联。

工具成功回执当前先确认内存副作用，异步文件保存的事务确认仍需后续完善。真实模型供应商和浏览器平台须单独验收，mock通过不代表实机全部通过。