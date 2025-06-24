import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class Playpage extends StatefulWidget {
  final Client client;
  const Playpage({super.key, required this.client});

  @override
  State<Playpage> createState() => _PlaypageState();
}

class _PlaypageState extends State<Playpage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Page with space for question and 4 buttons for answers
    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.blueGrey,
                child: const Text(
                  'Question will be displayed here',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    flex: 10,
                    child: Row(
                      children: [
                        Spacer(),
                        Expanded(
                          flex: 5,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 1',
                            height: mq.size.height * 0.1,
                          ),
                        ),
                        Spacer(),
                        Expanded(
                          flex: 5,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 2',
                            height: mq.size.height * 0.1,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    flex: 10,
                    child: Row(
                      children: [
                        Spacer(),
                        Expanded(
                          flex: 5,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 3',
                            height: mq.size.height * 0.1,
                          ),
                        ),
                        Spacer(),
                        Expanded(
                          flex: 5,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 4',
                            height: mq.size.height * 0.1,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
