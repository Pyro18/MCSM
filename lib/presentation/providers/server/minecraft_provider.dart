import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/server_types.dart';
import '../../../data/datasources/remote/minecraft_service.dart';

final minecraftServiceProvider = Provider((ref) => MinecraftService());

final availableVersionsProvider =
    FutureProvider.family<List<MinecraftVersion>, ServerType>((ref, type) =>
        ref.read(minecraftServiceProvider).getAvailableVersions(type));

final javaPathProvider = FutureProvider<String>(
    (ref) => ref.read(minecraftServiceProvider).findJavaPath());
