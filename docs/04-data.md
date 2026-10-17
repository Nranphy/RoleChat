# 本地文件与数据生命周期

业务数据使用浏览器OPFS，主题偏好使用SharedPreferences对应的浏览器偏好。文件按站点origin隔离；localhost与127.0.0.1、不同端口的存储互不等同。不是用户磁盘上的项目目录，也不需要选择本地文件夹。

## 物理结构

OPFS的rolechat目录包含独立initialized.json、active.json及UUID快照目录。active.json引用当前完整快照；成功切换指针后清理前一快照。业务编码后的快照结构为：

```text
config.json
auth.json（本地保存；导出默认排除）
runtime.json
agents/<角色UUID>/
  profile.json
  identity.md
  soul.md
  memory.md
  schedule.json
  avatar.png（可选）
chats/<私聊UUID>/
  profile.json
  messages.jsonl
groups/<群聊UUID>/
  profile.json
  background.md
  messages.jsonl
  avatar.png（可选）
```

config.json保存API的ID、名称、地址及模型参数；auth.json按API ID单独保存Key。角色profile.json包含名称、API/模型选择、QA样例、归档、时区、检查间隔、工具轮数、默认激活概率和锁。Markdown正文独立为UTF-8文件。

会话profile.json包含成员、归档及nextSequence；消息JSONL包含消息ID、递增序号、发送者ID/姓名快照、UTC时间、正文、@及引用快照。本地用户用空roleId标识，不建立用户资料或UUID。runtime.json保存查看游标、历史窗口与后台偏好，不是聊天已读功能。

## 初始化

initialized.json仅表示已完成初始化，内容为{"initialized":true}。它独立于业务快照，不随资料归档/删除或ZIP导入而删除。

- 有标记：只读取数据，不检查预设数量、不恢复用户删除的人物；标记存在但业务数据缺失则报错。
- 无标记：加载已有可读数据，按固定UUID补建缺失的五个角色、五个空私聊及“回春女子校社团”空群聊，补入缺少的预设成员，再成功保存并写标记。
- 同UUID资料、消息和归档状态保留；不按名字合并，不删除额外成员。数据损坏报错，不用预设覆盖。
- 清除标记后下次刷新重新补缺；完整清空后刷新重新初始化。

预设角色为朝雫、枫、凪津、咲、若叶。源D:/agent-identity只读；图片与适配后的设定位于assets/presets。固定命名空间a25a1ee4-0a9b-4b41-a95c-fcaa53725cf2，UUIDv5键为role:<目录>、private-chat:<目录>、group:school-club。用户创建、API、消息及新行程规则使用UUIDv4，前端不展示ID。

## 提交与并发

WorkspaceRepository先编码调用时数据，再串行写入；OPFS通过快照指针提交，避免混用多批文件。Web Locks限制同origin单个运行所有者。内存模型可继续编辑，导入/清理则暂停新保存并通过dataEpoch使旧模型结果失效。

角色文档工具另外检查预期内容哈希和用户锁。当前并非数据库事务系统；工具成功与文件保存成功的统一事务边界仍需后续完善。普通保存仍编码整个工作区，JSONL不是每次只追加一行的实现。

## ZIP

完整导出保留业务目录；单角色包含相关API配置、资料、文档、头像与行程，不含聊天记录。默认不含Key，用户显式勾选才包含auth.json；不导出initialized.json和运行游标。

导入先检查路径、文件类型、大小和结构。按UUID逐项确认冲突：覆盖以导入内容替换对应实体；均保留为导入实体重新生成ID并更新关联。无冲突部分合并，单角色导入补建空私聊。导入不会按名称去重，当前没有单群聊导出。

## 归档、删除与清理

角色/会话先归档，归档角色不参与调度。永久删除角色可选择保留私聊，群历史与发送者快照保留；永久删除会话删除其目录内容。删除消息直接重写JSONL，不记录删除事件。

设置提供四项确认操作：全部数据（含Key、偏好与标记）、角色/群聊及关联消息、仅聊天数据、仅初始化标记。部分清理保留API、偏好或标记的范围以界面提示为准；仅清聊天不会删除角色记忆。

代码入口：infrastructure/storage、infrastructure/transfer、infrastructure/presets和domain/serialization。只维护当前格式，不引入profiles.v2、schema迁移或旧字段兼容。正常新字段默认值与删除角色后的显示占位不属于旧格式迁移。
