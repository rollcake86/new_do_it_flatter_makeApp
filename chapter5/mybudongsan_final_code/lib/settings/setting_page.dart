import 'package:flutter/material.dart';
import 'package:mybudongsan/intro/intro_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  int _mapType = 0;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadMapType();
  }

  Future<void> _loadMapType() async {
    final type = _prefs.getInt("mapType");
    if (type!= null) {
      setState(() {
        _mapType = type;
      });
    }
  }

  Future<void> _saveMapType(int value) async {
    await _prefs.setInt('mapType', value);
    setState(() {
      _mapType = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'), // const 추가
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _logout, // 로그아웃 함수 호출
              child: const Text('로그 아웃 하기'), // const 추가
            ),
            const SizedBox(height: 30), // const 추가
            const Text('지도 타입'), // const 추가
            const SizedBox(height: 20), // const 추가
            _buildMapTypeOptions(), // 지도 타입 선택 위젯 분리
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOptions() {
    return Column(
      children: [
        RadioListTile<int>(
          title: const Text('terrain'), // const 추가
          value: 0,
          groupValue: _mapType,
          onChanged: (value) {
            if (value!= null) {
              _saveMapType(value);
            }
          },
        ),
        RadioListTile<int>(
          title: const Text('satellite'), // const 추가
          value: 1,
          groupValue: _mapType,
          onChanged: (value) {
            if (value!= null) {
              _saveMapType(value);
            }
          },
        ),
        RadioListTile<int>(
          title: const Text('hybrid'), // const 추가
          value: 2,
          groupValue: _mapType,
          onChanged: (value) {
            if (value!= null) {
              _saveMapType(value);
            }
          },
        ),
      ],
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const IntroPage()),
          (route) => false,
    );
  }
}