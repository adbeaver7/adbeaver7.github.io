import 'dart:convert';
import 'package:adbeaver/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:adbeaver/services/user_provider.dart';

const String baseUrl = ServerConfig.nodeBaseUrl;

Future<String> registerUser(String username, String nickname, String email, String password) async {
  final url = Uri.parse('$baseUrl/api/auth/register');

  try {
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'nickname': nickname,
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201) {
      return '성공';
    } else if (response.statusCode == 409) {
      return responseBody['error'] ?? '이미 존재하는 이메일입니다.';
    } else {
      return '오류: ${responseBody['error'] ?? '알 수 없는 오류'}';
    }
  } catch (e) {
    return '서버 연결 실패';
  }
}

Future<String> loginUser(BuildContext context, String email, String password) async {
  final url = Uri.parse('$baseUrl/api/auth/login');

  try {
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      final userData = responseBody['user'];

      if (context.mounted) {
        context.read<UserProvider>().setUser(
          userData['user_id'],
          userData['username'],
          userData['nickname'],
          userData['email'],
          userData['bid'],
          userData['money'],
          userData['signup_bonus_claimed'],
        );
      }
      return '로그인성공';
    }
    else if (response.statusCode == 401) {
      return responseBody['error'] ?? '아이디 또는 비밀번호가 틀렸습니다.';
    }
    else {
      return '서버 오류: ${responseBody['error'] ?? '알 수 없는 오류'}';
    }
  } catch (e) {
    print('로그인 에러 상세: $e');
    return '연결 오류: 서버에 접속할 수 없습니다.';
  }
}

Future<String> kakaoLoginUser(BuildContext context, String email) async {
  final url = Uri.parse('$baseUrl/api/auth/kakao-login');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      final userData = responseBody['user'];

      if (context.mounted) {
        context.read<UserProvider>().setUser(
          userData['user_id'],
          userData['username'],
          userData['nickname'],
          userData['email'],
          userData['bid'],
          userData['money'],
          userData['signup_bonus_claimed'],
        );
      }
      return "로그인성공";
    }

    if (response.statusCode == 404) {
      return "회원가입필요";
    }

    return responseBody['error'] ?? "알 수 없는 오류";
  } catch (e) {
    return "연결 오류: 서버에 접속할 수 없습니다.";
  }
}

Future<Map<String, dynamic>?> kakaoLoginApi(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/kakao-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print('🔵 kakao-login 응답 코드: ${response.statusCode}');
    print('🔵 kakao-login 응답 바디: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'] as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ kakao-login 요청 중 에러: $e');
    rethrow;
  }
}

Future<Map<String, dynamic>?> naverLoginApi(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/naver-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print('🔵 naver-login 응답 코드: ${response.statusCode}');
    print('🔵 naver-login 응답 바디: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'] as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ naver-login 요청 중 에러: $e');
    rethrow;
  }
}