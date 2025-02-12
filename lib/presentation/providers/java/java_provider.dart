import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/java_installation.dart';
import '../../../data/datasources/remote/java_service.dart';

final javaServiceProvider = Provider((ref) => JavaService());

final javaInstallationsProvider =
    FutureProvider<List<JavaInstallation>>((ref) async {
  final service = ref.read(javaServiceProvider);

  // First try to load saved installations
  final savedInstallations = await service.loadJavaInstallations();
  if (savedInstallations.isNotEmpty) {
    return savedInstallations;
  }

  // If no saved installations, detect them
  final installations = await service.detectJavaInstallations();

  // Save the detected installations
  await service.saveJavaInstallations(installations);

  return installations;
});

final defaultJavaInstallationProvider =
    Provider<AsyncValue<JavaInstallation>>((ref) {
  final installations = ref.watch(javaInstallationsProvider);

  return installations.when(
    data: (list) {
      try {
        return AsyncValue.data(
          list.firstWhere(
            (inst) => inst.isDefault,
            orElse: () => list.first,
          ),
        );
      } catch (e) {
        return const AsyncValue.error(
          "No Java installation found",
          StackTrace.empty,
        );
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
