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
    try {
      return User(
        id: json['id'], // Can be null
        name: json['name'] ?? '이름 없음',
        phone: json['phone'] ?? '번호 없음',
        birth: json['birth']?.toString() ?? '',
        // Handle potentially null or non-integer values for rank/points
        rank: _parseInt(json['rank']) ?? 0,
        points: _parseInt(json['points']) ?? 0,
        status: json['status'] ?? 'pending',
        isApproved: json['is_approved'] == true,
      );
    } catch (e) {
      print('❌ Error parsing user data: $e');
      print('Dump: $json');
      // Return a safe fallback user object instead of crashing
      return User(
        id: null,
        name: json['name'] ?? 'ErrorUser',
        phone: json['phone'] ?? 'ErrorPhone',
        birth: '',
        rank: 0,
        points: 0,
        status: 'error',
        isApproved: false,
      );
    }
  }

  // Helper to safely parse integers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
