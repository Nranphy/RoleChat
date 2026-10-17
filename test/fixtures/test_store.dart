import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/workspace_data.dart';
import 'package:rolechat/data/workspace_storage.dart';
import 'preview_data.dart';

/// Synthetic conversations belong to tests, never application initialization.
PreviewStore createTestStore(
  SharedPreferences preferences, {
  WorkspaceStorage? storage,
}) {
  final store = PreviewStore(preferences, storage: storage);
  // UI fixtures represent an already initialized workspace, without real presets.
  if (store.storage case final MemoryWorkspaceStorage memory) {
    memory.initialized = true;
  }
  store.applyData(
    WorkspaceData(
      apis: PreviewData.apis(),
      roles: PreviewData.roles(),
      chats: PreviewData.conversations(),
      schedules: PreviewData.schedules(),
    ),
  );
  return store;
}
