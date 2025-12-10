import 'dart:async';

import 'package:adbeaver/login.dart';
import 'package:adbeaver/services/email_verification_service.dart';
import 'package:adbeaver/services/kakao.dart';
import 'package:adbeaver/services/naver.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adbeaver/mainboard.dart';
import 'package:adbeaver/services/service.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: const SignupForm(),
    );
  }
}

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final EmailVerificationService _emailService = EmailVerificationService();
  bool _isEmailVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isRegistering = false;

  Timer? _codeTimer;
  int _secondsLeft = 0;
  bool _hasRequestedCode = false;

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[0-9])(?=.*[a-z])(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _codeTimer?.cancel();
    super.dispose();
  }

  final KakaoLoginService kakaoLogin = KakaoLoginService();
  bool isKakaoLogined = false;
  User? user;

  void _startCodeTimer({int seconds = 300}) {
    _codeTimer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });

    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft -= 1;
        });
      }
    });
  }

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> handleKakaoLogin() async {
    bool loginResult = await kakaoLogin.kakaoLogin();
    if (!loginResult) {
      _showErrorSnackBar("카카오 로그인 실패");
      return;
    }

    try {
      User kakaoUser = await UserApi.instance.me();

      String? kakaoNickname = kakaoUser.kakaoAccount?.profile?.nickname;
      String? kakaoName = kakaoUser.kakaoAccount?.name;
      String? email = kakaoUser.kakaoAccount?.email;

      final String finalNickname = kakaoNickname ?? "카카오닉네임";
      final String finalName = kakaoName ?? "카카오사용자";

      if (email == null) {
        _showErrorSnackBar(
          "카카오 계정에서 이메일 정보를 가져오지 못했습니다.\n카카오 계정 설정에서 이메일 제공 동의를 확인해주세요.",
        );
        return;
      }

      Map<String, dynamic>? userFromDb;
      try {
        userFromDb = await kakaoLoginApi(email);
      } catch (e) {
        _showErrorSnackBar("서버 통신 중 오류가 발생했습니다.");
        return;
      }

      if (userFromDb == null) {
        String result = await registerUser(
          finalName,
          finalNickname,
          email,
          "kakao${kakaoUser.id}",
        );
        if (result != '성공') {
          _showErrorSnackBar(result);
          return;
        }

        userFromDb = await kakaoLoginApi(email);
        if (userFromDb == null) {
          _showErrorSnackBar("카카오 회원 정보를 불러오지 못했습니다.");
          return;
        }
      }

      final userProvider = context.read<UserProvider>();
      await userProvider.setUser(
        userFromDb['user_id'] as int,
        userFromDb['username'] as String,
        userFromDb['nickname'] as String?,
        userFromDb['email'] as String?,
        userFromDb['bid'] as int,
        userFromDb['money'] as int,
        userFromDb['signup_bonus_claimed'] as bool,
      );

      if (!mounted) return;
      _navigateToMain();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("카카오 로그인 완료!"),
          backgroundColor: Color(0xFF2972C7),
        ),
      );
    } catch (e) {
      print("카카오 유저 정보 처리 중 오류: $e");
      _showErrorSnackBar("계정 처리 중 오류가 발생했습니다.");
    }
  }

  final NaverLoginService naverService = NaverLoginService();

  Future<void> handleNaverLogin() async {
    final NaverAccountResult? account = await naverService.buttonLoginPressed();

    if (account == null) {
      _showErrorSnackBar("네이버 로그인에 실패했습니다.");
      return;
    }

    String userName = account.name ?? "네이버 사용자";
    String? userEmail = account.email;
    String nickname = account.nickname ?? userName;

    if (userEmail == null) {
      _showErrorSnackBar(
        "네이버 계정에서 이메일 정보를 가져오지 못했습니다.\n네이버 계정 설정에서 이메일 제공 동의를 확인해주세요.",
      );
      return;
    }

    Map<String, dynamic>? userFromDb;
    try {
      userFromDb = await naverLoginApi(userEmail);
    } catch (e) {
      _showErrorSnackBar("서버 통신 중 오류가 발생했습니다.");
      return;
    }

    if (userFromDb == null) {
      final dummyPassword = "naver_${DateTime.now().millisecondsSinceEpoch}";
      String result = await registerUser(
        userName,
        nickname,
        userEmail,
        dummyPassword,
      );

      if (result != '성공') {
        _showErrorSnackBar(result);
        return;
      }

      userFromDb = await naverLoginApi(userEmail);
      if (userFromDb == null) {
        _showErrorSnackBar("네이버 회원 정보를 불러오지 못했습니다.");
        return;
      }
    }

    final userProvider = context.read<UserProvider>();
    await userProvider.setUser(
      userFromDb['user_id'] as int,
      userFromDb['username'] as String,
      userFromDb['nickname'] as String?,
      userFromDb['email'] as String?,
      userFromDb['bid'] as int,
      userFromDb['money'] as int,
      userFromDb['signup_bonus_claimed'] as bool,
    );

    if (!mounted) return;
    _navigateToMain();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("네이버 로그인 완료!"),
        backgroundColor: Color(0xFF2972C7),
      ),
    );
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar("이메일을 입력해주세요.");
      return;
    }
    if (!_isValidEmail(email)) {
      _showErrorSnackBar('이메일 형식이 올바르지 않습니다.');
      return;
    }
    setState(() {
      _isSendingCode = true;
    });
    try {
      await _emailService.sendCode(email);

      setState(() {
        _hasRequestedCode = true;
      });
      _startCodeTimer();

      _showErrorSnackBar('인증번호가 이메일로 전송되었습니다.');
    } catch (error) {
      print(" 인증번호 전송 실패: $error");
      _showErrorSnackBar('인증번호 전송에 실패하였습니다.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  Future<void> _handleVerifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      _showErrorSnackBar('이메일과 인증번호를 모두 입력해주세요.');
      return;
    }

    if (_secondsLeft <= 0) {
      _showErrorSnackBar('인증 유효 시간이 만료되었습니다. 다시 요청해주세요.');
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    final ok = await _emailService.verifyCode(email: email, code: code);

    if (!mounted) return;
    setState(() {
      _isVerifyingCode = false;
    });

    if (ok) {
      setState(() {
        _isEmailVerified = true;
        _secondsLeft = 0;
      });
      _codeTimer?.cancel();
      _showErrorSnackBar('이메일 인증이 완료되었습니다 ✅');
    } else {
      _showErrorSnackBar('인증번호가 틀렸거나 만료되었습니다.');
    }
  }

  Future logout() async {
    await kakaoLogin.kakaoLogout();
    isKakaoLogined = false;
    user = null;
  }

  void _register() async {
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (name.isEmpty ||
        nickname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showErrorSnackBar('모든 정보를 입력해주세요.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showErrorSnackBar('이메일 형식이 올바르지 않습니다.');
      return;
    }
    if (!_isValidPassword(password)) {
      _showErrorSnackBar('비밀번호는 8자 이상이며, 숫자, 영문 대소문자, 특수문자를 모두 포함해야 합니다.');
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (!_isEmailVerified) {
      _showErrorSnackBar('이메일 인증을 먼저 완료해주세요.');
      return;
    }
    setState(() {
      _isRegistering = true;
    });

    String result = await registerUser(
      name,
      nickname,
      email,
      password,
    );

    if (!mounted) return;

    if (result != '성공') {
      setState(() {
        _isRegistering = false;
      });
      _showErrorSnackBar(result);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입 성공! 광고주님 환영합니다.'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF2972C7),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() {
      _isRegistering = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainBoardForm()),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSlimTextField({
    required TextEditingController controller,
    String? placeholder,
    bool isPassword = false,
    bool? isObscure,
    VoidCallback? onToggleVisibility,
    TextInputType inputType = TextInputType.text,
  }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        obscureText: isObscure ?? false,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: placeholder,
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
            borderSide: const BorderSide(color: Color(0xFF2972C7), width: 1.2),
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
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "매출 상승의 첫 걸음,\n애드비버와 함께하세요.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("이름(본명)"),
              _buildSlimTextField(
                controller: _nameController,
                placeholder: "실명을 입력해주세요",
              ),
              const SizedBox(height: 16),

              _buildLabel("닉네임"),
              _buildSlimTextField(
                controller: _nicknameController,
                placeholder: "사용하실 닉네임을 입력해주세요",
              ),
              const SizedBox(height: 16),

              _buildLabel("이메일 (아이디)"),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSlimTextField(
                      controller: _emailController,
                      placeholder: "example@email.com",
                      inputType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSendingCode ? null : _handleSendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2972C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _hasRequestedCode ? "재요청" : "인증요청",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel("인증번호"),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSlimTextField(
                      controller: _codeController,
                      placeholder: "인증번호 6자리",
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isVerifyingCode ? null : _handleVerifyCode,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2972C7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isVerifyingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2972C7),
                              ),
                            )
                          : const Text(
                              "확인",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2972C7),
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              if (_secondsLeft > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        "남은 시간 ${_formatSeconds(_secondsLeft)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "인증이 완료되었습니다.",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              _buildLabel("비밀번호"),
              _buildSlimTextField(
                controller: _passwordController,
                placeholder: "영문, 숫자, 특수문자 포함 8자 이상",
                isPassword: true,
                isObscure: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 16),

              _buildLabel("비밀번호 확인"),
              _buildSlimTextField(
                controller: _confirmPasswordController,
                placeholder: "비밀번호 재입력",
                isPassword: true,
                isObscure: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (!_isEmailVerified || _isRegistering) ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2972C7),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "가입하기",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
                      "간편 회원가입",
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialLoginBtn(String assetPath, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
      ),
    );
  }
}
