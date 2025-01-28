import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/server_types.dart';
import '../server_process_service.dart';

final serverProcessServiceProvider = Provider((ref) => ServerProcessService());

final serverOutputProvider = StreamProvider.family<String, String>((ref, serverId) {
  final service = ref.watch(serverProcessServiceProvider);
  return service.getServerOutput(serverId)?.map((output) => output) ?? const Stream.empty();
});

final serverStatusProvider = StreamProvider.family<ServerStatus, String>((ref, serverId) {
  final service = ref.watch(serverProcessServiceProvider);
  return service.getServerStatus(serverId) ?? const Stream.empty();
});

final serverMetricsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, serverId) {
  final service = ref.watch(serverProcessServiceProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return service.getServerMetrics(serverId);
  });
});