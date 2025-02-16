import '../../domain/repositories/java_repository.dart';
import '../../domain/entities/java_installation.dart';
import '../datasources/remote/java_service.dart';

class JavaRepositoryImpl implements IJavaRepository {
  final JavaService _javaService;

  JavaRepositoryImpl(this._javaService);

  @override
  Future<List<JavaInstallation>> detectJavaInstallations() =>
      _javaService.detectJavaInstallations();

  @override
  Future<void> validateJavaPath(String path) async {
    final installations = await detectJavaInstallations();
    if (!installations.any((inst) => inst.path == path)) {
      throw Exception('Invalid Java path');
    }
  }

  @override
  Future<String> getDefaultJavaPath() async {
    final installations = await loadJavaInstallations();
    final defaultInst = installations.firstWhere(
          (inst) => inst.isDefault,
      orElse: () => installations.first,
    );
    return defaultInst.path;
  }

  @override
  Future<void> saveJavaInstallations(List<JavaInstallation> installations) =>
      _javaService.saveJavaInstallations(installations);

  @override
  Future<List<JavaInstallation>> loadJavaInstallations() =>
      _javaService.loadJavaInstallations();



  @override
  Future<void> setDefaultJavaInstallation(String path) async {
    final installations = await loadJavaInstallations();
    final updatedInstallations = installations.map((inst) =>
        JavaInstallation(
          path: inst.path,
          version: inst.version,
          isDefault: inst.path == path,
        )
    ).toList();
    await saveJavaInstallations(updatedInstallations);
  }

  @override
  Future<void> removeJavaInstallation(String path) async {
    final installations = await loadJavaInstallations();
    installations.removeWhere((inst) => inst.path == path);
    await saveJavaInstallations(installations);
  }

  @override
  Future<JavaInstallation?> selectAndValidateJavaPath(String path) async {
    try {
      final version = await _javaService.validateAndGetVersion(path);
      if (version != null) {
        return JavaInstallation(
          path: path,
          version: version,
          isDefault: false,
        );
      }
      return null;
    } catch (e) {
      print('Error validating Java path: $e');
      return null;
    }
  }
}