import 'package:dio/dio.dart';
import 'package:adbeaver/config.dart';

class WalletInfo {
  final int bid;
  final int money;
  final bool signupBonusClaimed;

  WalletInfo({
    required this.bid,
    required this.money,
    required this.signupBonusClaimed,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      bid: json['bid'] ?? 0,
      money: json['money'] ?? 0,
      signupBonusClaimed: json['signup_bonus_claimed'] ?? false,
    );
  }
}

class WalletService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ServerConfig.nodeBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
    ),
  );

  Future<WalletInfo> fetchWallet(int userId) async {
    final response = await _dio.get('/api/users/$userId/wallet');
    return WalletInfo.fromJson(response.data);
  }

  Future<WalletInfo> claimSignupBonus(int userId) async {
    final response = await _dio.post('/api/users/$userId/signup-bonus');
    final data = response.data['user'] ?? {};
    return WalletInfo(
      bid: data['bid'] ?? 0,
      money: data['money'] ?? 0,
      signupBonusClaimed: data['signup_bonus_claimed'] ?? true,
    );
  }
}
