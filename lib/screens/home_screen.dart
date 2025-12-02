import 'package:flutter/material.dart';
import 'login_screen.dart';

import 'league_screen.dart';
import 'tournament_screen.dart';
import 'gallery_screen.dart';
import 'schedule_screen.dart';

import 'community_screen.dart';

import 'member_directory_screen.dart';

class HomeScreen extends StatelessWidget {
  final String memberName;
  final String memberRole;

  const HomeScreen({
    super.key,
    required this.memberName,
    required this.memberRole,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'title': '월례 풀리그',
        'icon': Icons.emoji_events,
        'screen': const LeagueScreen(),
      },

      {
        'title': '갤러리',
        'icon': Icons.photo_library,
        'screen': GalleryScreen(memberName: memberName),
      },
      {
        'title': '운동 약속',
        'icon': Icons.calendar_today,
        'screen': ScheduleScreen(memberName: memberName),
      },
      {
        'title': '토너먼트',
        'icon': Icons.emoji_events,
        'screen': const TournamentScreen(),
      },
      {
        'title': '커뮤니티',
        'icon': Icons.campaign,
        'screen': CommunityScreen(memberName: memberName),
      },
      {
        'title': '회원 명부',
        'icon': Icons.people_alt,
        'screen': MemberDirectoryScreen(memberRole: memberRole),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('무안 테니스 클럽'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '환영합니다, $memberName님!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => item['screen'] as Widget,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
