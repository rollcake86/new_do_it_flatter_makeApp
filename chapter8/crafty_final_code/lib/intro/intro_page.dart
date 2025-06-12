import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/user.dart';
import '../data/constant.dart';
import '../view/auth/auth_page.dart';
import '../view/main/main_page.dart';

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

  late CraftyUser user;

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
    String? type = preferences.getString("type");

    if (id == null || pw == null) {
      return false;
    }

    final FirebaseAuth auth = FirebaseAuth.instance;

    if (type == SignType.Email.name) {
      try {
        await auth.signInWithEmailAndPassword(email: id, password: pw);
        CraftyUser user = CraftyUser(email: id, password: pw);
        user.type = SignType.Email.name;
        user.uid = auth.currentUser!.uid;
        Get.lazyPut(() => user);
        return true;
      } on FirebaseAuthException catch (e) {
        return false;
      }
    } else if (type == SignType.Google.name) {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
      await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user != null) {
        CraftyUser craftyUseruser = CraftyUser(email: id, password: pw);
        craftyUseruser.type = SignType.Google.name;
        craftyUseruser.uid = user.uid;
        Get.lazyPut(() => craftyUseruser);
        return true;
      } else {
        return false;
      }
    }

    return false;
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
            title: const Text(Constant.APP_NAME),
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
                    Future.delayed(const Duration(seconds: 2), () async {
                      Get.snackbar(Constant.APP_NAME, '로그인 되었습니다');
                      CraftyUser user = Get.find();
                      await FirebaseFirestore.instance
                          .collection('craftyusers')
                          .doc(user.email)
                          .update({
                        'loginTimeStamp': FieldValue.serverTimestamp()
                      });
                      // 메인 페이지로 이동하기
                      Get.off(MainPage());
                    });
                  } else {
                    Future.delayed(const Duration(seconds: 2), () {
                      print("로그인 안됨");
                      Get.off(AuthPage());
                      // 로그인 페이지로 이동하기
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
            Lottie.asset('res/animation/shop.json'),
          ],
        ),
      ),
    );
  }
}
