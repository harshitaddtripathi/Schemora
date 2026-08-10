class HealthStatus {
  final String status;
  final String version;
  final String environment;
  final bool databaseConnected;
  final double latencyMs;

  HealthStatus({
    required this.status,
    required this.version,
    required this.environment,
    required this.databaseConnected,
    required this.latencyMs,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '0.0.0',
      environment: json['environment'] as String? ?? 'unknown',
      databaseConnected: json['database_connected'] as bool? ?? false,
      latencyMs: (json['latency_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
