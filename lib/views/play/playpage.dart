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
  Realtime? realtime;
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;
    realtime ??= Realtime(widget.client);
    if (q == Question.empty()) {
      getCurrentQuestion(
        client: widget.client,
        code: arguments['code'] ?? 0,
      ).then((v) {
        realtime!
            .subscribe([
              'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.${v.gameID}',
            ])
            .stream
            .listen((event) {
              if (event.events.contains(
                'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.${v.gameID}',
              )) {
                if (!ModalRoute.of(context)!.isCurrent) {
                  Navigator.pop(context);
                }
                getCurrentQuestion(
                  client: widget.client,
                  code: arguments['code'] ?? 0,
                ).then((v) {
                  wait();
                  setState(() {
                    q = v;
                  });
                });
              }
            });
        setState(() {
          wait();
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
                          response: await q.answer(
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

  void wait() {
    showDialog(
      context: context,
      builder: (context) {
        final MediaQueryData mq = MediaQuery.of(context);
        return AlertDialog(
          content: SizedBox(
            width: mq.size.width * 0.8,
            height: mq.size.height * 0.4,
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'Look at the question and choose an answer!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: mq.size.height * 0.2,
                    height: mq.size.height * 0.2,
                    child: CircularProgressIndicator(),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
      barrierDismissible: false,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!ModalRoute.of(context)!.isCurrent) {
        Navigator.pop(context);
      }
    });
  }
}

void result({required BuildContext context, required AnswerResponse response}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          response.status == AnswerStatus.correct
              ? 'You Win!'
              : response.status == AnswerStatus.incorrect
              ? 'You Lose!'
              : response.status == AnswerStatus.tooLate
              ? 'Too Late!'
              : 'Already Answered',
        ),
        content: Text(
          response.status == AnswerStatus.correct
              ? 'Congratulations! You answered correctly. You won ${response.score} points!'
              : response.status == AnswerStatus.incorrect
              ? 'Sorry, that was incorrect.'
              : response.status == AnswerStatus.tooLate
              ? 'Sorry, you took too long to answer.'
              : 'You have already answered this question.',
        ),
      );
    },
    barrierDismissible: false,
  );
}
