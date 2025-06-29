import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class PlayPage extends StatefulWidget {
  final Client client;
  const PlayPage({super.key, required this.client});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  Question q = Question.empty();
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;
    Realtime realtime = Realtime(widget.client);
    if (q == Question.empty()) {
      getCurrentQuestion(
        client: widget.client,
        code: arguments['code'] ?? 0,
      ).then((v) {
        realtime
            .subscribe([
              'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.${v.gameID}',
            ])
            .stream
            .listen((event) {
              if (event.events.contains(
                'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.*',
              )) {
                getCurrentQuestion(
                  client: widget.client,
                  code: arguments['code'] ?? 0,
                ).then((v) {
                  setState(() {
                    q = v;
                  });
                });
              }
            });
        setState(() {
          q = v;
        });
      });
    }
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Choose an answer ! ${q.questionID}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: QuizButton(
                      onPressed: () async {
                        result(
                          context: context,
                          correct: await q.answer(
                            client: widget.client,
                            answerIndex: 1,
                          ),
                        );
                      },
                      label: '',
                      symbol: Symbols.square,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuizButton(
                      onPressed: () async {
                        await q.answer(client: widget.client, answerIndex: 2);
                      },
                      label: '',
                      symbol: Symbols.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: QuizButton(
                      onPressed: () {
                        q.answer(client: widget.client, answerIndex: 3);
                      },
                      label: '',
                      symbol: Symbols.triangle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuizButton(
                      onPressed: () {
                        q.answer(client: widget.client, answerIndex: 4);
                      },
                      label: '',
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

void result({required BuildContext context, required bool correct}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(correct ? 'You Win!' : 'You Lose!'),
        content: Text(
          correct
              ? 'Congratulations! You answered correctly.'
              : 'Sorry, that was incorrect.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
