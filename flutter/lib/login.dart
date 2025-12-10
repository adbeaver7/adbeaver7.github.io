import 'dart:convert';
import 'package:adbeaver/find_password.dart';
import 'package:adbeaver/services/naver.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:provider/provider.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:adbeaver/services/kakao.dart';
import 'package:adbeaver/services/service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'mainboard.dart';
import 'package:adbeaver/signup.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: const LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _loginAction() async {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
        );
        return;
      }

      String result = await loginUser(
        context,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result == '로그인성공') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 성공!'),
            backgroundColor: Color(0xFF2972C7),
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainBoardForm()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  final KakaoLoginService kakaoLogin = KakaoLoginService();
  bool isKakaoLogined = false;
  User? user;

  Future<void> handleKakaoLogin() async {
    bool logged = await kakaoLogin.kakaoLogin();
    if (!logged) {
      _showErrorSnackBar("카카오 로그인 실패");
      return;
    }

    User kakaoUser = await UserApi.instance.me();
    final email = kakaoUser.kakaoAccount?.email;

    if (email == null) {
      _showErrorSnackBar("카카오 계정에 이메일 제공 동의가 필요합니다.");
      return;
    }

    String result = await kakaoLoginUser(context, email);

    if (result == "로그인성공") {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그인 성공!'),
        backgroundColor: Color(0xFF2972C7),
        duration: Duration(seconds: 1),
      ),);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainBoardForm()),
      );
    } else if (result == "회원가입필요") {
      _showErrorSnackBar("회원가입이 필요합니다.\n카카오 회원가입을 진행해주세요.");
    } else {
      _showErrorSnackBar(result);
    }
  }

  final NaverLoginService naverService = NaverLoginService();

  Future<void> handleNaverLogin() async {
    print("🔵 네이버 로그인 버튼 클릭");

    final NaverAccountResult? account = await naverService.buttonLoginPressed();

    if (account == null) {
      _showErrorSnackBar("네이버 로그인에 실패했습니다.");
      return;
    }

    final email = account.email;
    final name = account.name ?? "네이버 사용자";

    if (email == null) {
      _showErrorSnackBar("네이버 계정에 이메일 제공 동의가 필요합니다.");
      return;
    }


    final userFromDb = await naverLoginApi(email);
    if (userFromDb == null) {
      _showErrorSnackBar("회원가입이 필요합니다.\n네이버로 회원가입을 먼저 진행해주세요.");
      return;
    }

    final userProvider = context.read<UserProvider>();
    await userProvider.setUser(
      userFromDb['user_id'] as int,
      userFromDb['username'] as String,
      userFromDb['nickname'] as String,
      userFromDb['email'] as String?,
      userFromDb['bid'] as int,
      userFromDb['money'] as int,
      userFromDb['signup_bonus_claimed'] as bool,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('로그인 성공!'),
      backgroundColor: Color(0xFF2972C7),
      duration: Duration(seconds: 1),
    ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainBoardForm()),
    );
  }


  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }


  Widget _buildSlimTextField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool? isObscure,
    VoidCallback? onToggleVisibility,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: controller,
            obscureText: isObscure ?? false,
            keyboardType: inputType,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '$label 입력',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: Colors.grey[50],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide:
                    const BorderSide(color: Color(0xFF2972C7), width: 1.2),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isObscure!
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "광고주님 환영합니다.",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "오늘의 광고 성과를 확인해보세요.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                _buildSlimTextField(
                  label: "이메일",
                  controller: _emailController,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                _buildSlimTextField(
                  label: "비밀번호",
                  controller: _passwordController,
                  isPassword: true,
                  isObscure: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FindPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text(
                        "비밀번호를 잊으셨나요?",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24.0),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loginAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2972C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text(
                      "로그인",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "SNS 계정으로 로그인",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialLoginBtn(
                        "assets/images/kakao_login.png",
                        onTap: handleKakaoLogin,
                    ),
                    const SizedBox(width: 16),
                    _socialLoginBtn(
                        "assets/images/naver_login.png",
                    onTap: handleNaverLogin,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "아직 계정이 없으신가요? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        "회원가입",
                        style: TextStyle(
                          color: Color(0xFF2972C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialLoginBtn(String assetPath, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage(assetPath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 2),
              )
            ]),
      ),
    );
  }
}