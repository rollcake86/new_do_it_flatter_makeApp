import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mybudongsan/map/map_filter.dart';
import 'package:mybudongsan/map/map_filter_dialog.dart';
import 'package:mybudongsan/myFavorite/my_favorite_page.dart';
import 'package:mybudongsan/settings/setting_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../geoFire/geoflutterfire.dart';
import '../geoFire/models/point.dart';

import 'apt_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MapPage();
  }
}

class _MapPage extends State<MapPage> {
  Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId? selectedMarker;
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  LatLng? markerPosition;
  var geoHasher = GeoHasher();
  final geo = Geoflutterfire();

  int currentItem = 0;

  MapType mapType = MapType.normal;

  late List<DocumentSnapshot> documentList =
      List<DocumentSnapshot>.empty(growable: true);

  MapFilter mapFilter = MapFilter();



  static const CameraPosition _googleMapCamera = CameraPosition(
    target: LatLng(37.571320, 127.029403),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    addCustomIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My 부동산'),
        actions: [IconButton(onPressed: () async{
          var result = await Navigator.of(context).push(MaterialPageRoute(builder: (context){
            return MapFilterDialog(mapFilter);
          }));
          if(result != null){
            mapFilter = result as MapFilter;
          }
        }, icon: const Icon(Icons.search))],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(child: Text('조준수 님 환영합니다')),
            ListTile(
              title: const Text('내가 선택한 아파트'),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return const MyFavoritePage();
                }));
              },
            ),
            ListTile(
              title: const Text('설정'),
              onTap: () async {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return SettingPage();
                })).then((value) async {
                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                  final int? type = prefs.getInt('mapType');
                  setState(() {
                    switch(type){
                      case 0:
                        mapType = MapType.terrain;
                        break;
                      case 1:
                        mapType = MapType.satellite;
                        break;
                      case 2:
                        mapType = MapType.hybrid;
                        break;
                    }
                  });
                });
              },
            ),
          ],
        ),
      ),
      body: currentItem == 0 ? GoogleMap(
        mapType: mapType,
        initialCameraPosition: _googleMapCamera,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(markers.values),
      ) : ListView.builder(itemBuilder: (context, value){
        Map<String, dynamic> item = documentList[value].data() as Map<String , dynamic>;
        return InkWell(child: Card(
          child: ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(item['name']),
            subtitle: Text(item['address']),
            trailing: const Icon(Icons.arrow_circle_right_sharp),
          ),
        ),onTap: (){
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return AptPage(
              aptHash: item['position']['geohash'],
              aptInfo: item,
            );
          }));
        },);
      } , itemCount: documentList.length,)
      ,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentItem,
        onTap: (value) {
          if (value == 0){
            _controller =
                Completer<GoogleMapController>();
          }
          setState(() {
            currentItem = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: 'map',
            icon: Icon((Icons.map)),
          ),
          BottomNavigationBarItem(
            label: 'list',
            icon: Icon((Icons.list)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _searchApt,
        label: const Text('이 위치로 검색하기'),
      ),
    );
  }

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "res/images/apartment.png")
        .then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  Future<void> _searchApt() async {
    // GoogleMapController 가져오기
    final GoogleMapController controller = await _controller.future;

    // 현재 지도 화면 영역 가져오기
    final bounds = await controller.getVisibleRegion();

    //  화면 영역의 중심 좌표 계산
    final LatLng centerBounds = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    //  Firestore 'cities' 컬렉션 참조 가져오기
    final aptRef = FirebaseFirestore.instance.collection('cities');
    final geo = Geoflutterfire();

    // GeoFirePoint 객체 생성 (지도 중심 좌표 사용)
    final GeoFirePoint center = geo.point(
        latitude: centerBounds.latitude, longitude: centerBounds.longitude);

    // 검색 반경 및 GeoFire 필드 설정
    const double radius = 1; // 검색 반경 1km
    const String field = 'position'; // GeoFire 필드 이름

    // GeoFlutterFire를 사용하여 Firestore 쿼리 실행 (반경 내 문서 검색)
    final Stream<List<DocumentSnapshot>> stream = geo
        .collection(collectionRef: aptRef)
        .within(center: center, radius: radius, field: field);

    //  검색 결과 스트림 Listen
    stream.listen((List<DocumentSnapshot> documentList) {
      //  검색 결과 문서 목록 저장 및 마커 업데이트
      this.documentList = documentList;
      _drawMarkers(documentList);
    });
  }

  void _drawMarkers(List<DocumentSnapshot> documentList) {
    setState(() {
      markers.clear(); // 기존 마커들을 효율적으로 제거
    });

    // 검색 결과 문서 목록 순회
    for (final DocumentSnapshot doc in documentList) {
      //  각 문서에서 아파트 정보 추출
      final Map<String, dynamic> info = doc.data()! as Map<String, dynamic>;
      // 필터 조건에 맞는지 확인
      if (selectedCheck(info, mapFilter.peopleString, mapFilter.carString, mapFilter.buildingString)) {
        // MarkerId 생성 (geohash 사용)
        final MarkerId markerId = MarkerId(info['position']['geohash']);

        //  Marker 생성
        final Marker marker = Marker(
          markerId: markerId,
          infoWindow: InfoWindow(
            title: info['name'],
            snippet: info['address'],
            onTap: () {
              // AptPage로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AptPage(
                    aptHash: info['position']['geohash'],
                    aptInfo: info,
                  ),
                ),
              );
            },
          ),
          position: LatLng(
            (info['position']['geopoint'] as GeoPoint).latitude,
            (info['position']['geopoint'] as GeoPoint).longitude,
          ),
          icon: markerIcon,
        );
        //  마커를 지도에 추가
        setState(() {
          markers[markerId] = marker;
        });
      }
    }
  }

  bool selectedCheck(Map<String, dynamic> info, String? peopleString,
      String? carString, String? buildingString) {
    final dong = info['ALL_DONG_CO'];
    final people = info['ALL_HSHLD_CO'];
    final parking = people / info['CNT_PA'];

    // Check building and people conditions first
    if (dong < int.parse(buildingString!) || people < int.parse(peopleString!)) {
      return false;
    }

    // Now check car condition based on carString
    if (carString == '1') {
      return parking < 1;
    } else {
      return parking >= 1;
    }
  }
}
