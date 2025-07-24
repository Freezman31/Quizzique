import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/views/play/podiumpage.dart';
import 'package:quizapp/widgets/countdown.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class PresentPage extends StatefulWidget {
  static const String route = '/play/present';
  final Client client;
  const PresentPage({super.key, required this.client});

  @override
  State<PresentPage> createState() => _PresentPageState();
}

class _PresentPageState extends State<PresentPage> {
  Question q = Question.empty();
  String gameID = '';
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;
    if (q == Question.empty()) {
      setState(() {
        q = (arguments['quiz'] as Quiz).questions.first;
        gameID = arguments['gameID'];
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                q.question,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.all(16),
                  child: Countdown(
                    duration: q.duration,
                    durationBeforeAnswer: q.durationBeforeAnswer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    flex: 10,
                    child: Row(
                      children: [
                        Spacer(),
                        Expanded(
                          flex: 10,
                          child: QuizButton(
                            onPressed: () {},
                            label: q.answers[0],
                            symbol: Symbols.square,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 10,
                          child: QuizButton(
                            onPressed: () {},
                            label: q.answers[1],
                            symbol: Symbols.circle,
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 10,
                    child: Row(
                      children: [
                        Spacer(),
                        Expanded(
                          flex: 10,
                          child: QuizButton(
                            onPressed: () {},
                            label: q.answers[2],
                            symbol: Symbols.triangle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 10,
                          child: QuizButton(
                            onPressed: () {},
                            label: q.answers[3],
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            PodiumPage.route,
            arguments: {
              'gameID': gameID,
              'currentQuestion': q,
              'code': arguments['code'],
            },
          );
        },
        tooltip: 'Next',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
