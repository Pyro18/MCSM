import '../entities/java_installation.dart';

abstract class IJavaRepository {
  Future<List<JavaInstallation>> detectJavaInstallations();

  Future<void> validateJavaPath(String path);

  Future<String> getDefaultJavaPath();

  Future<void> saveJavaInstallations(List<JavaInstallation> installations);

  Future<List<JavaInstallation>> loadJavaInstallations();

  Future<void> setDefaultJavaInstallation(String path);

  Future<void> removeJavaInstallation(String path);
}
