import 'dart:async';
import 'package:adbeaver/login.dart';
import 'package:adbeaver/services/email_verification_service.dart';
import 'package:adbeaver/services/service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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

  bool _isKumohEmail(String email) {
    return email.toLowerCase().endsWith('@kumoh.ac.kr');
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
    if (!_isKumohEmail(email)) {
      _showErrorSnackBar('금오공대 이메일(@kumoh.ac.kr)만 인증할 수 있습니다.');
      return;
    }
    if (_isEmailVerified) {
      _showErrorSnackBar('이미 이메일이 인증이 완료되었습니다');
      return;
    }
    setState(() {
      _isSendingCode = true;
    });
    try {
      await _emailService.sendSignupCode(email);

      setState(() {
        _hasRequestedCode = true;
      });
      _startCodeTimer();

      _showErrorSnackBar('인증번호가 이메일로 전송되었습니다.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      print(
          '❌ [signup/_handleSendCode] DioException: status=$status, data=$data, type=${e.type}, message=${e.message}');

      final serverMessage = (data is String) ? data : null;
      _showErrorSnackBar(
        serverMessage ??
            '인증번호 전송 실패 (status: ${status ?? '알 수 없음'})',
      );
    } catch (error) {
      print('❌ [signup/_handleSendCode] Unknown error: $error');
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
    if (name.length > 5) {
      _showErrorSnackBar('이름은 5자 이내로 입력해주세요.');
      return;
    }
    if (nickname.length > 10) {
      _showErrorSnackBar('닉네임은 10자 이내로 입력해주세요.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('이메일 형식이 올바르지 않습니다.');
      return;
    }
    if (!_isKumohEmail(email)) {
      _showErrorSnackBar('금오공대 이메일(@kumoh.ac.kr)만 회원가입에 사용할 수 있습니다.');
      return;
    }
    if (!_isValidPassword(password)) {
      _showErrorSnackBar('비밀번호는 8자 이상이며, 숫자, 영문 소문자, 특수문자를 모두 포함해야 합니다.');
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
        content: Text('회원가입 성공! 광고주님 환영합니다! 🎉'),
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSlimTextField({
    required TextEditingController controller,
    int? maxLength,
    String? placeholder,
    bool isPassword = false,
    bool? isObscure,
    VoidCallback? onToggleVisibility,
    TextInputType inputType = TextInputType.text,
    bool enabled = true,
    Color? fillColor,
  }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: isObscure ?? false,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14),
        inputFormatters: maxLength != null
            ? [LengthLimitingTextInputFormatter(maxLength)]
            : null,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          filled: true,
          fillColor: fillColor ?? Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide:
                const BorderSide(color: Color(0xFF2972C7), width: 1.2),
          ),
          counterText: "",
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
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
              _buildLabel("이름"),
              _buildSlimTextField(
                controller: _nameController,
                placeholder: "이름을 입력해주세요",
                maxLength: 5,
              ),
              const SizedBox(height: 16),
              _buildLabel("닉네임"),
              _buildSlimTextField(
                controller: _nicknameController,
                placeholder: "사용하실 닉네임을 입력해주세요",
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              _buildLabel("이메일 (아이디)"),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSlimTextField(
                      controller: _emailController,
                      placeholder: "example@kumoh.ac.kr",
                      inputType: TextInputType.emailAddress,
                      enabled: !_isEmailVerified,
                      fillColor:
                          _isEmailVerified ? Colors.grey[200] : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSendingCode || _isEmailVerified)
                          ? null
                          : _handleSendCode,
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
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  "금오공대 이메일(@kumoh.ac.kr)로만 인증 및 회원가입이 가능합니다.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
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
                      enabled: !_isEmailVerified,
                      fillColor:
                          _isEmailVerified ? Colors.grey[200] : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: (_isVerifyingCode || _isEmailVerified)
                          ? null
                          : _handleVerifyCode,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isEmailVerified
                              ? Colors.grey
                              : const Color(0xFF2972C7),
                        ),
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
                          : Text(
                              _isEmailVerified ? "인증완료" : "확인",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isEmailVerified
                                    ? Colors.grey
                                    : const Color(0xFF2972C7),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  }
}