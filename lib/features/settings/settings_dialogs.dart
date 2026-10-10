import 'package:rolechat/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/shared/widgets/common.dart';
import 'package:rolechat/design/form_metrics.dart';

Future<void> showLocalDataInfo(BuildContext context) => managedDialog<void>(
  context: context,
  builder: (context) => AppDialog.content(
    title: const Text('关于本地数据'),
    content: const Text(
      '主题、头像以及角色与群聊资料保存在当前浏览器。API 配置与消息仅在本次运行中保留。导入导出和角色自动回复尚未实现。',
    ),
    actions: [
      TextButton(
        style: FormMetrics.dialogActionStyle,
        onPressed: () => Navigator.pop(context),
        child: const Text('知道了'),
      ),
    ],
  ),
);
void showRoleChatAbout(BuildContext context) => showAboutDialog(
  context: context,
  applicationName: 'RoleChat',
  applicationVersion: 'UI Preview 0.1',
  applicationIcon: const RoleAvatar('', icon: Icons.chat_bubble_outline),
  children: [const Text('本版本提供 UI 预览与真实接口检测，聊天暂不调用模型。')],
);

Future<void> editThemeColor(
  BuildContext context,
  Color seed,
  ValueChanged<Color> onChanged,
) async {
  final controller = TextEditingController(
    text: seed.toARGB32().toRadixString(16).substring(2).toUpperCase(),
  );
  final form = GlobalKey<FormState>();
  await managedDialog<void>(
    context: context,
    builder: (context) => AppDialog.content(
      title: const Text('自定义主题颜色'),
      content: Form(
        key: form,
        child: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '十六进制颜色',
            prefixText: '#',
            hintText: '597B66',
          ),
          validator: (v) =>
              RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v ?? '') ? null : '请输入六位颜色值',
        ),
      ),
      actions: [
        TextButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          style: FormMetrics.dialogActionStyle,
          onPressed: () {
            if (!form.currentState!.validate()) return;
            onChanged(Color(int.parse('ff${controller.text}', radix: 16)));
            Navigator.pop(context);
          },
          child: const Text('应用'),
        ),
      ],
    ),
  );
  controller.dispose();
}
