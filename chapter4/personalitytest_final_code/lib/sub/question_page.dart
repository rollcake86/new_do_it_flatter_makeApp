import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../detail/detail_page.dart';

class QuestionPage extends StatefulWidget {
  final Map<String , dynamic> question;

  const QuestionPage({super.key, required this.question});

  @override
  State<StatefulWidget> createState() {
    return _QuestionPage();
  }
}

class _QuestionPage extends State<QuestionPage> {
  String title = '';
  int? selectedOption; // null safety 적용

  @override
  void initState() {
    super.initState();
    title = widget.question['title'] as String; // initState에서 title 설정
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question['question'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: (widget.question['selects'] as List<dynamic>).length,
                itemBuilder: (context, index) {
                  return RadioListTile<int>(
                    title: Text(widget.question['selects'][index] as String),
                    value: index,
                    groupValue: selectedOption,
                    onChanged: (int? value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: selectedOption == null
                    ? null
                    : () async {
                  try {
                    await FirebaseAnalytics.instance.logEvent(
                      name: "personal_select",
                      parameters: {
                        "test_name": title,
                        "select": selectedOption ?? 0,
                      },
                    );
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          answer: widget.question['answer'][selectedOption],
                          question: widget.question['question'],
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Failed to log event: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('성격 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}