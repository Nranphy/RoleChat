import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';

/// Captures exactly the API/model settings selected at dispatch time.
class AgentBinding {
  AgentBinding(this.role, this.api, this.settings) : model = role.model;
  final RoleProfile role;
  final ApiProfile api;
  final ModelSettings settings;
  final String model;
  String get key => '${api.id}:$model';

  bool current(AgentWorkspace workspace) =>
      role.apiId == api.id &&
      role.model == model &&
      workspace.apis.contains(api) &&
      identical(api.models[model], settings);

  static (AgentBinding?, String?) resolve(
    AgentWorkspace workspace,
    RoleProfile role,
  ) {
    final api = workspace.apis.where((a) => a.id == role.apiId).firstOrNull;
    if (api == null) return (null, '未关联 API 配置');
    if (api.key.trim().isEmpty) return (null, 'API Key 为空');
    if (role.model.trim().isEmpty) return (null, '模型名称为空');
    final settings = api.models[role.model];
    if (settings == null) return (null, '所选模型不在 API 配置中，请在角色基础页重新选择');
    return (AgentBinding(role, api, settings), null);
  }
}
