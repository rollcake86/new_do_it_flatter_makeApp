import 'dart:async';

import 'package:classicsound/data/constant.dart';
import 'package:classicsound/view/main/main_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../auth/auth_page.dart';


class IntroPage extends StatefulWidget {
  final Database database;
  const IntroPage({super.key, required this.database});

  @override
  State<StatefulWidget> createState() {
    return _IntroPageState();
  }
}

class _IntroPageState extends State<IntroPage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isDialogOpen = false; // 다이얼로그 표시 여부
  bool _isConnected = false; // 인터넷 연결 상태


  Future<bool> _loginCheck() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();
    String? id = preferences.getString("id");
    String? pw = preferences.getString("pw");
    if (id != null && pw != null){
      final FirebaseAuth auth = FirebaseAuth.instance;
      try {
        await auth.signInWithEmailAndPassword(
            email: id, password: pw);
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
    _initConnectivity(); // 초기 연결 상태 확인 및 리스너 등록
  }

  Future<void> _initConnectivity() async {
    // 초기 연결 상태 확인
    List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // 연결 상태 변경 리스너 등록
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {

    for (var element in result) {
      if (element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi) {
        setState(() {
          _isConnected = true;
        });
      }
    }
    if (_isConnected) {
      if (_isDialogOpen) {
        Navigator.of(context).pop(); // 다이얼로그 닫기
        _isDialogOpen = false;
      }
      _loginCheck().then((value){
        if(value == true) {
          Timer(const Duration(seconds: 2), () {
            if (mounted) { // mounted check 추가
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainPage(database: widget.database,)),
              );
            }
          });
        }else {
          Timer(const Duration(seconds: 2), () {
            if (mounted) { // mounted check 추가
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage(database: widget.database,)),
              );
            }
          });
        }
      });

    } else {
      _showOfflineDialog(); // 인터넷 연결 안되었을 때 다이얼로그 표시
    }
  }

  void _showOfflineDialog() {
    if (!_isDialogOpen && mounted) { // mounted check 추가
      _isDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false, // 다이얼로그 외부 터치 방지
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(Constant.APP_NAME,),
            content: const Text(
                '/ '),
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
    // 인터넷 연결 상태에 따라 다른 위젯 표시
    return Scaffold(
      body: Center(
        child: _isConnected //_isConnected 변수를 사용하여 조건부 렌더링
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Constant.APP_NAME,
                style: TextStyle(fontSize: 50),
              ),
              SizedBox(
                height: 20,
              ),
              Icon(
                Icons.audiotrack,
                size: 100,
              )
            ],
          ),
        )
            : const CircularProgressIndicator(), // 인터넷 연결 대기 중
      ),
    );
  }
}
