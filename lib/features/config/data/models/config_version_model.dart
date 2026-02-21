import '../../domain/entities/config_version.dart';

class ConfigVersionModel extends ConfigVersion {
  const ConfigVersionModel({
    required super.version,
    required super.updatedAt,
  });

  factory ConfigVersionModel.fromJson(Map<String, dynamic> json) => ConfigVersionModel(
      version: json['version'] as int? ?? 1,
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );

  Map<String, dynamic> toJson() => {
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
    };
}
