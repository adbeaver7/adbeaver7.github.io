import 'package:adbeaver/services/ad_provider.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:adbeaver/wait.dart';
import 'package:flutter/material.dart';
import 'package:adbeaver/signup.dart';
import 'package:adbeaver/login.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:adbeaver/error_space.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  KakaoSdk.init(
    nativeAppKey: '32dab713d411d882ecefa59843151c3c',
    javaScriptAppKey: '3489f585029383fd25c82684f037f25e',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdCreationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AdBeaverScreen(),
    ),
  );
}

class AdBeaverScreen extends StatelessWidget {
  const AdBeaverScreen({super.key});

  static const double _minWidth = 500;
  static const double _minHeight = 600;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final size = mediaQuery.size;

        final bool isEnoughSize =
            size.width >= _minWidth && size.height >= _minHeight;

        final baseChild = child ?? const SizedBox.shrink();

        if (kIsWeb && !isEnoughSize) {
          return Stack(
            children: [
              baseChild,
              const ErrorSpaceScreen(
                minWidth: _minWidth,
                minHeight: _minHeight,
              ),
            ],
          );
        }

        return baseChild;
      },
      home: const WaitScreen(),
    );
  }
}

class AdBeaverForm extends StatelessWidget {
  const AdBeaverForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/title.png",
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 220,
                        child: Image.asset(
                          "assets/images/adbeaver.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginForm(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2972C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupForm(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2972C7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFF2972C7),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}