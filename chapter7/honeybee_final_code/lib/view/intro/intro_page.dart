import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:honeybee/data/constant.dart';
import 'package:honeybee/view/hobby/HobbySelectionPage.dart';
import 'package:honeybee/view/main/main_page.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/user.dart';
import '../auth/auth_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _IntroPage();
  }
}

class _IntroPage extends State<IntroPage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isDialogOpen = false; // 다이얼로그 표시 여부

  late HoneyBeeUser user;

  Future<bool> _notiPermissionCheck() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _loginCheck() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? id = preferences.getString("id");
    String? pw = preferences.getString("pw");
    String? hobby = preferences.getString("hobby");
    if (id != null && pw != null) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      try {
        await auth.signInWithEmailAndPassword(email: id, password: pw);
        user = HoneyBeeUser(
            email: auth.currentUser!.email!, uid: auth.currentUser!.uid);
        user.hobby = hobby;
        // Get.put(user);
        Get.lazyPut(() => user);
        await Future.delayed(const Duration(seconds: 2));
        return true;
      } on FirebaseAuthException catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnection(); // 초기 연결 상태 확인
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _handleConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _handleConnectionStatus(result);
  }

  void _handleConnectionStatus(List<ConnectivityResult> result) {
    for (var element in result) {
      if (element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi) {
        if (_isDialogOpen) {
          Navigator.of(context).pop(); // 다이얼로그 닫기
          _isDialogOpen = false;
        }
        // _notiPermissionCheck().then((value) {

        // });
      } else {
        // 인터넷 연결 안됨
        _showOfflineDialog();
      }
    }
  }

  void _showOfflineDialog() {
    if (!_isDialogOpen && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          _isDialogOpen = true;
          return AlertDialog(
            title: const Text('심리 테스트 앱'),
            content: const Text(
                '지금 인터넷에 연결되지 않아 심리 테스트 앱을 사용할 수 없습니다. 나중에 다시 실행해 주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _isDialogOpen = false;
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      ).then((_) => _isDialogOpen = false); // 다이얼로그 닫힐 때 _isDialogOpen = false
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // StreamSubscription 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: _notiPermissionCheck(),
          builder: (buildContext, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return introView();
              case ConnectionState.waiting:
                return introView();
              case ConnectionState.active:
                return introView();
              case ConnectionState.done:
                _loginCheck().then((value) {
                  if (value == true) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Get.snackbar(Constant.APP_NAME, '로그인 되었습니다');
                      if (user.hobby != null) {
                          // 메인 페이지로 이동하기
                        Get.off(MainPage());
                      } else {
                          // 취미 선택 페이지로 이동하기
                        Get.off(const HobbySelectionPage());
                      }
                    });
                  } else {
                    Future.delayed(const Duration(seconds: 2), () {
                      Get.off(const AuthPage());
                      print("로그인 안됨");
                    });
                  }
                });
                return introView();
            }
          }),
    );
  }

  Widget introView() {
    return Container(
      color: Colors.greenAccent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              Constant.APP_NAME,
              style: TextStyle(fontSize: 50, fontFamily: 'clover'),
            ),
            SizedBox(
              height: 20,
            ),
            Lottie.asset('res/animation/honeybee.json'),
          ],
        ),
      ),
    );
  }
}
