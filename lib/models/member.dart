class Member {
  final int id;
  final String name;
  final String phone;
  final String? birth; // Make sure nullable fields are handled
  final String? pin;
  final bool isApproved; // Dart property
  final String role;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    this.birth,
    this.pin,
    required this.isApproved,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      birth: json['birth'],
      pin: json['pin'],
      // 👇 HERE IS THE FIX: Map 'is_approved' (Server) to 'isApproved' (App)
      isApproved: json['is_approved'] ?? false,
      role: json['role'] ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'birth': birth,
      'pin': pin,
      'is_approved': isApproved, // Send back as snake_case too
      'role': role,
    };
  }
}
