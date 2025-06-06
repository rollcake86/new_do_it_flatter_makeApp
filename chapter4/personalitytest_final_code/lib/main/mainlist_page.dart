// import 'dart:convert';
//
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter/material.dart';
// import 'package:personalitytest/sub/question_page.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class MainPage extends StatefulWidget {
//   const MainPage({super.key});
//
//   @override
//   State<StatefulWidget> createState() {
//     return _MainPage();
//   }
// }
//
// class _MainPage extends State<MainPage> {
//   FirebaseDatabase database = FirebaseDatabase.instance;
//
//   late DatabaseReference _testRef;
//   late List<String> testList = List.empty(growable: true);
//
//   final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     remoteConfigInit();
//     _testRef = database.ref('test');
//   }
//
//   Future<List<String>> loadAsset() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     if (connectivityResult == ConnectivityResult.mobile ||
//         connectivityResult == ConnectivityResult.wifi) {
//       await _testRef.get().then((value) => value.children.forEach((element) {
//             testList.add(element.value.toString());
//           }));
//     } else {
//       if (mounted) {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text('심리테스트앱'),
//               content: Text(
//                   '지금 인터넷이 연결이 되어있지 않아 심리테스트 앱을 사용할 수 없습니다. 나중에 다시 실행해 주세요.'),
//             );
//           },
//         );
//       }
//     }
//     return testList;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: remoteConfig.getBool("banner")
//           ? AppBar(
//               title: Text(remoteConfig.getString("welcome")),
//             )
//           : null,
//       body: FutureBuilder(
//         builder: (context, snapshot) {
//           switch (snapshot.connectionState) {
//             case ConnectionState.active:
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//             case ConnectionState.done:
//               return ListView.builder(
//                 itemBuilder: (context, value) {
//                   Map<String, dynamic> item = jsonDecode(snapshot.data![value]);
//                   return InkWell(
//                     child: SizedBox(
//                       height: remoteConfig.getInt("item_height").toDouble(),
//                       child: Card(
//                         color: Colors.amber,
//                         child: Text(item['title'].toString()),
//                       ),
//                     ),
//                     onTap: () async {
//                       await FirebaseAnalytics.instance.logEvent(
//                         name: "test_click",
//                         parameters: {
//                           "test_name": item['title'].toString(),
//                         },
//                       ).then((result) {
//                         Navigator.of(context)
//                             .push(MaterialPageRoute(builder: (context) {
//                           return QuestionPage(question: item);
//                         }));
//                       });
//                     },
//                   );
//                 },
//                 itemCount: snapshot.data!.length,
//               );
//             case ConnectionState.none:
//               return const Center(
//                 child: Text('No Data'),
//               );
//             case ConnectionState.waiting:
//               return const Center(
//                 child: CircularProgressIndicator(),
//               );
//           }
//         },
//         future: loadAsset(),
//       ),
// //       floatingActionButton: FloatingActionButton(
// //         child: const Icon(Icons.add),
// //         onPressed: () {
// //           FirebaseDatabase database = FirebaseDatabase.instance;
// //           DatabaseReference _testRef = database.ref('test');
// //           _testRef.push().set("""{
// //   "title": "당신이 좋아하는 애완동물은",
// //   "question": "당신이 무인도에 도착했는데 마침 떠내려온 상자를 열었을때 보이는 이것은",
// //   "selects": [
// //     "생존키트",
// //     "휴대폰",
// //     "텐트",
// //     "무인도에서 살아남기"
// //   ],
// //   "answer": [
// //     "당신은 현실주의 동물은 안키운다!!",
// //     "당신은 늘 함께 있는 걸 좋아하는 강아지가 딱입니다",
// //     "당신은 같은 공간을 공유하는 고양이",
// //     "당신은 낭만을 좋아하는 앵무새"
// //   ]
// // }""");
// //           _testRef.push().set("""{
// //   "title": "5초 MBTI I/E 편",
// //   "question": "친구와 함께 간 미술관 당신이라면",
// //   "selects": [
// //     "말이 많아짐",
// //     "생각이 많아짐"
// //   ],
// //   "answer": [
// //     "당신의 성향은 E",
// //     "당신의 성향은 I"
// //   ]
// // }""");
// //           _testRef.push().set("""{
// //   "title": "당신은 어떤 사랑을 하고 싶나요",
// //   "question": "목욕을 할때 가장 먼저 비누칠을 하는 곳은",
// //   "selects": [
// //     "머리",
// //     "상체",
// //     "하체"
// //   ],
// //   "answer": [
// //     "당신은 자만추를 추천해요",
// //     "당신은 소개팅을 통한 새로운 사람의 소개를 좋아합니다",
// //     "당신은 길가다가 우연히 지나친 그런 인연을 좋아합니다"
// //   ]
// // }""");
// //         },
// //       ),
//     );
//   }
//
//   void remoteConfigInit() async {
//     await remoteConfig.fetchAndActivate();
//   }
// }

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../sub/question_page.dart';

final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isDialogOpen = false; // 다이얼로그 표시 여부

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;
  late List<String> testList = List.empty(growable: true);

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
        _testRef = database.ref('test');
        remoteConfigInit();
        return;
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

  void remoteConfigInit() async {
    await remoteConfig.fetch();
    await remoteConfig.activate(); // activate()를 명시적으로 호출
    welcomeTitle = remoteConfig.getString("welcome");
    bannerUse = remoteConfig.getBool("banner");
    itemHeight = remoteConfig.getInt("item_height");
  }

  Future<List<String>> loadAsset() async {
    try {
      final snapshot = await _testRef.get();
      snapshot.children.forEach((element) {
        print("element ${element.value as String}");
        testList.add(element.value as String); // 타입 변환
      });
      return testList;
    } catch (e) {
      print('Failed to load data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<String>>(
      // 타입 명시
      future: loadAsset(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // null check
          return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> item = jsonDecode(snapshot.data![index]);
                return InkWell(
                  child: SizedBox(
                    height: remoteConfig.getInt("item_height").toDouble(),
                    child: Card(
                      color: Colors.amber,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(item['title'].toString()),
                      ),
                    ),
                  ),
                  onTap: () async {
                    await FirebaseAnalytics.instance.logEvent(
                      name: "test_click",
                      parameters: {
                        "test_name": item['title'].toString(),
                      },
                    ).then((result) {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return QuestionPage(question: item);
                      }));
                    });
                  },
                );
              });
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ));
  }
}
