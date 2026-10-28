class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String university;
  final String department;
  final String semester;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.university,
    required this.department,
    required this.semester,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'university': university,
      'department': department,
      'semester': semester,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      university: json['university'] as String,
      department: json['department'] as String,
      semester: json['semester'] as String,
    );
  }
}
