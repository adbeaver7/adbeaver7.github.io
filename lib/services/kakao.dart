import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginService {
  Future<bool> kakaoLogin() async {
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
          return true;
        } catch (error) {
          print("카카오톡 로그인 실패 → 계정 로그인으로 재시도: $error");
          try {
            await UserApi.instance.loginWithKakaoAccount();
            return true;
          } catch (e) {
            print("카카오 계정 로그인도 실패: $e");
            return false;
          }
        }
      } else {
        await UserApi.instance.loginWithKakaoAccount();
        return true;
      }
    } catch (error) {
      print("로그인 코드 전체 실패: $error");
      return false;
    }
  }

  Future<bool> kakaoLogout() async{
    try {
      await UserApi.instance.unlink();
      return true;
    } catch(error){
      return false;
    }
  }
}