import 'package:rolechat/services/model_availability_checker.dart';
import 'widgets/api_configuration_form.dart';
import 'package:flutter/material.dart';
import 'package:rolechat/design/form_metrics.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/common.dart';

Future<void> editApi(
  BuildContext context,
  PreviewStore store, {
  ApiProfile? profile,
  ModelAvailabilityChecker? checker,
}) async {
  final name = TextEditingController(text: profile?.name ?? '');
  final url = TextEditingController(text: profile?.url ?? '');
  final key = TextEditingController(text: profile?.key ?? '');
  var hidden = true;
  var checking = false;
  var revision = 0;
  ModelCheckResult? checkResult;
  final form = GlobalKey<FormState>();
  await managedDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(profile == null ? '添加 API 配置' : '编辑 API 配置'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: ApiConfigurationForm(
                name: name,
                url: url,
                apiKey: key,
                hidden: hidden,
                onToggleVisibility: () => setLocal(() => hidden = !hidden),
                checkMessage: checkResult?.message,
                checkSucceeded: checkResult?.success ?? false,
                onConnectionChanged: (_) => setLocal(() {
                  revision++;
                  checkResult = null;
                }),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: FormMetrics.dialogActionStyle,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: FormMetrics.dialogActionStyle,
            onPressed: checking
                ? null
                : () async {
                    final requestRevision = ++revision;
                    setLocal(() {
                      checking = true;
                      checkResult = null;
                    });
                    final result = await (checker ?? ModelAvailabilityChecker())
                        .checkApi(address: url.text, apiKey: key.text);
                    if (!context.mounted) return;
                    setLocal(() {
                      checking = false;
                      if (requestRevision == revision) checkResult = result;
                    });
                  },
            child: Text(checking ? '检查中…' : '检查接口'),
          ),
          FilledButton(
            style: FormMetrics.dialogActionStyle,
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final p =
                  profile ?? ApiProfile(id: store.newId(), name: '', url: '');
              p.name = name.text.trim();
              p.url = url.text.trim();
              p.key = key.text;
              if (profile == null) store.apis.add(p);
              store.changed();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  url.dispose();
  key.dispose();
}
