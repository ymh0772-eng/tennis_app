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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _authService.fetchMembers();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve(String phone, {int? id}) async {
    print('DEBUG: 승인 요청하려는 회원 - Phone: $phone, ID: $id');
    try {
      final error = await _authService.approveMember(phone, id: id);
      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원 승인 완료')));
          _loadMembers(); // Refresh list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
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
    // Filter members based on role
    final displayedMembers = widget.memberRole == 'ADMIN'
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
          : ListView.builder(
              itemCount: displayedMembers.length,
              itemBuilder: (context, index) {
                final member = displayedMembers[index];
                final isApproved = member['is_approved'] == true;

                // Only Admin sees unapproved members, so this check is mainly for Admin view
                // For regular users, isApproved is always true due to filter above.

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
                    trailing: widget.memberRole == 'ADMIN'
                        ? (isApproved
                              ? const Text(
                                  '정회원',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _approve(
                                    member['phone'],
                                    id: member['id'],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('승인하기'),
                                ))
                        : null, // Regular users don't see any trailing button/status
                  ),
                );
              },
            ),
    );
  }
}
