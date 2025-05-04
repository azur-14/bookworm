class SystemConfig {
  final int id;
  final String configName;
  late final String configValue;

  SystemConfig({
    required this.id,
    required this.configName,
    required this.configValue,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      id: json['id'] as int,
      configName: json['config_name'] as String,
      configValue: json['config_value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'config_name': configName,
      'config_value': configValue,
    };
  }

  /// helper để dễ copy + sửa value
  SystemConfig copyWith({String? configValue}) {
    return SystemConfig(
      id: id,
      configName: configName,
      configValue: configValue ?? this.configValue,
    );
  }
}
