# Do it! 플러터 앱 개발&출시하기 예제 코드

이 저장소는 "Do it! 플러터 앱 개발&출시하기" 책에서 다루는 예제 코드를 담고 있습니다.
Flutter와 Dart를 사용하여 다양한 애플리케이션을 만들어가는 과정을 학습할 수 있습니다.

## 📚 목차 (챕터별 예제)

이 저장소는 다음과 같은 챕터별 예제 코드를 포함하고 있습니다. 각 챕터 폴더에는 일반적으로 `_start` (시작 코드)와 `_final_code` (완성 코드) 폴더가 제공될 수 있습니다.

* **Chapter 2: Dart 기본 및 비동기 프로그래밍**
    * Dart 언어의 기초 문법 학습
    * 비동기 처리 (async, await)
    * JSON 데이터 다루기
    * 스트림(Stream) 활용
    * 간단한 예제: 구구단, 로또 번호 생성기, 자동차 클래스 등 (`gugudan.dart`, `lottery.dart`, `car.dart`)

* **Chapter 4: 성격 테스트 앱 (Personality Test App)**
    * `personalitytest_start`: 성격 테스트 앱 개발 시작 코드
    * `personalitytest_final_code`: 성격 테스트 앱 완성 코드
    * 주요 기능: MBTI 기반 성격 테스트, 결과 확인
    * 학습 내용: Flutter UI 구성, 상태 관리, 로컬 JSON 데이터 활용, Firebase 연동 (필요시)
    * 데이터 파일: `res/api/list.json`, `res/api/mbti.json`, `res/api/test1.json`, `res/api/test2.json`

* **Chapter 5: 내 부동산 앱 (My Budongsan App)**
    * `mybudongsan_start`: 내 부동산 앱 개발 시작 코드
    * `mybudongsan_final_code`: 내 부동산 앱 완성 코드
    * 주요 기능: 부동산 매물 정보 확인, 위치 기반 서비스
    * 학습 내용: Google Maps 연동, Geoflutterfire (위치 기반 쿼리), Firebase Firestore 활용, 필터링 기능
    * 데이터 파일: `res/json/apt_test_data.json`

* **Chapter 6: 클래식 사운드 앱 (Classic Sound App)**
    * `classic_sound_start`: 클래식 사운드 앱 개발 시작 코드
    * `classic_sound_final_code`: 클래식 사운드 앱 완성 코드
    * 주요 기능: 클래식 음악 스트리밍, 다운로드, 플레이어 기능, 사용자 인증, 관리자 업로드 기능
    * 학습 내용: Firebase (Auth, Firestore, Storage), 오디오 플레이어, 로컬 데이터베이스 (Drift/Moor), 파일 다운로드 및 관리

* **Chapter 7: 허니비 앱 (Honeybee App)**
    * `honeybee_start`: 허니비 앱 개발 시작 코드
    * `honeybee_final_code`: 허니비 앱 완성 코드
    * 주요 기능: 취미 기반 소셜 네트워킹, 채팅, 게시물 공유, 그림판, 사용자 프로필
    * 학습 내용: Firebase (Auth, Firestore, Storage, Functions), Lottie 애니메이션, 외부 API 연동, 푸시 알림 (Firebase Cloud Messaging)
    * 애니메이션 파일: `res/animation/honeybee.json`
    * Firebase Functions: `lib/admin/functions/index.js`

* **Chapter 8: [챕터8 제목을 입력해주세요 - 예: 쇼핑 앱]**
    * ([챕터8 관련 코드 폴더가 있다면 여기에 명시해주세요])
    * 주요 기능: [챕터8의 주요 기능을 입력해주세요]
    * 학습 내용: [챕터8의 학습 내용을 입력해주세요]
    * 애니메이션 파일: `res/animation/shop.json`, `res/animation/soldout.json` (활용 예시)

## 🚀 시작하기

### 1. 사전 준비 사항

* **Flutter SDK**: 최신 버전의 Flutter SDK를 설치해주세요. (정확한 권장 버전: `[Flutter 버전을 입력해주세요]`)
    * Flutter 설치 가이드: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
* **IDE**: Android Studio 또는 Visual Studio Code 사용을 권장합니다.
* **Firebase 설정 (필요한 챕터의 경우)**:
    * 일부 예제(Chapter 4, 5, 6, 7 등)는 Firebase 연동이 필요합니다.
    * 책의 안내에 따라 Firebase 프로젝트를 생성하고, 각 플랫폼별(Android/iOS/Web) 설정을 완료해주세요.
    * Android: `android/app/google-services.json` 파일을 올바르게配置해야 합니다.
    * iOS: `ios/Runner/GoogleService-Info.plist` 파일을 올바르게配置해야 합니다. (및 `firebase_app_id_file.json`)
    * Web: Firebase SDK 초기화 코드가 `lib/firebase_options.dart` 또는 `web/index.html`에 올바르게 설정되어야 합니다.


## ⚠️ 주의사항

* 각 프로젝트의 `pubspec.yaml` 파일에 명시된 Flutter 및 Dart SDK 버전을 확인해주세요.
* Firebase를 사용하는 예제의 경우, 실행 전에 반드시 본인의 Firebase 프로젝트 설정으로 변경해야 정상적으로 동작합니다. 책의 관련 부분을 참고하여 설정을 진행해주세요.
* 일부 API 키가 필요한 경우, 책의 안내에 따라 발급받아 코드에 적용해야 할 수 있습니다.
