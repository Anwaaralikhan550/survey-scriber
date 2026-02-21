import 'package:equatable/equatable.dart';

class ConfigVersion extends Equatable {
  const ConfigVersion({
    required this.version,
    required this.updatedAt,
  });

  final int version;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [version, updatedAt];
}
