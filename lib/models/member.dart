class Member {
  final int id;
  final String username;
  final String role;
  final String? name;
  final String? phone;
  final String? birth;
  final bool isApproved;

  Member({
    required this.id,
    required this.username,
    required this.role,
    this.name,
    this.phone,
    this.birth,
    this.isApproved = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      username: json['username'] ?? '',
      role: json['role'] ?? 'MEMBER',
      name: json['name'],
      phone: json['phone'],
      birth: json['birth'],
      isApproved: json['is_approved'] == true || json['is_approved'] == 'true',
    );
  }
}
