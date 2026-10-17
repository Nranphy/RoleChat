import '../chat/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});
  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  bool enabled = true;
  double probability = 80;
  String state = '正常';
  String status = '暂停';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading('界面展览', ''),
              const PreviewNotice(text: '这里可独立验收组件，不需要创建角色或连接 API。'),
              const SizedBox(height: 26),
              section(
                '消息与引用',
                Column(
                  children: [
                    MessageBubble(
                      message: ChatMessage(
                        id: 'a',
                        roleId: 'showcase-role',
                        text: '窗外开始下雨了。\n给你留了一杯热茶。',
                        time: '16:42',
                      ),
                      name: '咲',
                    ),
                    MessageBubble(
                      message: ChatMessage(
                        id: 'b',
                        text: '那我们就在这里待一会儿吧。',
                        reply: const MessageReference(
                          messageId: 'a',
                          text: '给你留了一杯热茶。',
                          senderName: '咲',
                          roleId: 'showcase-role',
                        ),
                        time: '16:43',
                      ),
                      name: '你',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.description_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('周末的小计划.txt'),
                                Text(
                                  '文本附件 · 2.4 KB · 展示',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.file_download_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              section(
                '按钮、头像与标签',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () => toast(context, '主要按钮点击成功'),
                          child: const Text('主要操作'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => toast(context, '次要按钮点击成功'),
                          child: const Text('次要操作'),
                        ),
                        OutlinedButton(
                          onPressed: () => toast(context, '描边按钮点击成功'),
                          child: const Text('描边操作'),
                        ),
                        const FilledButton(onPressed: null, child: Text('不可用')),
                        TextButton(
                          onPressed: () => toast(context, '文字按钮点击成功'),
                          child: const Text('文字操作'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Wrap(
                      spacing: 12,
                      children: [
                        RoleAvatar('朝雫'),
                        RoleAvatar('枫'),
                        RoleAvatar('凪津'),
                        RoleAvatar('咲'),
                        RoleAvatar('若叶'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      children: ['暂停', '激活', '处理中']
                          .map(
                            (s) => ChoiceChip(
                              label: Text(s),
                              selected: status == s,
                              onSelected: (_) => setState(() => status = s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('当前选择：$status（仅展示）'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              section(
                '表单与交互',
                Column(
                  children: [
                    const TextField(
                      decoration: InputDecoration(
                        labelText: '角色名称',
                        hintText: '一个好听的名字',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '密钥字段',
                        hintText: '这里不会保存凭据',
                        suffixIcon: Icon(Icons.visibility_off_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: '错误状态',
                        errorText: '请输入有效的接口地址',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开关组件'),
                      subtitle: const Text('点击查看选中与关闭效果'),
                      value: enabled,
                      onChanged: (v) => setState(() => enabled = v),
                    ),
                    Slider(
                      value: probability,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${probability.round()}%',
                      onChanged: (v) => setState(() => probability = v),
                    ),
                    Text('概率滑块：${probability.round()}%'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await confirm(
                              context,
                              title: '删除角色？',
                              body: '这个角色正在参与「社团群聊」。\n此处仅展示确认弹窗。',
                            );
                            if (context.mounted) {
                              toast(context, result ? '确认操作已展示' : '已取消');
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('确认弹窗'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => toast(context, '这是一条轻量提示，操作已完成。'),
                          icon: const Icon(Icons.notifications_none),
                          label: const Text('提示消息'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              section(
                '空、加载与错误状态',
                Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      children: ['正常', '空状态', '加载中', '错误']
                          .map(
                            (s) => ChoiceChip(
                              label: Text(s),
                              selected: state == s,
                              onSelected: (_) => setState(() => state = s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 260,
                      child: switch (state) {
                        '空状态' => const EmptyState(
                          title: '暂无消息',
                          subtitle: '发送消息开始聊天。',
                        ),
                        '加载中' => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 18),
                              Text('正在整理回忆…（展示）'),
                            ],
                          ),
                        ),
                        '错误' => EmptyState(
                          title: '暂时没能连接',
                          subtitle: '错误展示，不会真的发送请求。',
                          action: OutlinedButton(
                            onPressed: () => setState(() => state = '正常'),
                            child: const Text('重试'),
                          ),
                        ),
                        _ => const EmptyState(
                          title: '一切准备好了',
                          subtitle: '选择上面的标签查看不同状态。',
                        ),
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              section(
                '文字与富文本风格',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('文字样式', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    const Text(
                      '正文样式示例。\n这里是一段普通文字，后续 Markdown 渲染可复用相同的色彩与排版。',
                      style: TextStyle(height: 1.8),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SelectableText(
                        '今天的小计划\n  1. 逛花店\n  2. 喝一杯咖啡\n  3. 慢慢走回家',
                        style: TextStyle(fontFamily: 'monospace', height: 1.8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '这是一条次级说明，用来补充必要的信息。',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget section(String title, Widget child) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}
