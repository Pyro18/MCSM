class JavaInstallation {
  final String path;
  final String version;
  final bool isDefault;

  JavaInstallation({
    required this.path,
    required this.version,
    this.isDefault = false,
  });

  factory JavaInstallation.fromJson(Map<String, dynamic> json) {
    return JavaInstallation(
      path: json['path'] as String,
      version: json['version'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'version': version,
      'isDefault': isDefault,
    };
  }
}