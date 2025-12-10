import 'package:adbeaver/services/secure_storage.dart';
import 'package:adbeaver/services/wallet.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final WalletService _walletService = WalletService();

  int? _userId;
  String? _username;
  String? _nickname;
  String? _email;

  int _bid = 0;
  int _money = 0;
  bool _signupBonusClaimed = false;

  int? get userId => _userId;
  String? get username => _username;
  String? get nickname => _nickname;
  String? get email => _email;

  int get bid => _bid;
  int get money => _money;
  bool get signupBonusClaimed => _signupBonusClaimed;
  bool get isSignupBonusClaimed => _signupBonusClaimed;

  bool get isLoggedIn => _userId != null;

  Future<void> setUserFromApi(Map<String, dynamic> userJson) async {
    final dynamic rawId = userJson['user_id'];
    if (rawId is int) {
      _userId = rawId;
    } else if (rawId is String) {
      _userId = int.tryParse(rawId);
    } else {
      _userId = null;
    }
    _username = userJson['username'] as String?;
    _nickname = userJson['nickname'] as String?;
    _email    = userJson['email'] as String?;

     final dynamic rawBid = userJson['bid'];
     if (rawBid is int) {
       _bid = rawBid;
     } else if (rawBid is String) {
       _bid = int.tryParse(rawBid) ?? 0;
     } else {
       _bid = 0;
     }

     final dynamic rawMoney = userJson['money'];
     if (rawMoney is int) {
       _money = rawMoney;
     } else if (rawMoney is String) {
       _money = int.tryParse(rawMoney) ?? 0;
     } else {
       _money = 0;
     }

     final dynamic rawBonus = userJson['signup_bonus_claimed'];
     if (rawBonus is bool) {
       _signupBonusClaimed = rawBonus;
     } else {
       _signupBonusClaimed = rawBonus?.toString() == 'true';
     }

    if (_userId != null) {
      await _storage.saveUser(
        userId: _userId!,
        username: _username ?? '',
        nickname: _nickname ?? '',
        email: _email ?? '',
        bid: _bid,
        money: _money,
        signupBonusClaimed: _signupBonusClaimed,
      );
    }

    notifyListeners();
  }

  Future<void> setUser(
    int id,
    String name,
    String? nickname,
    String? email,
    int bid,
    int money,
    bool signupBonusClaimed,
  ) async {
    _userId = id;
    _username = name;
    _nickname = nickname;
    _email = email;
    _bid = bid;
    _money = money;
    _signupBonusClaimed = signupBonusClaimed;

    await _storage.saveUser(
      userId: id,
      username: name,
      nickname: nickname ?? '',
      email: email ?? '',
      bid: _bid,
      money: _money,
      signupBonusClaimed: _signupBonusClaimed,
    );

    notifyListeners();
  }

  Future<void> loadUserFromStorage() async {
    final data = await _storage.readUser();
    if (data == null) {
      return;
    }

    final lastLoginStr = data['last_login'];
    if (lastLoginStr != null && lastLoginStr.isNotEmpty) {
      final lastLogin = DateTime.tryParse(lastLoginStr);
      if (lastLogin != null) {
        final now = DateTime.now();
        final diff = now.difference(lastLogin).inDays;
        if (diff > 30) {
          await logout();
          return;
        }
      }
    }

    _userId   = int.tryParse(data['user_id'] ?? '');
    _username = data['username'];
    _nickname = data['nickname'];
    _email    = data['email'];

    _bid   = int.tryParse(data['bid'] ?? '0') ?? 0;
    _money = int.tryParse(data['money'] ?? '0') ?? 0;
    _signupBonusClaimed =
        (data['signup_bonus_claimed'] ?? 'false') == 'true';

    notifyListeners();
  }

  Future<void> updateWallet({
    required int bid,
    required int money,
    required bool signupBonusClaimed,
    bool saveToStorage = true,
  }) async {
    _bid = bid;
    _money = money;
    _signupBonusClaimed = signupBonusClaimed;

    if (saveToStorage && _userId != null) {
      await _storage.saveUser(
        userId: _userId!,
        username: _username ?? '',
        nickname: _nickname ?? '',
        email: _email ?? '',
        bid: _bid,
        money: _money,
        signupBonusClaimed: _signupBonusClaimed,
      );
    }

    notifyListeners();
  }

  Future<void> refreshWallet() async {
    if (_userId == null) return;

    try {
      final wallet = await _walletService.fetchWallet(_userId!);
      await updateWallet(
        bid: wallet.bid,
        money: wallet.money,
        signupBonusClaimed: wallet.signupBonusClaimed,
      );
    } catch (e) {
      debugPrint('지갑 새로고침 실패: $e');
    }
  }

  Future<String?> claimSignupBonus() async {
    if (_userId == null) return '로그인이 필요합니다.';

    try {
      final wallet = await _walletService.claimSignupBonus(_userId!);
      await updateWallet(
        bid: wallet.bid,
        money: wallet.money,
        signupBonusClaimed: wallet.signupBonusClaimed,
      );
      return null;
    } catch (e) {
      debugPrint('보너스 지급 실패: $e');
      return '보너스 지급에 실패했습니다.';
    }
  }

  Future<void> logout() async {
    _userId = null;
    _username = null;
    _nickname = null;
    _email = null;
    _bid = 0;
    _money = 0;
    _signupBonusClaimed = false;

    await _storage.clearUser();
    notifyListeners();
  }
}
