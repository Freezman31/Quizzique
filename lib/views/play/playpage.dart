import 'dart:convert';
import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/constants.dart';
import 'package:quizzique/utils/utils.dart';
import 'package:quizzique/views/homepage.dart';
import 'package:quizzique/widgets/quiz_button.dart';

class PlayPage extends StatefulWidget {
  static const String route = '/play/quiz';
  final Client client;
  const PlayPage({super.key, required this.client});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  Question q = Question.empty();
  Realtime? realtime;
  DateTime? lastUpdate;
  String username = '';
  late final RealtimeSubscription sub;
  late int value = q.type == QuestionType.guess
      ? (int.parse(q.answers[0]) + int.parse(q.answers[1]) ~/ 2)
      : 0;

  @override
  void dispose() {
    sub.close();
    super.dispose();
  }

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
        Logger().i('Subscribing to question updates for game ID: ${v.gameID}');

        sub = realtime!.subscribe([
          'databases.${Constants.databaseId}.tables.${Constants.gamesTableId}.rows.${v.gameID}',
        ]);
        sub.stream.listen((event) {
          if (event.events.contains(
                'databases.${Constants.databaseId}.tables.${Constants.gamesTableId}.rows.${v.gameID}',
              ) &&
              jsonDecode(event.payload['currentQuestion'])['id'] !=
                  q.questionID &&
              jsonDecode(event.payload['currentQuestion'])['i'] !=
                  q.questionIndex) {
            Logger().i('Current question ID: ${q.questionID}');
            if (!ModalRoute.of(context)!.isCurrent) {
              Navigator.pop(context);
            }
            getCurrentQuestion(
              client: widget.client,
              code: arguments['code'] ?? 0,
            ).then((v) {
              wait(false, v.durationBeforeAnswer);
              setState(() {
                q = v;
              });
            });
          } else if (event.events.contains(
                'databases.${Constants.databaseId}.tables.${Constants.gamesTableId}.rows.${v.gameID}',
              ) &&
              event.payload['ended'] == true) {
            Logger().i('Game ended, navigating to results page.');
            result(context: context, client: widget.client, gameID: v.gameID);
          }
        });
        setState(() {
          username = arguments['username'] ?? '';
          wait(true, 0);
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
                  'Choose an answer !',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            ...switch (q.type) {
              QuestionType.fourChoices => fourOptions(
                context: context,
                q: q,
                client: widget.client,
                username: username,
                lastUpdate: lastUpdate,
              ),
              QuestionType.twoChoices => twoOptions(
                context: context,
                q: q,
                client: widget.client,
                username: username,
                lastUpdate: lastUpdate,
              ),
              QuestionType.guess => guess(
                context: context,
                q: q,
                client: widget.client,
                username: username,
                lastUpdate: lastUpdate,
                value: value,
                valueUpdate: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            },
          ],
        ),
      ),
    );
  }

  void wait(bool waitingStart, int durationInSeconds) {
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
                  waitingStart
                      ? 'Wait for the game to start!'
                      : 'Look at the question and choose an answer!',
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
    if (!waitingStart) {
      Future.delayed(Duration(seconds: durationInSeconds), () {
        if (!ModalRoute.of(context)!.isCurrent) {
          Navigator.pop(context);
        }
      }).then((_) {
        lastUpdate = DateTime.now();
      });
    }
  }
}

void loading({required BuildContext context}) {
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
                'Loading...',
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
}

