import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/views/play/presentpage.dart';
import 'package:quizapp/widgets/score_view.dart';

class PodiumPage extends StatefulWidget {
  static const String route = '/play/podium';
  final Client client;
  const PodiumPage({super.key, required this.client});

  @override
  State<PodiumPage> createState() => _PodiumPageState();
}

class _PodiumPageState extends State<PodiumPage> {
  List<Score> podium = [];
  Quiz quiz = Quiz.empty();
  int questionIndex = 0;
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;

    if (podium.isEmpty) {
      getPodium(client: widget.client, gameID: arguments['gameID'] ?? '').then((
        pod,
      ) {
        setState(() {
          quiz = arguments['quiz'] as Quiz;
          questionIndex = arguments['currentQuestionIndex'] ?? 0;
          podium = pod;
        });
      });
    }
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Current podium:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (podium.isNotEmpty)
              SizedBox(
                height: mq.size.height * 0.5,
                width: mq.size.width * 0.8,
                child: ListView.builder(
                  itemCount: podium.length,
                  itemBuilder: (context, index) {
                    final score = podium[index];
                    return ScoreView(score: score, rank: index + 1);
                  },
                ),
              )
            else
              SizedBox(
                height: mq.size.height * 0.5,
                width: mq.size.width * 0.8,
                child: Column(
                  children: [
                    const Text('Loading...', style: TextStyle(fontSize: 18)),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          goToNextQuestion(
            client: widget.client,
            gameID: arguments['gameID'],
            currentQuestion: arguments['currentQuestion'],
          ).then(
            (_) => Navigator.of(context).popAndPushNamed(
              PresentPage.route,
              arguments: {
                'code': arguments['code'],
                'gameID': arguments['gameID'],
                'quiz': quiz,
                'currentQuestionIndex': questionIndex + 1, // Next question
              },
            ),
          );
        },
        tooltip: 'Next Question',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
