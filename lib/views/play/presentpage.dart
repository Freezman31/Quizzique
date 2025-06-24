import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class PresentPage extends StatefulWidget {
  final Client client;
  const PresentPage({super.key, required this.client});

  @override
  State<PresentPage> createState() => _PresentPageState();
}

class _PresentPageState extends State<PresentPage> {
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
                          flex: 7,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 1',
                            height: mq.size.height * 0.14,
                            symbol: Symbols.square,
                          ),
                        ),
                        Spacer(),
                        Expanded(
                          flex: 7,
                          child: QuizButton(
                            onPressed: () {},
                            label:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                            height: mq.size.height * 0.14,
                            symbol: Symbols.circle,
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
                          flex: 7,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 3',
                            height: mq.size.height * 0.14,
                            symbol: Symbols.triangle,
                          ),
                        ),
                        Spacer(),
                        Expanded(
                          flex: 7,
                          child: QuizButton(
                            onPressed: () {},
                            label: 'Answer 4',
                            height: mq.size.height * 0.14,
                            symbol: Symbols.diamond,
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
