import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MemberDirectoryScreen extends StatefulWidget {
  final String memberRole;

  const MemberDirectoryScreen({super.key, required this.memberRole});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final _authService = AuthService();
  List<dynamic> _members = [];
  List<dynamic> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMembers(),
      if (widget.memberRole == 'admin') _loadPendingUsers(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _authService.fetchMembers();
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _loadPendingUsers() async {
    try {
      final pending = await _authService.fetchPendingUsers();
      if (mounted) {
        setState(() {
          _pendingUsers = pending;
        });
      }
    } catch (e) {
      print('Error loading pending users: $e');
    }
  }

  // ✅ [수정] 승인 버튼 핸들러 (UI 즉시 갱신 포함)
  Future<void> _handleApprove(String phone, String name) async {
    // 1. API 호출
    bool success = await _authService.approveMember(phone);

    if (success) {
      // 2. 성공 시 UI 상태 즉시 변경 (리로드 없이 반영)
      setState(() {
        // 대기 목록에서 찾기
        final index = _pendingUsers.indexWhere((m) => m['phone'] == phone);
        if (index != -1) {
          // 대기 목록에서 제거 후 정회원 목록으로 이동
          var approvedMember = _pendingUsers.removeAt(index);

          // (옵션) UI 표시용 상태 업데이트
          if (approvedMember is Map) {
            approvedMember['is_approved'] = true;
          }

          _members.add(approvedMember);
        }
      });

      // 3. 피드백 메시지
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name 님을 정회원으로 승인했습니다.')));
      }
    } else {
      // 4. 실패 메시지
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('승인 실패. 서버 로그를 확인하세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter members based on role
    final displayedMembers = widget.memberRole == 'admin'
        ? _members
        : _members.where((m) => m['is_approved'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 명부'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  if (widget.memberRole == 'admin' && _pendingUsers.isNotEmpty)
                    _buildPendingUserWidget(),
                  if (widget.memberRole == 'admin' && _pendingUsers.isNotEmpty)
                    const Divider(
                      thickness: 8,
                      color: Colors.grey,
                    ), // Separator
                  ...displayedMembers.map((member) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: RichText(
                          text: TextSpan(
                            text: member['name'],
                            style: DefaultTextStyle.of(context).style.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: ' (${member['birth']}년생)',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          '${member['phone']} | 랭킹: ${member['rank_point'] ?? 0}점',
                        ),
                        trailing: widget.memberRole == 'admin'
                            ? member['is_approved'] == true
                                  ? const Text(
                                      '정회원',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : InkWell(
                                      onTap: () => _handleApprove(
                                        member['phone'],
                                        member['name'],
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          '승인 대기 [터치하여 승인]',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingUserWidget() {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '가입 대기자 목록',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 8),
          ..._pendingUsers.map(
            (user) => Card(
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.orange),
                title: Text('${user['name']} (${user['birth']})'),
                subtitle: Text(user['phone']),
                trailing: ElevatedButton(
                  onPressed: () => _handleApprove(user['phone'], user['name']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('승인'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
