import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mybudongsan/map/map_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isDialogOpen = false; // 다이얼로그 표시 여부
  bool _isConnected = false; // 인터넷 연결 상태

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
    setState(() {
      _isConnected = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
    });

    if (_isConnected) {
      if (_isDialogOpen) {
        Navigator.of(context).pop(); // 다이얼로그 닫기
        _isDialogOpen = false;
      }
      // 인터넷 연결되었을 때 2초 후 화면 전환
      Timer(const Duration(seconds: 2), () {
        if (mounted) { // mounted check 추가
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          );
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
            title: const Text('My 부동산'),
            content: const Text(
                '인터넷 연결이 되어있지 않아 앱을 사용할 수 없습니다. 나중에 다시 실행해 주세요.'),
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
    // _connectivitySubscription.cancel(); // StreamSubscription 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 인터넷 연결 상태에 따라 다른 위젯 표시
    return Scaffold(
      body: Center(
        child: _isConnected //_isConnected 변수를 사용하여 조건부 렌더링
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'My 부동산',
              style: TextStyle(fontSize: 50),
            ),
            SizedBox(height: 20),
            Icon(
              Icons.apartment_rounded,
              size: 100,
            ),
          ],
        )
            : const CircularProgressIndicator(), // 인터넷 연결 대기 중
      ),
    );
  }
}


