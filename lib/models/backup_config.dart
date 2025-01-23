class BackupConfig {
  final String backupPath;
  final bool autoBackup;
  final int backupFrequency;
  final int maxBackups;

  BackupConfig({
    required this.backupPath,
    this.autoBackup = true,
    this.backupFrequency = 24,
    this.maxBackups = 5,
  });

  factory BackupConfig.fromJson(Map<String, dynamic> json) => BackupConfig(
    backupPath: json['backupPath'] as String? ?? '',
    autoBackup: json['autoBackup'] as bool? ?? true,
    backupFrequency: json['backupFrequency'] as int? ?? 24,
    maxBackups: json['maxBackups'] as int? ?? 5,
  );

  Map<String, dynamic> toJson() => {
    'backupPath': backupPath,
    'autoBackup': autoBackup,
    'backupFrequency': backupFrequency,
    'maxBackups': maxBackups,
  };

  factory BackupConfig.defaults() => BackupConfig(
    backupPath: '',
    autoBackup: true,
    backupFrequency: 24,
    maxBackups: 5,
  );
}
