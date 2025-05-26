import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';

class AptPage extends StatefulWidget {
  final String aptHash;
  final Map<String, dynamic> aptInfo;

  const AptPage({super.key, required this.aptHash, required this.aptInfo});

  @override
  State<AptPage> createState() => _AptPageState();
}

class _AptPageState extends State<AptPage> {
  late final CollectionReference<Map<String, dynamic>> _aptRef; // final 추가, 타입 명시
  int _startYear = 2006; // _ 추가
  bool _isFavorite = false; // 찜 상태 관리

  @override
  void initState() {
    super.initState();
    _aptRef = FirebaseFirestore.instance.collection('wydmu17me'); // 타입 명시
    _checkFavorite(); // 찜 여부 확인
  }

  Future<void> _checkFavorite() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('rollcake')
          .doc('favorite') // 문서 ID를 명확하게 지정해야 합니다.
          .get();

      if (docSnapshot.exists) {
        // 문서가 존재하면 찜 상태를 확인합니다.
        final favoriteData = docSnapshot.data() as Map<String, dynamic>?; // 타입 캐스팅 및 null check
        if (favoriteData != null && favoriteData['aptHash'] == widget.aptHash) {
          setState(() {
            _isFavorite = true;
          });
        }
      }
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

// 찜 추가/제거 함수
  Future<void> _toggleFavorite() async {
    try {
      final favoriteRef = FirebaseFirestore.instance.collection('rollcake').doc('favorite');
      if (_isFavorite) {
        // 찜 제거
        await favoriteRef.delete(); // 문서 삭제
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('나의 아파트에서 제거되었습니다')));
      } else {
        // 찜 추가
        await favoriteRef.set(widget.aptInfo); // 문서 데이터 설정
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('나의 아파트로 등록되었습니다')));
      }
    } catch (e) {
      // 에러 처리
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜 기능에 오류가 발생했습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersQuery = _aptRef // _aptRef 사용
        .orderBy('deal_ymd')
        .where('deal_ymd', isGreaterThanOrEqualTo: '${_startYear}0000'); // _startYear 사용

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aptInfo['name']),
        actions: [
          IconButton(
            onPressed: _toggleFavorite, // 찜 토글 함수 호출
            icon: Icon(_isFavorite? Icons.favorite: Icons.favorite_border), // 찜 상태에 따라 아이콘 변경
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAptInfo(widget.aptInfo), // 아파트 정보 표시 위젯 분리
          Container(
            color: Colors.black,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 5), // margin 수정
          ),
          Text('검색 시작 년도: $_startYear년'), // _startYear 사용
          Slider(
            value: _startYear.toDouble(),
            onChanged: (value) {
              setState(() {
                _startYear = value.toInt();
              });
            },
            min: 2006,
            max: 2023,
          ),
          Expanded(
            child: FirestoreListView<Map<String, dynamic>>(
              query: usersQuery,
              pageSize: 20,
              itemBuilder: (context, snapshot) {
                if (!snapshot.exists) {
                  return const Center(child: CircularProgressIndicator()); // 데이터 로딩 중 표시
                }
                Map<String, dynamic> apt = snapshot.data()!; //! 추가
                return Card(
                  child: Padding( // Padding 추가
                    padding: const EdgeInsets.all(8.0), // Padding 추가
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Row 위젯 정렬
                      children: [
                        Expanded( // Expanded 추가
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Column 위젯 정렬
                            children: [
                              Text('계약 일시: ${apt['deal_ymd']}'),
                              Text('계약 층: ${apt['floor']}층'),
                              Text('계약 가격: ${double.parse(apt['obj_amt']) / 10000}억'),
                              Text('전용 면적: ${apt['bldg_area']}m2'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              emptyBuilder: (context) => const Center(child: Text('매매 데이터가 없습니다')), // Center 위젯 추가
              errorBuilder: (context, err, stack) => Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.')), // Center 위젯 추가, 메시지 변경
            ),
          ),
        ],
      ),
    );
  }

  // 아파트 정보 표시 위젯
  Widget _buildAptInfo(Map<String, dynamic> aptInfo) {
    return Padding( // Padding 추가
      padding: const EdgeInsets.all(8.0), // Padding 추가
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Column 위젯 정렬
        children: [
          Text('아파트 이름: ${aptInfo['name']}'),
          Text('아파트 주소: ${aptInfo['address']}'),
          Text('아파트 동 수: ${aptInfo['ALL_DONG_CO']}'),
          Text("아파트 세대 수: ${aptInfo['ALL_HSHLD_CO']}"),
          Text('아파트 주차 대수: ${aptInfo['CNT_PA']}'),
          Text('60m2 이하 평형 세대수: ${aptInfo['KAPTMPAREA60']}'),
          Text('60m2 - 85m2 이하 평형 세대수: ${aptInfo['KAPTMPAREA85']}'),
        ],
      ),
    );
  }
}