import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class PlayPage extends StatefulWidget {
  final Client client;
  const PlayPage({super.key, required this.client});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: QuizButton(
                      onPressed: () {},
                      label: '',
                      height: mq.size.height * .5,
                      symbol: Symbols.square,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuizButton(
                      onPressed: () {},
                      label: '',
                      height: mq.size.height * .5,
                      symbol: Symbols.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: QuizButton(
                      onPressed: () {},
                      label: '',
                      height: mq.size.height * .5,
                      symbol: Symbols.triangle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuizButton(
                      onPressed: () {},
                      label: '',
                      height: mq.size.height * .5,
                      symbol: Symbols.diamond,
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
