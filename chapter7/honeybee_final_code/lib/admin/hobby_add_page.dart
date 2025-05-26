import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:honeybee/view/hobby/ChatScreen.dart';

class HobbyAddPage extends StatelessWidget {
  final databaseReference = FirebaseDatabase.instance.ref();

  final hobbyKeyController = TextEditingController();
  final hobbyValueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Data'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: hobbyKeyController,
              decoration: InputDecoration(
                labelText: 'Key',
              ),
            ),
            TextField(
              controller: hobbyValueController,
              decoration: InputDecoration(
                labelText: 'Value',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context){
                  return ChatScreen(hobby: '목공예',);
                }));

                final hobby = hobbyKeyController.text;
                final hobbykr = hobbyValueController.text;
                databaseReference.child('hobby').push().set({
                  'key': hobby,
                  'value': hobbykr,
                  'showing': true,
                });
              },
              child: Text('Add Data'),
            ),
          ],
        ),
      ),
    );
  }
}