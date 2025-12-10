import 'dart:async';
import 'package:adbeaver/login.dart';
import 'package:adbeaver/services/email_verification_service.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({Key? key}) : super(key: key);

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailService = EmailVerificationService();

  bool _isSendingCode = false;
  bool _isResetting = false;
  bool _isCodeSent = false;
  bool _isCodeVerified = false;
  bool _hasRequestedCode = false;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isVerifyingCode = false;

  Timer? _codeTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _codeTimer?.cancel();
    super.dispose();
  }

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

  void _showSnack(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF2972C7) : null,
      ),
    );
  }

  void _startTimer({int seconds = 300}) {
    _codeTimer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });

    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack('이메일을 입력해주세요.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('이메일 형식이 올바르지 않습니다.');
      return;
    }
    setState(() {
      _isSendingCode = true;
    });
    try {
      await _emailService.sendResetPasswordCode(email);
      if(!mounted) return;
      setState(() {
        _isSendingCode = false;
        _isCodeSent = true;
        _hasRequestedCode =true;
      });
      _startTimer();
      _showSnack('인증 코드가 이메일로 전송되었습니다.', isSuccess: true);
    }on DioException catch (e) {
      if(!mounted) return;
      setState(() {
        _isSendingCode = false;
        _isCodeSent = false;
        _hasRequestedCode = false;
      });
      _showSnack('해당 이메일의 사용자를 찾을 수 없습니다 ');
    }catch(e){
      if(!mounted) return;
      print('❌ [find_password/_sendCode] Unknown error: $e');
      setState(() {
        _isSendingCode = false;
        _isCodeSent = false;
        _hasRequestedCode = false;
      });
      _showSnack('인증 코드 전송에 실패하였습니다.');
    }
  }

  void _verifyCodeUI() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty) {
      _showSnack('이메일을 먼저 입력해주세요.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('이메일 형식이 올바르지 않습니다.');
      return;
    }

    if (code.isEmpty) {
      _showSnack('인증 코드를 입력해주세요.');
      return;
    }
    if (_secondsLeft <= 0) {
      _showSnack('인증 시간이 만료되었습니다. 다시 요청해주세요.');
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    final ok = await _emailService.verifyCode(
        email: email,
        code: code,
    );

    if(!mounted) return;
    setState(() {
      _isVerifyingCode =false;
    });

    if (ok) {
      setState(() {
        _isCodeVerified = true;
        _secondsLeft =0;
      });
      _codeTimer?.cancel();
      _showSnack('이메일 인증 성공', isSuccess: true);
    }else {
      _showSnack("인증번호가 틀리거나 만료되었습니다.");
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isCodeVerified) {
      _showSnack('먼저 이메일 인증을 완료해주세요.');
      return;
    }

    if (email.isEmpty ||
        code.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack('모든 칸을 입력해주세요.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('이메일 형식이 올바르지 않습니다.');
      return;
    }
    if (!_isValidPassword(newPassword)) {
      _showSnack('비밀번호는 8자 이상이며, 숫자, 영문 대소문자, 특수문자를 모두 포함해야 합니다.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnack('새 비밀번호가 서로 일치하지 않습니다.');
      return;
    }

    setState(() => _isResetting = true);
    final result = await _emailService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    setState(() => _isResetting = false);

    _showSnack(result);

    if (result.contains('성공')) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildSlimTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
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
              hintText: hintText ?? '$label 입력',
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "계정을 잊으셨나요?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "이메일 인증을 통해 비밀번호를 재설정합니다.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "이메일",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: _emailController,
                              enabled: !_isCodeVerified,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '가입한 이메일 입력',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 12),
                                filled: true,
                                fillColor: _isCodeVerified
                                    ? Colors.grey[200]
                                    : Colors.grey[50],
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2972C7), width: 1.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_isSendingCode || _isCodeVerified)
                                ? null
                                : _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2972C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                    _hasRequestedCode ? '재요청' : '인증 요청',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (_isCodeSent) ...[
                  const SizedBox(height: 24),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "인증 코드",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (!_isCodeVerified && _secondsLeft > 0)
                        Text(
                          _formatTime(_secondsLeft),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextFormField(
                            controller: _codeController,
                            enabled: !_isCodeVerified,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '6자리 인증 코드 입력',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                              filled: true,
                              fillColor: _isCodeVerified
                                  ? Colors.grey[200]
                                  : Colors.grey[50],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2972C7), width: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: (_isCodeVerified || _isVerifyingCode)
                              ? null
                              : _verifyCodeUI,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isCodeVerified
                                  ? Colors.grey
                                  : const Color(0xFF2972C7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                          ),
                          child: _isVerifyingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isCodeVerified ? '인증완료' : '확인',
                                  style: TextStyle(
                                    color: _isCodeVerified
                                        ? Colors.grey
                                        : const Color(0xFF2972C7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  if (_isCodeVerified) ...[
                    const SizedBox(height: 24),
                    const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 24),

                    _buildSlimTextField(
                      label: "새 비밀번호",
                      controller: _newPasswordController,
                      hintText: "영문, 숫자, 특수문자 포함 8자 이상",
                      isPassword: true,
                      isObscure: _obscureNewPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildSlimTextField(
                      label: "새 비밀번호 확인",
                      controller: _confirmPasswordController,
                      hintText: "비밀번호 재입력",
                      isPassword: true,
                      isObscure: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isResetting ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2972C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isResetting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '비밀번호 변경',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
