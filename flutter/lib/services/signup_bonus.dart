import 'package:adbeaver/config.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SignupBonusManager {
  SignupBonusManager._();

  static Future<void> checkAndShowBonus(BuildContext context) async {
    final userProvider = context.read<UserProvider>();

    if (!userProvider.isLoggedIn) return;

    if (userProvider.isSignupBonusClaimed == true) return;

    final bool? ok = await _showBonusDialog(context);

    if (ok != true) return;

    if (context.mounted) {
      await _claimBonusFromServer(context);
    }
  }

  static Future<bool?> _showBonusDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final name = userProvider.nickname ?? userProvider.username ?? "광고주";
    final formatter = NumberFormat('#,###');

    const defaultCredits = 3;
    const defaultMoney = 10000;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2972C7).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "가입을 축하드려요!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$name 님을 위한 선물이 도착했습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildRewardItem(
                        title: "광고 등록 티켓",
                        value: "${defaultCredits}개",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      _buildRewardItem(
                        title: "광고 예산 지원금",
                        value: "${formatter.format(defaultMoney)}원",
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2972C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "선물 받기",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildRewardItem({
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF2972C7) : Colors.black87,
          ),
        ),
      ],
    );
  }

  static Future<void> _claimBonusFromServer(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;

    if (userId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 정보가 없습니다. 다시 로그인해주세요.")),
      );
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.post(
        '${ServerConfig.nodeBaseUrl}/api/users/$userId/signup-bonus',
      );


      final data = response.data;
      final int newBid = data['bid'] ?? 0;
      final int newMoney = data['money'] ?? 0;

      await userProvider.claimSignupBonus();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("선물이 지급되었습니다!"),
          backgroundColor: Color(0xFF2972C7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("보너스 지급 에러: $e");
      if (!context.mounted) return;

      String errorMsg = "선물 지급 중 오류가 발생했습니다.";
      if (e is DioException && e.response?.statusCode == 400) {
        errorMsg = "이미 선물을 받으셨습니다.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }
}