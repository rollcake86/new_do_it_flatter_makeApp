import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crafty/data/constant.dart';
import 'package:crafty/data/crafty_kind.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../../data/user.dart';

import 'package:http/http.dart' as http;

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SellPage();
  }
}

class _SellPage extends State<SellPage> {
  final TextEditingController _titleTextEditingController =
      TextEditingController();
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _priceEditingController = TextEditingController();
  final TextEditingController _tagtextEditingController =
      TextEditingController();
  CraftyUser user = Get.find();
  XFile? _mediaFile;

  int _selectedItem = 1;
  var _checkbox = false.obs;

  final googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
  late GenerativeModel _currentModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, left: 10),
            child: TextField(
              controller: _titleTextEditingController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Please enter product title',
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            margin: const EdgeInsets.only(right: 10, left: 10),
            height: 150,
            child: TextField(
              controller: _textEditingController,
              keyboardType: TextInputType.emailAddress,
              expands: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Please enter product details',
              ),
              maxLines: null,
            ),
          ),
          _mediaFile != null
              ? SizedBox(
                  height: 300,
                  child: Image.file(
                    File(_mediaFile!.path),
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return const Center(
                          child: Text('This image type is not supported'));
                    },
                  ),
                )
              : Container(),
          SizedBox(
            height: 10,
          ),
          Container(
            margin: const EdgeInsets.only(right: 10, left: 10),
            child: TextField(
              controller: _priceEditingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter the price you would like to sell for',
              ),
              maxLines: null,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            margin: const EdgeInsets.only(right: 10, left: 10),
            child: TextField(
              controller: _tagtextEditingController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Please enter tags, separated by ,(comma)',
              ),
              maxLines: null,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: DropdownButton(
              value: _selectedItem,
              items: craftyKind.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedItem = value!;
                });
              },
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Push Check'),
              Switch(
                  value: _checkbox.value,
                  onChanged: (value) {
                    print(value);
                    setState(() {
                      _checkbox.value = value;
                    });
                  }),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // 이미지 업로드 기능을 추가하세요.
                  final ImagePicker _picker = ImagePicker();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 500,
                    maxHeight: 500,
                    imageQuality: 80,
                  );
                  setState(() {
                    _mediaFile = pickedFile;
                  });
                },
                child: Text('Gallery'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 이미지 업로드 기능을 추가하세요.
                  final ImagePicker _picker = ImagePicker();
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 500,
                    maxHeight: 500,
                    imageQuality: 80,
                  );
                  setState(() {
                    _mediaFile = pickedFile;
                  });
                },
                child: Text('Camera'),
              ),
              ElevatedButton(
                onPressed: () async {
                  var result = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(Constant.APP_NAME),
                          content: const SizedBox(
                            height: 200,
                            child: Column(
                              children: [
                                Text(
                                    'Would you like to post? 10 points will be deducted, and sending a push message will result in an additional 5 points being deducted.'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Get.back(result: false);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back(result: true);
                              },
                              child: Text('Confirm'),
                            ),
                          ],
                        );
                      });

                  if (result) {
                    bool writeCheck = true;
                    await FirebaseFirestore.instance
                        .collection('craftyusers')
                        .doc(user.email)
                        .get()
                        .then((value) {
                      if (!value.data()!.containsKey('points')) {
                        Get.snackbar(Constant.APP_NAME, 'There are no points');
                        return;
                      }
                      int point = value['points'];
                      if (_checkbox.isTrue) {
                        if (point >= 15) {
                          FirebaseFirestore.instance
                              .collection('craftyusers')
                              .doc(user.email)
                              .update({
                            'points': FieldValue.increment(-15),
                          });
                        } else {
                          Get.snackbar(Constant.APP_NAME, 'Not enough points.');
                          writeCheck = false;
                        }
                      } else {
                        if (point >= 10) {
                          FirebaseFirestore.instance
                              .collection('craftyusers')
                              .doc(user.email)
                              .update({
                            'points': FieldValue.increment(-10),
                          });
                        } else {
                          Get.snackbar(Constant.APP_NAME, 'Not enough points.');
                          writeCheck = false;
                        }
                      }
                    });
                    if (writeCheck == true) {
                      final content = _textEditingController.text.trim();

                      bool resultCode = await hobbyContentCheck(
                          File(_mediaFile!.path),
                          content,
                          craftyKind[_selectedItem]!);

                      if (resultCode == true) {
                        final title = _titleTextEditingController.text.trim();
                        final price = _priceEditingController.text.trim();
                        final tag = _tagtextEditingController.text.trim();
                        if (content.isEmpty) {
                          return;
                        }
                        String downloadurl = '';
                        if (_mediaFile != null) {
                          downloadurl =
                              await uploadFile(File(_mediaFile!.path));
                        }
                        final post = {
                          'id': const Uuid().v1(),
                          'user': user.email,
                          'price': price,
                          'content': content,
                          'title': title,
                          'image': downloadurl,
                          'sell': false,
                          'kind': _selectedItem,
                          'tag': getTag(tag.split(",")),
                          'timestamp': FieldValue.serverTimestamp(),
                        };
                        await FirebaseFirestore.instance
                            .collection('crafty')
                            .add(post)
                            .then((value) {
                          _textEditingController.clear();
                          _priceEditingController.clear();
                          _tagtextEditingController.clear();
                          Get.snackbar(Constant.APP_NAME, 'Upload Success');
                          if (_checkbox.isTrue) {
                            http
                                .post(
                              Uri.parse(
                                  'https://us-central1-example-20efe.cloudfunctions.net/sendPostNotification'),
                              headers: <String, String>{
                                'Content-Type':
                                    'application/json; charset=UTF-8',
                              },
                              body: jsonEncode(<String, dynamic>{
                                'title':
                                    _titleTextEditingController.text.trim(),
                                'link': value.id
                              }),
                            )
                                .then((value) {
                              Get.back();
                            });
                          }
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(Constant.APP_NAME),
                              content: Text(
                                  "이 이미지는 구글AI에 의해 알맞지 않은 내용으로 노출을 제한합니다."),
                              actions: <Widget>[
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('upload'),
              )
            ],
          ),
        ],
      ),
    );
  }


  Future<bool> hobbyContentCheck(
      File image, String content, String kind) async {
    final generationConfig = GenerationConfig(
      responseMimeType: 'application/json',
    );
    _currentModel = googleAI.generativeModel(model: 'gemini-2.0-flash' ,generationConfig: generationConfig);

    // Prepare image data
    final imageBytes = await image.readAsBytes();

    // Craft a detailed prompt for Gemini
    final prompt = TextPart("""
  당신은 콘텐츠 관련성 평가 전문가입니다.
  이미지와 텍스트 $content를 받으면, 그 내용이 $kind와 관련이 있는지 평가하고, 결과를 JSON 형식으로 반환해야 합니다.
  반환할 JSON의 형식은 다음과 같아야 합니다.
  "{
    "result": "true" 또는 "false",
    "issue": "평가 결과에 대한 설명 ($kind와 관련이 없다면 이유를 상세히 설명)"
  }"
  참고:
  - "result"는 $content가 $kind와 관련이 있으면 "true", 그렇지 않으면 "false"여야 합니다.
  - "issue"는 평가 결과에 대한 설명입니다. 만약 "result"가 "false"라면, 왜 관련이 없는지 그 이유를 명확하게 작성해야 합니다.
  - 출력은 반드시 유효한 JSON 문자열만 포함해야 합니다. 그 외의 텍스트는 포함할 수 없습니다.
""");

    final imagePart = InlineDataPart('image/jpeg', imageBytes);

    final response = await _currentModel.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final generatedContent = response.text?.trim();
    print("generated Content $generatedContent" );
    if (generatedContent != null) {
      final Map<String, dynamic> jsonData = jsonDecode(generatedContent);
// 결과 및 이슈 추출
      final dynamic resultValue = jsonData['result'];
      final String? issue = jsonData['issue'];

      bool isSuccess;
      if (resultValue is bool) {
        isSuccess = resultValue;
      } else if (resultValue is String) {
        isSuccess = resultValue.toLowerCase() == 'true';
      } else {
        print('알 수 없는 result 타입입니다: ${resultValue?.runtimeType}');
        return false;
      }

      if (isSuccess) {
        // 콘텐츠가 안전하고 관련성이 높은 경우
        print('콘텐츠가 승인되었습니다.');
        return true; // 최종 결과 반환
      } else {
        // 콘텐츠가 안전하지 않거나 관련성이 낮은 경우
        print('콘텐츠가 거부되었습니다. 이유: $issue');
        return false; // 최종 결과 반환
      }
    } else {
      return false;
    }
  }


  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file) async {
    String downloadURL = '';
    try {
      String fileName = basename(file.path);
      Reference reference = storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      downloadURL = await taskSnapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      print(e.toString());
    }
    return downloadURL;
  }

  getTag(List<String> split) {
    List<String> tags = List.empty(growable: true);
    split.forEach((element) {
      if (element.isNotEmpty) {
        tags.add(element);
      }
    });
    return tags;
  }
}
