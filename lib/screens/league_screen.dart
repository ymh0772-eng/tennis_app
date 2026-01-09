import 'package:flutter/material.dart';
import '../services/league_service.dart';
import '../services/auth_service.dart';
import '../models/member.dart';
import 'match_history_screen.dart';
import 'league_history_screen.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  final _leagueService = LeagueService();
  final _authService = AuthService();

  List<dynamic> _rankings = [];
  List<Member> _members = [];
  Member? _currentUser;
  bool _isLoading = true;

  // Match Input State: 2vs2
  int? _teamAP1;
  int? _teamAP2;
  int? _teamBP1;
  int? _teamBP2;

  final _scoreAController = TextEditingController();
  final _scoreBController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rankings = await _leagueService.fetchRankings();
      final members = await _authService.fetchMembers(isApproved: true);
      final currentUser = await _authService.getCurrentMember();

      if (mounted) {
        setState(() {
          _rankings = rankings;
          _members = members;
          _currentUser = currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
      }
    }
  }

  Future<void> _submitMatch() async {
    // 1. Check all players selected
    if (_teamAP1 == null ||
        _teamAP2 == null ||
        _teamBP1 == null ||
        _teamBP2 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 선수를 선택해주세요 (4명)')));
      return;
    }

    // 2. Check duplicates
    final selectedIds = {_teamAP1, _teamAP2, _teamBP1, _teamBP2};
    if (selectedIds.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('중복된 선수가 있습니다. 모두 다른 선수여야 합니다.')),
      );
      return;
    }

    // 3. Check scores
    if (_scoreAController.text.isEmpty || _scoreBController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('점수를 입력해주세요')));
      return;
    }

    try {
      await _leagueService.submitMatch(
        _teamAP1!,
        _teamAP2!,
        _teamBP1!,
        _teamBP2!,
        int.parse(_scoreAController.text),
        int.parse(_scoreBController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('복식 경기 결과 등록 완료')));
        _scoreAController.clear();
        _scoreBController.clear();
        setState(() {
          _teamAP1 = null;
          _teamAP2 = null;
          _teamBP1 = null;
          _teamBP2 = null;
        });
        _loadData(); // Refresh rankings
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Widget _buildPlayerDropdown(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: _members.map<DropdownMenuItem<int>>((m) {
        return DropdownMenuItem<int>(
          value: m.id,
          child: Text(m.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('월례 풀리그 (복식)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentUser != null) // Only show if user is loaded
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MatchHistoryScreen(currentUser: _currentUser!),
                  ),
                );
              },
            ),
          // [UI 추가] 월별 명예의 전당 (기록실) 이동 버튼
          IconButton(
            icon: const Icon(Icons.emoji_events), // 트로피 아이콘
            tooltip: '월별 명예의 전당',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeagueHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top: Ranking Board
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('순위')),
                          DataColumn(label: Text('이름')),
                          DataColumn(label: Text('승점')),
                          DataColumn(label: Text('전적')),
                          DataColumn(label: Text('득실')),
                        ],
                        rows: List<DataRow>.generate(_rankings.length, (index) {
                          final member = _rankings[index];
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(member['name'])),
                              DataCell(Text('${member['rank_point']}')),
                              DataCell(
                                Text(
                                  '${member['wins']}승 ${member['losses']}패 ${member['draws']}무',
                                ),
                              ),
                              DataCell(Text('${member['game_diff']}')),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const Divider(thickness: 2),
                // Bottom: Match Input
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '경기 결과 입력 (2 vs 2)',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Team A Card
                          Card(
                            elevation: 2,
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Text(
                                    "Team A",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPlayerDropdown(
                                          "선수 1",
                                          _teamAP1,
                                          (val) =>
                                              setState(() => _teamAP1 = val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPlayerDropdown(
                                          "선수 2",
                                          _teamAP2,
                                          (val) =>
                                              setState(() => _teamAP2 = val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _scoreAController,
                                    decoration: const InputDecoration(
                                      labelText: 'Team A 점수',
                                      border: OutlineInputBorder(),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // VS Divider
                          const Center(
                            child: Text(
                              "VS",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Team B Card
                          Card(
                            elevation: 2,
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  const Text(
                                    "Team B",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPlayerDropdown(
                                          "선수 1",
                                          _teamBP1,
                                          (val) =>
                                              setState(() => _teamBP1 = val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildPlayerDropdown(
                                          "선수 2",
                                          _teamBP2,
                                          (val) =>
                                              setState(() => _teamBP2 = val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _scoreBController,
                                    decoration: const InputDecoration(
                                      labelText: 'Team B 점수',
                                      border: OutlineInputBorder(),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _submitMatch,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '결과 등록',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
