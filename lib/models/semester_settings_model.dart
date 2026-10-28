class SemesterSettings {
  final DateTime startDate;
  final DateTime endDate;

  SemesterSettings({
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory SemesterSettings.fromJson(Map<String, dynamic> json) {
    return SemesterSettings(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }
}
