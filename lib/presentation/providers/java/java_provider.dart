import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/java_service.dart';
import '../../../data/repositories/java_repository_impl.dart';
import '../../../domain/entities/java_installation.dart';
import '../../../domain/repositories/java_repository.dart';

final javaServiceProvider = Provider((ref) => JavaService());

final javaInstallationsProvider =
FutureProvider<List<JavaInstallation>>((ref) async {
  final service = ref.watch(javaServiceProvider);

  final savedInstallations = await service.loadJavaInstallations();
  if (savedInstallations.isNotEmpty) {
    return savedInstallations;
  }

  final installations = await service.detectJavaInstallations();

  if (installations.isNotEmpty) {
    await service.saveJavaInstallations(installations);
  }

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

final javaRepositoryProvider = Provider<IJavaRepository>((ref) {
  final service = ref.watch(javaServiceProvider);
  return JavaRepositoryImpl(service);
});