class Exam {
  final String id;
  final String courseName;
  final String examTitle;
  final DateTime examDateTime;
  final String room;

  Exam({
    required this.id,
    required this.courseName,
    required this.examTitle,
    required this.examDateTime,
    required this.room,
  });

  /// Returns true if the exam date/time has passed.
  bool get isPast => examDateTime.isBefore(DateTime.now());

  /// Returns duration remaining until exam date/time.
  Duration get timeRemaining => examDateTime.difference(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'examTitle': examTitle,
      'examDateTime': examDateTime.toIso8601String(),
      'room': room,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      examTitle: json['examTitle'] as String,
      examDateTime: DateTime.parse(json['examDateTime'] as String),
      room: json['room'] as String,
    );
  }
}
