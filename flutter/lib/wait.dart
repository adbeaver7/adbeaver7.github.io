
import 'package:adbeaver/login.dart';
import 'package:adbeaver/main.dart';
import 'package:adbeaver/mainboard.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class WaitScreen extends StatefulWidget {
  const WaitScreen({super.key});

  @override
  State<WaitScreen> createState() => _WaitScreenState();
}

class _WaitScreenState extends State<WaitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    final userProvider = context.read<UserProvider>();
    try {
       await userProvider.loadUserFromStorage();
     } catch (e) {
       print('🔴 loadUserFromStorage 에러: $e');
     }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (userProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainBoardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdBeaverForm()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              'AdBeaver',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
