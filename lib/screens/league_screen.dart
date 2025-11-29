import 'package:flutter/material.dart';
import '../services/league_service.dart';
import '../services/auth_service.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  final _leagueService = LeagueService();
  final _authService = AuthService();

  List<dynamic> _rankings = [];
  List<dynamic> _members = [];
  bool _isLoading = true;

  // Match Input State
  int? _selectedPlayer1;
  int? _selectedPlayer2;
  final _score1Controller = TextEditingController();
  final _score2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rankings = await _leagueService.fetchRankings();
      final members = await _authService.fetchMembers();
      setState(() {
        _rankings = rankings;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
      }
    }
  }

  Future<void> _submitMatch() async {
    if (_selectedPlayer1 == null || _selectedPlayer2 == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선수를 선택해주세요')));
      return;
    }
    if (_selectedPlayer1 == _selectedPlayer2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('동일한 선수를 선택할 수 없습니다')));
      return;
    }
    if (_score1Controller.text.isEmpty || _score2Controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('점수를 입력해주세요')));
      return;
    }

    try {
      await _leagueService.submitMatch(
        _selectedPlayer1!,
        _selectedPlayer2!,
        int.parse(_score1Controller.text),
        int.parse(_score2Controller.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('경기 결과 등록 완료')));
        _score1Controller.clear();
        _score2Controller.clear();
        setState(() {
          _selectedPlayer1 = null;
          _selectedPlayer2 = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('월례 풀리그'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top: Ranking Board
                Expanded(
                  flex: 1,
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
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '경기 결과 입력',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  value: _selectedPlayer1,
                                  decoration: const InputDecoration(
                                    labelText: 'Player A',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _members.map<DropdownMenuItem<int>>((
                                    m,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: m['id'],
                                      child: Text(
                                        m['name'],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedPlayer1 = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  value: _selectedPlayer2,
                                  decoration: const InputDecoration(
                                    labelText: 'Player B',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _members.map<DropdownMenuItem<int>>((
                                    m,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: m['id'],
                                      child: Text(
                                        m['name'],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedPlayer2 = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _score1Controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Score A',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _score2Controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Score B',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
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
                          const SizedBox(height: 32), // Extra padding at bottom
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
