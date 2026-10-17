# Web运行、平台与发布

当前仅Flutter Web，支持桌面和手机宽度。没有Android构建目标、Python运行进程、自建推送服务或云端控制后端。SDK、存储、浏览器和日志适配在lib/infrastructure，应用流程不直接依赖平台实现。

## 启动和后台

main打开OPFS与偏好，AppStore恢复/初始化工作区后自动启动AgentRuntime，再显示RoleChatApp。打开失败或运行所有权被占用时显示错误，不回退到临时业务存储。

页面可执行时按随机间隔检查。后台偏好允许时继续发起新检查；浏览器可能节流、冻结或回收页面，关闭后不保证执行。恢复按当前时间匹配行程，合并错过的检查，不补跑积压。Service Worker不是常驻Agent运行进程。

同一origin通过Web Locks保持一个运行所有者。localhost、127.0.0.1和不同端口属于不同站点存储范围，不能用换地址验证“同一份”数据。

## 网络与数据

模型API须支持浏览器CORS和所选OpenAI协议；前端不能替提供方修复缺失的跨域响应头。SDK实例按请求配置创建，不用全局地址/Key静态值互相覆盖。接口探测和正式调用共用OpenAIClientFactory。

业务数据在OPFS，Key在独立auth.json，本地没有额外加密；ZIP默认不含Key。上下文包含的聊天和角色资料会发送给模型。浏览器清理站点数据可能删除文件，备份使用导出功能，不自动跨设备同步。

## 构建与本地访问

在D:/Project/RoleChat执行flutter build web --release，产物为build/web。node scripts/preview.mjs在http://127.0.0.1:4173/提供静态预览；这是静态资源服务，不承担调度、API调用或业务存储。长期预览进程在Windows应隐藏启动。

发布为静态站点，验证安全上下文、base path、资源路径、刷新、OPFS配额/恢复、ZIP下载上传、CORS和目标浏览器。生产API凭据不得编译进资源或提交历史。应用不要求终端用户访问项目源码目录来保存数据。

当前已通过自动测试和release构建；后台长期执行、目标设备OPFS额度、第三方模型工具协议及ZIP实际上传下载仍需实机验证。