class TimetableEntry {
  final String id;
  final String? courseId;
  final String courseName;
  final String day;
  final String startTime;
  final String endTime;
  final String room;

  TimetableEntry({
    required this.id,
    this.courseId,
    required this.courseName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
    };
  }

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as String,
      courseId: json['courseId'] as String?,
      courseName: json['courseName'] as String,
      day: json['day'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      room: json['room'] as String,
    );
  }
}
