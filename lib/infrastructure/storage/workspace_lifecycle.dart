import 'package:rolechat/domain/models/workspace_cleanup.dart';
import 'package:rolechat/domain/models/workspace_data.dart';
import 'package:rolechat/infrastructure/presets/preset_workspace.dart';
import 'package:rolechat/infrastructure/storage/workspace_codec.dart';
import 'package:rolechat/infrastructure/storage/workspace_repository.dart';

/// File lifecycle operations, separate from UI preferences and navigation.
class WorkspaceLifecycle {
  WorkspaceLifecycle(this.repository);
  final WorkspaceRepository repository;
  Future<WorkspaceData> initialize(String timezone) async {
    final initialized = await repository.storage.isInitialized();
    final saved = await repository.load();
    if (initialized) {
      if (saved == null) throw StateError('初始化标记存在，但数据文件缺失；不会重新注入预设');
      return saved;
    }
    final initial = await loadPresetWorkspace(
      timezone: timezone,
      existing: saved,
    );
    await repository.saveOrThrow(initial);
    await repository.storage.markInitialized();
    return initial;
  }

  Future<WorkspaceData?> clear(
    WorkspaceCleanup scope,
    WorkspaceData current,
  ) async {
    await repository.flush();
    if (scope == WorkspaceCleanup.initialization) {
      await repository.storage.removeInitializationMarker();
      return null;
    }
    if (scope == WorkspaceCleanup.all) {
      await repository.storage.clearAll();
      return WorkspaceData(apis: [], roles: [], chats: [], schedules: []);
    }
    final next = scope == WorkspaceCleanup.profiles
        ? WorkspaceData(
            apis: current.apis.toList(),
            roles: [],
            chats: [],
            schedules: [],
            runtime: {
              if (current.runtime.containsKey('background'))
                'background': current.runtime['background'],
            },
          )
        : WorkspaceCodec.decode(WorkspaceCodec.encode(current));
    if (scope == WorkspaceCleanup.messages) {
      for (final chat in next.chats) {
        chat.messages.clear();
        chat.nextSequence = 1;
      }
      next.runtime.removeWhere((key, _) => key != 'background');
    }
    await repository.saveOrThrow(next);
    return next;
  }
}
