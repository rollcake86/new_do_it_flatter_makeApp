import 'package:flutter/material.dart';
import 'package:honeybee/view/hobby/Chatbot.dart';

class ChatScreen extends StatefulWidget {
  final hobby;

  const ChatScreen({super.key, this.hobby});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];
  late ChatBot chatBot;

  @override
  void initState() {
    super.initState();
    chatBot = ChatBot(widget.hobby);
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _messages.add(_textController.text);
        chatBot.sendPost(_textController.text).then((result){
          if(result != null){
            setState(() {
              _messages.add(result);
            });
          } else{
            setState(() {
              _messages.add("데이터가 없습니다");
            });
          }
        });
        _textController.clear();
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(_messages[index]),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}