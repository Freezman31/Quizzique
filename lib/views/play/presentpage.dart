import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class PresentPage extends StatefulWidget {
  final Client client;
  const PresentPage({super.key, required this.client});

  @override
  State<PresentPage> createState() => _PresentPageState();
}

class _PresentPageState extends State<PresentPage> {
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
    // Page with space for question and 4 buttons for answers
    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                q.question,
                style: Theme.of(context).textTheme.headlineLarge,
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
    );
  }
}
