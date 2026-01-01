import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/member.dart';

class MemberDirectoryScreen extends StatefulWidget {
  final String memberRole;

  const MemberDirectoryScreen({super.key, required this.memberRole});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final _authService = AuthService();
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      // ADMIN: Fetch all (isApproved: null), Others: Fetch approved only (isApproved: true)
      final isApproved = widget.memberRole.toUpperCase() == 'ADMIN'
          ? null
          : true;
      final members = await _authService.fetchMembers(isApproved: isApproved);
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

  Future<void> _approve(String phone, {required int id}) async {
    try {
      final error = await _authService.approveMember(phone, id: id);
      if (error == null) {
        if (mounted) {
          setState(() {
            // 리스트에서 해당 회원을 찾아 상태를 'is_approved': true 로 변경
            final index = _members.indexWhere((m) {
              return m.id == id;
            });

            if (index != -1) {
              // Create new Member with updated status
              final oldMember = _members[index];
              _members[index] = Member(
                id: oldMember.id,
                name: oldMember.name,
                phone: oldMember.phone,
                birth: oldMember.birth,
                pin: oldMember.pin,
                isApproved: true,
                role: oldMember.role,
              );
            }
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('회원 승인 완료')));
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
    // Filter members based on role
    // List is already filtered by API
    final displayedMembers = List.from(_members);

    // Sort logic (unchanged or slightly adjusted if needed, currently only for ADMIN mostly)
    if (widget.memberRole.toUpperCase() == 'ADMIN') {
      displayedMembers.sort((a, b) {
        final aApproved = a.isApproved;
        final bApproved = b.isApproved;
        if (aApproved == bApproved) return 0;
        return aApproved ? 1 : -1; // Pending (false) comes first
      });
    }

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
                final isApproved = member.isApproved;

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
                        text: member.name,
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: ' (${member.birth}년생)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          if (!isApproved)
                            const TextSpan(
                              text: ' (승인 대기)',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    subtitle: Text('${member.phone}'),
                    trailing: widget.memberRole.toUpperCase() == 'ADMIN'
                        ? (isApproved
                              ? const Text(
                                  '정회원',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () =>
                                      _approve(member.phone, id: member.id),
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
