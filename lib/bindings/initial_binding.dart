import 'package:get/get.dart';

import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/storage/local_storage.dart';
import 'package:voxora/data/providers/ai_provider.dart';
import 'package:voxora/data/providers/auth_provider.dart';
import 'package:voxora/data/providers/lesson_provider.dart';
import 'package:voxora/data/providers/progress_provider.dart';
import 'package:voxora/data/repositories/auth_repository.dart';
import 'package:voxora/data/repositories/lesson_repository.dart';
import 'package:voxora/data/repositories/progress_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ── Core infrastructure ───────────────────────
    Get.lazyPut<LocalStorage>(
      () => LocalStorage(),
      fenix: true,
    );

    Get.lazyPut<ApiClient>(
      () => ApiClient(Get.find<LocalStorage>()),
      fenix: true,
    );

    // ── Data providers ────────────────────────────
    Get.lazyPut<AuthProvider>(
      () => AuthProvider(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<LessonProvider>(
      () => LessonProvider(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<AiProvider>(
      () => AiProvider(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<ProgressProvider>(
      () => ProgressProvider(Get.find<ApiClient>()),
      fenix: true,
    );

    // ── Repositories ──────────────────────────────
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(
        Get.find<AuthProvider>(),
        Get.find<LocalStorage>(),
      ),
      fenix: true,
    );

    Get.lazyPut<LessonRepository>(
      () => LessonRepository(Get.find<LessonProvider>()),
      fenix: true,
    );

    Get.lazyPut<ProgressRepository>(
      () => ProgressRepository(Get.find<ProgressProvider>()),
      fenix: true,
    );
  }
}
