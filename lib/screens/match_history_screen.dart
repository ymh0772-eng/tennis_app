import 'package:flutter/material.dart';
import '../models/match_record.dart';
import '../services/match_service.dart';
import '../models/member.dart';

class MatchHistoryScreen extends StatefulWidget {
  final Member currentUser;

  const MatchHistoryScreen({super.key, required this.currentUser});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final _matchService = MatchService();
  late Future<List<MatchRecord>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _matchService.getMatches();
  }

  void _refreshMatches() {
    setState(() {
      _matchesFuture = _matchService.getMatches();
    });
  }

  Future<void> _deleteMatch(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경기 삭제 확인'),
        content: const Text('정말 삭제하시겠습니까? 점수가 되돌려집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _matchService.deleteMatch(id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('경기가 삭제되었습니다.')));
          _refreshMatches();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is admin
    final isAdmin = widget.currentUser.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 기록'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MatchRecord>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('기록된 경기가 없습니다.'));
          }

          // Descending Order (Assuming backend sort, or reverse here)
          final matches = snapshot.data!.reversed.toList();

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    '${match.teamANames} vs ${match.teamBNames}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '점수: ${match.scoreA} : ${match.scoreB} | 날짜: ${match.date}',
                  ),
                  trailing: isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMatch(match.id),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
