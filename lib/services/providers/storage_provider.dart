import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/app_storage.dart';

final appStorageProvider = Provider<AppStorage>((ref) => AppStorage());