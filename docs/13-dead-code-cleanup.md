# 清理与维护记录

当前结构以17-modular-architecture为准。旧文档中的“展览仍在用、profiles兼容、只实现UI”描述均已失效，不作为维护要求。

## 已清理或替代

- 删除独立界面展览页、专用提示和标题组件，导航仅保留三个业务入口。
- 移除旧emoji头像字段、角色简介、未读展示、已读、免打扰及无调用入口。
- 不保留早期profiles/v2迁移、旧行程文本解析或重复字段；正常新字段默认值和错误占位不是旧格式兼容。
- 生产代码不包含演示会话，测试数据集中test/fixtures/sample_data.dart。
- AppStore取代PreviewStore，领域模型按角色、API、会话、行程分文件；旧路径不保留转发壳。
- 原lib/data、runtime、services、features、shared、design等混合目录已迁入明确层次，空pages/widgets/showcase目录已移除。
- 撤掉按正文拦截消息；保留调用ID幂等、完整工具过程、累计预算和过时代次失效。
- 工具声明、文档规则和SDK实现与应用端口分离，共用客户端地址规范化。

## 维护规则

删除代码前查调用和导入/导出可达性，结合分析与行为测试；不要因为参数当前只被一个页面使用就删除合理公共接口。Flutter自适应控件仍可能引用Cupertino字体，不能仅凭显式Icon引用判断其无用。

控制器、图片提供器、GlobalKey/高亮和计时器按所有者释放。模型异步返回需校验数据epoch、配置身份、成员权限和当前上下文，不能向导入/清理后的新数据写回旧结果。

分层依赖由test/architecture/dependency_rules_test.dart约束，完整行为测试按层次组织。目录整理不意味着事务、细粒度状态或大数据性能问题已经解决；真实剩余项见15-open-questions。

README保持用户介绍，docs纳入Git跟踪，不修改.gitignore。本轮临时迁移清单/脚本在核对后移除，不作为产品源码留下。