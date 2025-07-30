import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/utils/utils.dart';
import 'package:quizapp/views/play/presentpage.dart';

class WaitingPage extends StatefulWidget {
  static const String route = '/play/waiting';

  final Client client;
  const WaitingPage({super.key, required this.client});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  String gameID = '';
  int gameCode = -1;
  Quiz quiz = Quiz.empty();
  List<String> players = [];
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;
    if (gameID.isEmpty || gameCode == -1 || quiz == Quiz.empty()) {
      final newGameID = arguments['gameID'];
      final newGameCode = arguments['gameCode'];
      final newQuiz = arguments['quiz'];
      getPlayers(client: widget.client, gameID: newGameID).then((value) {
        Realtime realtime = Realtime(widget.client);
        realtime
            .subscribe([
              'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.$newGameID',
            ])
            .stream
            .listen((event) {
              if (event.events.contains(
                'databases.6859582600031c46e49c.collections.685990a30018382797dc.documents.$newGameID',
              )) {
                getPlayers(client: widget.client, gameID: newGameID).then((
                  newValue,
                ) {
                  setState(() {
                    players = newValue;
                  });
                });
              }
            });
        setState(() {
          gameID = newGameID ?? '';
          gameCode = newGameCode ?? -1;
          players = value;
          quiz = newQuiz ?? Quiz.empty();
        });
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting for Players'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await goToNextQuestion(
            client: widget.client,
            gameID: gameID,
            currentQuestion: Question.empty()..questionIndex = -1,
          );
          Navigator.pushNamed(
            context,
            PresentPage.route,
            arguments: {'quiz': quiz, 'code': gameCode, 'gameID': gameID},
          );
        },
        tooltip: 'Start Game',
        child: const Icon(Icons.arrow_forward),
      ),
      body: Column(
        children: [
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Game Code: ',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  TextSpan(
                    text: gameCode.toString().spaceSeparateNumbers(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: players
                .map(
                  (player) => Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        player,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Currently ${players.length} ${'player'.pluralize(players.length)} joined.'
          '\n'
          'Waiting for players to join...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
