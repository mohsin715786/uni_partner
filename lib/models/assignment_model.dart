class Assignment {
  final String id;
  final String title;
  final String courseName;
  final DateTime dueDate;
  final String priority;
  bool isCompleted;

  Assignment({
    required this.id,
    required this.title,
    required this.courseName,
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
  });

  /// Checks if the assignment is overdue (not completed and due date before today).
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  /// Calculates the number of days remaining until due date using date-only comparison.
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'courseName': courseName,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      courseName: json['courseName'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: json['priority'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
