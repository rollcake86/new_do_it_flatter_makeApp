import 'package:classicsound/data/constant.dart';
import 'package:classicsound/view/main/main_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AuthPage extends StatefulWidget {
  final Database database;

  const AuthPage({Key? key, required this.database}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 입력값 검증
  bool _isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@');
  }

  bool _isValidPassword(String password) {
    return password.isNotEmpty && password.length >= 6;
  }

  // 인증 결과 처리
  void _handleAuthResult(UserCredential userCredential) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("id", _emailController.text);
    preferences.setString("pw", _passwordController.text);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_emailController.text)
        .set({
      'email': _emailController.text,
      'token': userCredential.user?.uid,
    });
    // 메인 페이지로 이동
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => MainPage(database: widget.database)),
            (route) => false);
  }

  // 회원가입
  void _signUp() async {
    if (!_isValidEmail(_emailController.text) ||
        !_isValidPassword(_passwordController.text)) {
      _showSnackBar("유효한 이메일과 비밀번호를 입력해주세요.");
      return;
    }
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      _handleAuthResult(userCredential);
    } on FirebaseAuthException catch (e) {
      _showSnackBar("회원가입 실패: ${e.message}");
    } catch (e) {
      _showSnackBar("오류가 발생했습니다: $e");
    }
  }

  // 로그인
  void _signIn() async {
    if (!_isValidEmail(_emailController.text) ||
        !_isValidPassword(_passwordController.text)) {
      _showSnackBar("유효한 이메일과 비밀번호를 입력해주세요.");
      return;
    }
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      _handleAuthResult(userCredential);
    } on FirebaseAuthException catch (e) {
      _showSnackBar("로그인 실패: ${e.message}");
    } catch (e) {
      _showSnackBar("오류가 발생했습니다: $e");
    }
  }

  // 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Constant.APP_NAME)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'example@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  hintText: '6자 이상',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(onPressed: _signUp, child: const Text('회원가입')),
                  ElevatedButton(onPressed: _signIn, child: const Text('로그인')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}