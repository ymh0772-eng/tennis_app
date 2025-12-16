import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'approval_waiting_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;

  // Controllers
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();

  String _formatPhoneNumber(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7, 11)}';
    }
    // Fallback or other lengths if needed, but 010 is usually 11
    return raw;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final formattedPhone = _formatPhoneNumber(_phoneController.text);

    try {
      if (_isLogin) {
        print(
          'DEBUG: Attempting login with phone: $formattedPhone, pin: ${_pinController.text}',
        );
        final member = await _authService.login(
          formattedPhone,
          _pinController.text,
        );
        if (mounted) {
          if (member['is_approved'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('환영합니다, ${member['name']}님!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  memberName: member['name'],
                  memberRole: member['role'],
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ApprovalWaitingScreen(),
              ),
            );
          }
        }
      } else {
        await _authService.register(
          _nameController.text,
          formattedPhone,
          _birthController.text,
          _pinController.text,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ApprovalWaitingScreen(),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.statusCode == 403 || e.message.contains('승인 대기')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApprovalWaitingScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sports_tennis,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '무안 테니스 클럽',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),

                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '이름',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? '이름을 입력해주세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birthController,
                    decoration: const InputDecoration(
                      labelText: '출생년도 (YYYY)',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.length != 4 ? '4자리 연도를 입력해주세요' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: '010-1234-5678',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? '전화번호를 입력해주세요' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 (4자리)',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  validator: (value) =>
                      value!.length != 4 ? '4자리를 입력해주세요' : null,
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? '로그인' : '회원가입',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? '신규 회원이신가요? 회원가입하기' : '이미 계정이 있으신가요? 로그인하기',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
