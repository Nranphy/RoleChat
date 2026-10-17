import 'dart:async';
import 'dart:math';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/core/activation/activation_models.dart';
import 'package:rolechat/core/activation/activation_scheduler.dart';
import 'package:rolechat/core/activation/activation_policy.dart';
import 'package:rolechat/application/agents/activation/roleplay_activation_policy.dart';
import 'package:rolechat/application/agents/execution/agent_binding.dart';
import 'package:rolechat/application/agents/ports/agent_gateway.dart';
import 'package:rolechat/application/agents/execution/agent_runner.dart';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';
import 'package:rolechat/application/agents/execution/model_request_gate.dart';
import 'package:rolechat/application/agents/activation/role_activation.dart';
import 'package:rolechat/core/diagnostics/runtime_events.dart';

export 'package:rolechat/core/activation/activation_models.dart'
    show AgentState;

/// Coordinates workspace snapshots and execution; policy lives in the scheduler.
class AgentRuntime {
  AgentRuntime(
    this.store, {
    required AgentGateway gateway,
    Random? random,
    RuntimeLog log = silentRuntimeLog,
    ActivationPolicy policy = const RoleplayActivationPolicy(),
    bool Function()? isHidden,
    DateTime Function()? clock,
  }) : log = log,
       isHidden = isHidden ?? (() => false),
       clock = clock ?? DateTime.now,
       scheduler = ActivationScheduler(
         random: random,
         log: log,
         policy: policy,
       ) {
    runner = AgentRunner(
      store,
      gateway: gateway,
      gate: gate,
      log: log,
      isClosed: () => _closed,
      clock: this.clock,
    );
  }
  final AgentWorkspace store;
  final RuntimeLog log;
  final bool Function() isHidden;
  final DateTime Function() clock;
  final ActivationScheduler scheduler;
  final gate = ModelRequestGate();
  late final AgentRunner runner;
  final _skipReasons = <String, String>{};
  Timer? _timer;
  bool _closed = false;
  int? _epoch;
  String? _pauseReason;

  AgentState state(String id) => scheduler.state(id);
  void start() {
    if (_closed || _timer != null) return;
    log('调度启动', {'tickSeconds': 1});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick(clock()));
    tick(clock());
  }

  void dispose() {
    _closed = true;
    _timer?.cancel();
    log('调度停止', {});
  }

  void _skip(RoleProfile role, String reason) {
    if (_skipReasons[role.id] == reason) return;
    _skipReasons[role.id] = reason;
    log('跳过角色', {'role': role.name, 'roleId': role.id, 'reason': reason});
  }

  void tick(DateTime now) {
    final pauseReason = _closed
        ? '运行时已关闭'
        : store.transferring
        ? '正在导入或清理数据'
        : isHidden() && store.runtimeData['background'] == false
        ? '页面在后台且未允许后台运行'
        : null;
    if (pauseReason != null) {
      if (_pauseReason != pauseReason) log('调度暂停', {'reason': pauseReason});
      _pauseReason = pauseReason;
      return;
    }
    if (_pauseReason != null) log('调度恢复', {});
    _pauseReason = null;
    if (_epoch != store.dataEpoch) {
      _epoch = store.dataEpoch;
      scheduler.reset();
    }
    final ids = store.activeRoles.map((r) => r.id).toSet();
    scheduler.retainAgents(ids);
    _skipReasons.removeWhere((id, _) => !ids.contains(id));
    for (final role in store.activeRoles) {
      final (binding, error) = AgentBinding.resolve(store, role);
      if (binding == null) {
        _skip(role, error!);
        continue;
      }
      final retryAfter = gate.retryAfter(binding.key);
      if (retryAfter != null && now.isBefore(retryAfter)) {
        _skip(role, '模型未返回工具调用，暂缓重试至 ${retryAfter.toIso8601String()}');
        continue;
      }
      if (_skipReasons.remove(role.id) != null) {
        log('角色恢复调度', {'role': role.name});
      }
      final request = scheduler.evaluate(
        RoleActivation.snapshot(store, role, now),
        now,
      );
      if (request == null) continue;
      final chat = store.activeChats
          .where((c) => c.id == request.targetId && c.members.contains(role.id))
          .firstOrNull;
      if (chat == null) {
        scheduler.complete(role.id);
        continue;
      }
      log('开始处理会话', {
        'role': role.name,
        'chatId': chat.id,
        'model': binding.model,
        'activationReason': request.reason.name,
      });
      unawaited(
        runner
            .run(
              binding,
              chat,
              onProcessing: () => scheduler.markProcessing(role.id),
            )
            .whenComplete(() {
              scheduler.complete(role.id);
              log('处理结束', {'role': role.name, 'chatId': chat.id});
            }),
      );
    }
  }
}
