class CertificateModel {
  final String certificateId;
  final String level;
  final int score;
  final double percentage;
  final bool isTestMode;

  const CertificateModel({
    required this.certificateId,
    required this.level,
    required this.score,
    required this.percentage,
    required this.isTestMode,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CertificateModel(
      certificateId: data['certificateId'] as String? ?? '',
      level: data['level'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      isTestMode: data['isTestMode'] as bool? ?? false,
    );
  }
}
