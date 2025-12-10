import 'package:adbeaver/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class EmailVerificationService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ServerConfig.springBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<void> sendSignupCode(String email) async {
    debugPrint('[sendCode] baseUrl = ${ServerConfig.springBaseUrl}');
    try {
      final response = await _dio.post(
        '/api/auth/email/send-code/signup',
        data: {'email': email},
      );
      debugPrint('응답: status=${response.statusCode}, data=${response.data}');
    } on DioException catch(e, st){
      debugPrint(' [sendCode] DioException 발생');
      debugPrint('  - type: ${e.type}');
      debugPrint('  - message: ${e.message}');
      debugPrint('  - status: ${e.response?.statusCode}');
      debugPrint('  - data: ${e.response?.data}');
      debugPrint('  - stacktrace: $st');
      rethrow; // 화면 쪽에서 잡도록 그대로 던짐
    } catch (e, st){
      debugPrint(' [sendCode] 알 수 없는 예외: $e');
      debugPrint('  - stacktrace: $st');
      rethrow;
    }
  }

  Future<void> sendResetPasswordCode(String email) async {
      debugPrint(' [sendCode] baseUrl = ${ServerConfig.springBaseUrl}');
      try {
        final response = await _dio.post(
          '/api/auth/email/send-code/reset-password',
          data: {'email': email},
        );
        debugPrint('응답: status=${response.statusCode}, data=${response.data}');
      } on DioException catch(e, st){
        debugPrint(' [sendCode] DioException 발생');
        debugPrint('  - type: ${e.type}');
        debugPrint('  - message: ${e.message}');
        debugPrint('  - status: ${e.response?.statusCode}');
        debugPrint('  - data: ${e.response?.data}');
        debugPrint('  - stacktrace: $st');
        rethrow;
      } catch (e, st){
        debugPrint(' [sendCode] 알 수 없는 예외: $e');
        debugPrint('  - stacktrace: $st');
        rethrow;
      }
  }

  Future<bool> verifyCode({required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/api/auth/email/verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );
      print('이메일 인증 성공: ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print(' 이메일 인증 실패: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print(' 이메일 인증 예외: $e');
      return false;
    }
  }
  Future<String> resetPassword({
      required String email,
      required String code,
      required String newPassword,
    }) async {
      try {
        final response = await _dio.post(
          '/api/auth/email/reset-password',
          data: {
            'email': email,
            'code': code,
            'newPassword': newPassword,
          },
        );
        return response.data.toString();
      } on DioException catch (e) {
        final msg =
            e.response?.data?.toString() ?? e.message ?? '비밀번호 변경 실패';
        return msg;
      } catch (e) {
        return '비밀번호 변경 실패: $e';
      }
    }
}