void answerResult({
  required BuildContext context,
  required AnswerResponse response,
  required Question q,
  required DateTime? lastUpdate,
}) {
  Future.delayed(
    Duration(
      milliseconds: max(
        q.duration * 1000 -
            (DateTime.now().difference(lastUpdate!).inMilliseconds),
        0,
      ),
    ),
    () {
      if (!ModalRoute.of(context)!.isCurrent) {
        Navigator.pop(context);
      }
      showDialog(
        context: context,
        builder: (context) {
          final MediaQueryData mq = MediaQuery.of(context);
          return AlertDialog(
            title: Text(
              response.status == AnswerStatus.correct
                  ? 'You Win!'
                  : response.status == AnswerStatus.incorrect
                  ? 'You Lose!'
                  : response.status == AnswerStatus.tooLate
                  ? 'Too Late!'
                  : 'Already Answered',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: mq.size.width * 0.8,
              height: mq.size.height * 0.4,
              child: Column(
                children: [
                  Text(
                    response.status == AnswerStatus.correct
                        ? 'Congratulations! You answered correctly. You won ${response.score} points!'
                        : response.status == AnswerStatus.incorrect
                        ? 'Sorry, that was incorrect.'
                        : response.status == AnswerStatus.tooLate
                        ? 'Sorry, you took too long to answer.'
                        : 'You have already answered this question.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Expanded(
                    child: Icon(
                      response.status == AnswerStatus.correct
                          ? Icons.check_circle
                          : response.status == AnswerStatus.incorrect
                          ? Icons.cancel
                          : response.status == AnswerStatus.tooLate
                          ? Icons.hourglass_empty
                          : Icons.warning,
                      color: response.status == AnswerStatus.correct
                          ? Colors.green
                          : response.status == AnswerStatus.incorrect
                          ? Colors.red
                          : response.status == AnswerStatus.tooLate
                          ? Colors.orange
                          : Colors.grey,
                      size: mq.size.height * 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        barrierDismissible: false,
      );
    },
  );
}

void result({
  required BuildContext context,
  required Client client,
  required String gameID,
}) async {
  final score = await getPlayerScore(client: client, gameID: gameID);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Podium'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  text: 'You finished in the ',
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    TextSpan(
                      text: '${score.ranking?.ordinate()} place',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: score.ranking == 1
                                ? Color(0xffFFD700)
                                : score.ranking == 2
                                ? Color(0xffc0c0c0)
                                : score.ranking == 3
                                ? Color(0xffcd7f32)
                                : Colors.black,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.settings.name == HomePage.route,
                  );
                },
                child: Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<Widget> fourOptions({
  required BuildContext context,
  required Question q,
  required Client client,
  required String username,
  required DateTime? lastUpdate,
}) {
  return [
    Expanded(
      flex: 3,
      child: Row(
        children: [
          Expanded(
            child: QuizButton(
              onPressed: () async {
                loading(context: context);
                answerResult(
                  lastUpdate: lastUpdate,
                  q: q,
                  context: context,
                  response: await q.answer(
                    client: client,
                    answerIndex: 0,
                    playerName: username,
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
                loading(context: context);
                answerResult(
                  lastUpdate: lastUpdate,
                  q: q,
                  context: context,
                  response: await q.answer(
                    client: client,
                    answerIndex: 1,
                    playerName: username,
                  ),
                );
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
              onPressed: () async {
                loading(context: context);
                answerResult(
                  lastUpdate: lastUpdate,
                  q: q,
                  context: context,
                  response: await q.answer(
                    client: client,
                    answerIndex: 2,
                    playerName: username,
                  ),
                );
              },
              label: '',
              symbol: Symbols.triangle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: QuizButton(
              onPressed: () async {
                loading(context: context);
                answerResult(
                  context: context,
                  lastUpdate: lastUpdate,
                  q: q,
                  response: await q.answer(
                    client: client,
                    answerIndex: 3,
                    playerName: username,
                  ),
                );
              },
              label: '',
              symbol: Symbols.diamond,
            ),
          ),
        ],
      ),
    ),
  ];
}

List<Widget> twoOptions({
  required BuildContext context,
  required Question q,
  required Client client,
  required String username,
  required DateTime? lastUpdate,
}) {
  return [
    Expanded(
      flex: 3,
      child: Row(
        children: [
          Expanded(
            child: QuizButton(
              onPressed: () async {
                loading(context: context);
                answerResult(
                  lastUpdate: lastUpdate,
                  q: q,
                  context: context,
                  response: await q.answer(
                    client: client,
                    answerIndex: 0,
                    playerName: username,
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
                loading(context: context);
                answerResult(
                  lastUpdate: lastUpdate,
                  q: q,
                  context: context,
                  response: await q.answer(
                    client: client,
                    answerIndex: 1,
                    playerName: username,
                  ),
                );
              },
              label: '',
              symbol: Symbols.circle,
            ),
          ),
        ],
      ),
    ),
  ];
}

List<Widget> guess({
  required BuildContext context,
  required Question q,
  required Client client,
  required String username,
  required DateTime? lastUpdate,
  required Function(int) valueUpdate,
  required int value,
}) {
  final theme = Theme.of(context);
  final TextEditingController valueController = TextEditingController(
    text: value.toString(),
  );
  return [
    Expanded(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackShape: RoundedRectSliderTrackShape(),
          trackHeight: 4.0,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
          tickMarkShape: RoundSliderTickMarkShape(),
          activeTrackColor: theme.colorScheme.secondary.withAlpha(200),
          valueIndicatorShape: DropSliderValueIndicatorShape(),
          valueIndicatorTextStyle: theme.textTheme.labelLarge!.copyWith(
            color: theme.colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
          showValueIndicator: ShowValueIndicator.alwaysVisible,
        ),
        child: Slider(
          value: value.toDouble(),
          min: double.parse(q.answers[0]),
          max: double.parse(q.answers[1]),
          label: '${value.toInt()}',
          onChanged: (newValue) {
            valueUpdate(newValue.toInt());
          },
        ),
      ),
    ),
    SizedBox(height: 20),
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Answer',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          counterText: '',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        controller: valueController,
        onTap: () {
          valueController.selection = TextSelection.fromPosition(
            TextPosition(offset: valueController.text.length),
          );
        },
        onChanged: (value) {
          if (int.parse(value) > int.parse(q.answers[1])) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Value must be less than max.'),
                duration: Duration(seconds: 2),
              ),
            );
            valueController.text = (int.parse(q.answers[1])).toString();
            valueController.selection = TextSelection.fromPosition(
              TextPosition(offset: valueController.text.length),
            );
          } else if (int.parse(value) < int.parse(q.answers[0])) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Value must be greater than min.'),
                duration: Duration(seconds: 2),
              ),
            );
            valueController.text = (int.parse(q.answers[0])).toString();
            valueController.selection = TextSelection.fromPosition(
              TextPosition(offset: valueController.text.length),
            );
          }
          valueUpdate(int.parse(valueController.text));
        },
      ),
    ),
    SizedBox(height: 20),
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.1,
      child: ElevatedButton(
        onPressed: () async {
          loading(context: context);
          answerResult(
            lastUpdate: lastUpdate,
            q: q,
            context: context,
            response: await q.answer(
              client: client,
              answerIndex: value,
              playerName: username,
            ),
          );
        },
        child: Text('Submit!'),
      ),
    ),
  ];
}
