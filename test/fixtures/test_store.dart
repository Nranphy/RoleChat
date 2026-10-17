import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/domain/models/workspace_data.dart';
import 'package:rolechat/infrastructure/storage/workspace_storage.dart';
import 'sample_data.dart';

/// Synthetic conversations belong to tests, never application initialization.
AppStore createTestStore(
  SharedPreferences preferences, {
  WorkspaceStorage? storage,
}) {
  final store = AppStore(preferences, storage: storage);
  // UI fixtures represent an already initialized workspace, without real presets.
  if (store.storage case final MemoryWorkspaceStorage memory) {
    memory.initialized = true;
  }
  store.applyData(
    WorkspaceData(
      apis: SampleData.apis(),
      roles: SampleData.roles(),
      chats: SampleData.conversations(),
      schedules: SampleData.schedules(),
    ),
  );
  return store;
}
