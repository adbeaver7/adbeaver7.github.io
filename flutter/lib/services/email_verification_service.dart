import 'package:adbeaver/config.dart';
import 'package:dio/dio.dart';

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

  Future<void> sendCode(String email) async {
    try {
      final response = await _dio.post(
        '/api/auth/email/send-code',
        data: {'email': email},
      );
      print('📨 인증 코드 전송 성공: ${response.data}');
    } catch (e) {
      print('❌ 인증 코드 전송 실패: $e');
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
      print('✅ 이메일 인증 성공: ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ 이메일 인증 실패: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('❌ 이메일 인증 예외: $e');
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
