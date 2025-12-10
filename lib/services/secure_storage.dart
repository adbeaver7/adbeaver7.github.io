import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyUserId   = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyNickname = 'nickname';
  static const String _keyEmail    = 'email';
  static const String _keyLastLogin = 'last_login';

  static const String _keyBid  = 'bid';
  static const String _keyMoney = 'money';
  static const String _keySignupBonusClaimed = 'signup_bonus_claimed';

  Future<void> saveUser({
    required int userId,
    required String username,
    required String nickname,
    required String email,
    required int bid,
    required int money,
    required bool signupBonusClaimed,
  }) async {
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyNickname, value: nickname);
    await _storage.write(key: _keyEmail, value: email);

    await _storage.write(key: _keyBid, value: bid.toString());
    await _storage.write(key: _keyMoney, value: money.toString());
    await _storage.write(
      key: _keySignupBonusClaimed,
      value: signupBonusClaimed.toString(),
    );

    await _storage.write(
      key: _keyLastLogin,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, String>?> readUser() async {
    try {
      final userId = await _storage.read(key: _keyUserId);
      if (userId == null) {
        return null;
      }

      final username  = await _storage.read(key: _keyUsername);
      final nickname  = await _storage.read(key: _keyNickname);
      final email     = await _storage.read(key: _keyEmail);
      final lastLogin = await _storage.read(key: _keyLastLogin);

      final bid   = await _storage.read(key: _keyBid);
      final money = await _storage.read(key: _keyMoney);
      final signupBonusClaimed =
          await _storage.read(key: _keySignupBonusClaimed);

      return {
        'user_id' : userId,
        'username': username ?? '',
        'nickname': nickname ?? '',
        'email'   : email ?? '',
        'last_login': lastLogin ?? '',
        'bid'     : bid ?? '0',
        'money    ': money ?? '0',
        'signup_bonus_claimed': signupBonusClaimed ?? 'false',
      };
    } catch (e) {
      print('🔴 SecureStorageService.readUser 에러: $e');
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyNickname);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyLastLogin);

      await _storage.delete(key: _keyBid);
      await _storage.delete(key: _keyMoney);
      await _storage.delete(key: _keySignupBonusClaimed);

    } catch (e) {
      print('🔴 SecureStorageService.clearUser 에러: $e');
    }
  }
}
