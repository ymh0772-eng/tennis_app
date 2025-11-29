import 'package:flutter/material.dart';
import '../services/tournament_service.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final _tournamentService = TournamentService();
  bool _isLoading = false;

  // Local state for matches
  List<dynamic> _qfMatches = [];
  List<Map<String, dynamic>> _sfMatches = [];
  List<Map<String, dynamic>> _finalMatch = [];

  Future<void> _generateBracket() async {
    setState(() => _isLoading = true);
    try {
      final bracket = await _tournamentService.generateBracket();
      setState(() {
        _qfMatches = bracket['matches'];
        // Initialize SF and Final slots
        _sfMatches = [
          {'id': 5, 'p1': null, 'p2': null, 'round': '4강전'},
          {'id': 6, 'p1': null, 'p2': null, 'round': '4강전'},
        ];
        _finalMatch = [
          {'id': 7, 'p1': null, 'p2': null, 'round': '결승'},
        ];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _advanceWinner(int matchId, String winnerName) {
    setState(() {
      if (matchId <= 4) {
        // QF -> SF
        int sfIndex = (matchId - 1) ~/ 2; // 0 or 1
        bool isP1 = (matchId - 1) % 2 == 0;
        if (isP1) {
          _sfMatches[sfIndex]['p1'] = winnerName;
        } else {
          _sfMatches[sfIndex]['p2'] = winnerName;
        }
      } else if (matchId <= 6) {
        // SF -> Final
        bool isP1 = matchId == 5;
        if (isP1) {
          _finalMatch[0]['p1'] = winnerName;
        } else {
          _finalMatch[0]['p2'] = winnerName;
        }
      } else {
        // Final Winner
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('우승: $winnerName! 축하합니다!')));
      }
    });
  }

  Widget _buildMatchCard(dynamic match, bool isLocal) {
    String p1 = isLocal ? (match['p1'] ?? 'TBD') : match['player1'];
    String p2 = isLocal ? (match['p2'] ?? 'TBD') : match['player2'];
    int id = isLocal ? match['id'] : match['match_id'];

    final score1Controller = TextEditingController();
    final score2Controller = TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Match #$id (${isLocal ? match['round'] : match['round']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Text('vs'),
                Expanded(
                  child: Text(
                    p2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (p1 != 'TBD' && p2 != 'TBD') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: score1Controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: score2Controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  int s1 = int.tryParse(score1Controller.text) ?? 0;
                  int s2 = int.tryParse(score2Controller.text) ?? 0;
                  if (s1 == s2) return; // No draws in tournament
                  String winner = s1 > s2 ? p1 : p2;
                  _advanceWinner(id, winner);
                },
                child: const Text('경기 종료'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('토너먼트'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (_qfMatches.isEmpty)
                    Center(
                      child: ElevatedButton(
                        onPressed: _generateBracket,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                        ),
                        child: const Text(
                          '대진표 생성',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  else ...[
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '8강전 (Quarter-Finals)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._qfMatches.map((m) => _buildMatchCard(m, false)),

                    const Divider(thickness: 2),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '4강전 (Semi-Finals)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._sfMatches.map((m) => _buildMatchCard(m, true)),

                    const Divider(thickness: 2),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '결승 (Final)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._finalMatch.map((m) => _buildMatchCard(m, true)),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
    );
  }
}
