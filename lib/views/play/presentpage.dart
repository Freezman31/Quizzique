import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/views/play/finalpodiumpage.dart';
import 'package:quizzique/views/play/podiumpage.dart';
import 'package:quizzique/widgets/countdown.dart';
import 'package:quizzique/widgets/question_types_edit/four_options.dart';
import 'package:quizzique/widgets/question_types_edit/guess.dart';
import 'package:quizzique/widgets/question_types_edit/two_options.dart';

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
  int questionIndex = 0;
  Quiz quiz = Quiz.empty();
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;
    if (q == Question.empty()) {
      setState(() {
        questionIndex = arguments['currentQuestionIndex'] ?? 0;
        quiz = arguments['quiz'] as Quiz;
        q = quiz.questions[questionIndex];
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
              child: switch (q.type) {
                QuestionType.fourChoices => FourOptions(
                  buttonHeight: MediaQuery.of(context).size.height * 0.1,
                  currentQuestion: q,
                  editMode: false,
                ),
                QuestionType.twoChoices => TwoOptions(
                  buttonHeight: MediaQuery.of(context).size.height * 0.1,
                  currentQuestion: q,
                  editMode: false,
                ),
                QuestionType.guess => Guess(
                  buttonHeight: MediaQuery.of(context).size.height * 0.1,
                  currentQuestion: q,
                  editMode: false,
                ),
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (questionIndex == quiz.questions.length - 1) {
            await endGame(client: widget.client, gameID: gameID);
            Navigator.pushNamed(
              context,
              FinalPodiumPage.route,
              arguments: {
                'gameID': gameID,
                'currentQuestion': q,
                'code': arguments['code'],
                'quiz': quiz,
                'currentQuestionIndex': questionIndex,
              },
            );
            return;
          }
          Navigator.pushNamed(
            context,
            PodiumPage.route,
            arguments: {
              'gameID': gameID,
              'currentQuestion': q,
              'code': arguments['code'],
              'quiz': quiz,
              'currentQuestionIndex': questionIndex,
            },
          );
        },
        tooltip: 'Next',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
