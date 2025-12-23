class User {
  final int? id;
  final String name;
  final String phone;
  final String birth;
  final int rank;
  final int points;
  final String status;
  final bool isApproved;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.birth,
    required this.rank,
    required this.points,
    required this.status,
    required this.isApproved,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Fail-safe Parsing Logic
    try {
      return User(
        id: int.tryParse(json['id']?.toString() ?? '0'),
        name: json['name']?.toString() ?? '이름 없음',
        phone: json['phone']?.toString() ?? '번호 없음',
        birth: json['birth']?.toString() ?? '',
        // Safe parsing for numeric fields
        rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
        points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
        status: json['status']?.toString() ?? 'pending',
        isApproved:
            json['is_approved'] == true || json['is_approved'] == 'true',
      );
    } catch (e) {
      print('❌ User Parsing Critical Error: $e');
      print('Dump: $json');
      // Absolute fallback to prevent crash
      return User(
        id: null,
        name: 'Parsing Error',
        phone: '000-0000-0000',
        birth: '',
        rank: 0,
        points: 0,
        status: 'error',
        isApproved: false,
      );
    }
  }

  // Convert back to Map for compatibility with existing code
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'birth': birth,
      'rank': rank,
      'points': points,
      'status': status,
      'is_approved': isApproved,
    };
  }
}
