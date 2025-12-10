import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';

class NaverLoginService {
  bool isLogin = false;
  String? accessToken;
  String? expiresAt;
  String? tokenType;
  String? name;
  String? refreshToken;
  NaverAccountResult? userInfo;


  Future<NaverAccountResult?> buttonLoginPressed() async {
     try {
       final NaverLoginResult res = await FlutterNaverLogin.logIn();
       if (res.status != NaverLoginStatus.loggedIn) return null;

       final account = await FlutterNaverLogin.getCurrentAccount();
       userInfo = account;
       isLogin = true;
       return account;
     } catch (e) {
       print("네이버 로그인 오류: $e");
       return null;
     }
   }


    Future<void> buttonTokenPressed() async {
      try {
        final NaverToken res = await FlutterNaverLogin.getCurrentAccessToken();

          refreshToken = res.refreshToken;
          accessToken = res.accessToken;
          tokenType = res.tokenType;
          expiresAt = res.expiresAt;
          isLogin = res.isValid();

      } catch (error) {
        print(error.toString());
      }
    }

    Future<void> buttonLogoutPressed() async {
      try {
        final NaverLoginResult res = await FlutterNaverLogin.logOut();
        if (res.status == NaverLoginStatus.loggedOut) {

            isLogin = false;
            accessToken = null;
            refreshToken = null;
            tokenType = null;
            expiresAt = null;
            userInfo = null;
        }
      } catch (error) {
        print(error.toString());
      }
    }

    Future<void> buttonLogoutAndDeleteTokenPressed() async {
      try {
        final NaverLoginResult res =
            await FlutterNaverLogin.logOutAndDeleteToken();
        if (res.status == NaverLoginStatus.loggedOut) {
            isLogin = false;
            accessToken = null;
            refreshToken = null;
            tokenType = null;
            expiresAt = null;
            userInfo = null;
        }
      } catch (error) {
        print(error.toString());
      }
    }

    Future<void> buttonGetUserPressed() async {
      try {
        final NaverAccountResult res =
            await FlutterNaverLogin.getCurrentAccount();
        userInfo = res;
      } catch (error) {
        print(error.toString());
      }
    }
}
