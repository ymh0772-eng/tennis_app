class MatchRecord {
  final int id;
  final String date;
  final String teamANames;
  final String teamBNames;
  final int scoreA;
  final int scoreB;

  MatchRecord({
    required this.id,
    required this.date,
    required this.teamANames,
    required this.teamBNames,
    required this.scoreA,
    required this.scoreB,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    // Helper to safely join player names if they exist in nested objects
    // Assuming backend returns:
    // team_a_player1: {name: "A"}, team_a_player2: {name: "B"} ...
    // OR names are directly provided. The prompt says "teamANames (String)".
    // If the prompt implies the field is ALREADY a string in the expected model,
    // but the backend might still be sending the old structure, I need to be careful.
    // Previous context showed complex mapping.
    // The prompt says: "Fields: ... teamANames (String)... Map the JSON fields correctly."
    // I will assume the backend structure hasn't changed from the previous success:
    // team_a_player1['name'] etc.

    String joinNames(dynamic p1, dynamic p2) {
      String n1 = (p1 != null && p1['name'] != null)
          ? p1['name'].toString()
          : 'Unknown';
      String n2 = (p2 != null && p2['name'] != null)
          ? p2['name'].toString()
          : 'Unknown';
      return "$n1, $n2";
    }

    // Check if the backend is already sending combined names or if I need to combine them.
    // To be safe, I'll try to use 'team_a_names' if it exists, otherwise combine player names.
    // Based on previous logs, it was 'team_a_player1', etc.

    String tA = '';
    if (json['team_a_names'] != null) {
      tA = json['team_a_names'].toString();
    } else if (json['team_a_player1'] != null) {
      tA = joinNames(json['team_a_player1'], json['team_a_player2']);
    }

    String tB = '';
    if (json['team_b_names'] != null) {
      tB = json['team_b_names'].toString();
    } else if (json['team_b_player1'] != null) {
      tB = joinNames(json['team_b_player1'], json['team_b_player2']);
    }

    return MatchRecord(
      id: json['id'],
      date: json['created_at']?.toString() ?? '',
      teamANames: tA,
      teamBNames: tB,
      scoreA: json['score_team_a'] ?? 0,
      scoreB: json['score_team_b'] ?? 0,
    );
  }
}
