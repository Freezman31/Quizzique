import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/constants.dart';
import 'package:quizzique/utils/utils.dart';
import 'package:quizzique/views/play/presentpage.dart';

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
              'databases.${Constants.databaseId}.collections.${Constants.gamesCollectionId}.documents.$newGameID',
            ])
            .stream
            .listen((event) {
              if (event.events.contains(
                'databases.${Constants.databaseId}.collections.${Constants.gamesCollectionId}.documents.$newGameID',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Game Code: ',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      TextSpan(
                        text: gameCode.toString().spaceSeparateNumbers(),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final MediaQueryData mq = MediaQuery.of(context);
                        final double size = min(
                          mq.size.width * 0.6,
                          mq.size.height * 0.6,
                        );
                        return AlertDialog(
                          insetPadding: EdgeInsets.zero,
                          contentPadding: EdgeInsets.zero,
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                          ],
                          actionsPadding: EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          content: Container(
                            margin: EdgeInsets.all(32),
                            width: size,
                            height: size,
                            child: QrImageView(
                              data:
                                  '${Constants.url}${Constants.port != '' ? ':${Constants.port}' : ''}/play/customization?code=${gameCode.toString()}',
                              version: QrVersions.auto,
                              padding: EdgeInsets.zero,
                              eyeStyle: QrEyeStyle(
                                color:
                                    View.of(context)
                                            .platformDispatcher
                                            .platformBrightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                eyeShape: QrEyeShape.square,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                color:
                                    View.of(context)
                                            .platformDispatcher
                                            .platformBrightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                dataModuleShape: QrDataModuleShape.square,
                              ),
                              size: size,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: QrImageView(
                    data:
                        '${Constants.url}:${Constants.port}/play/customization?code=${gameCode.toString()}',
                    size: 100,
                    version: QrVersions.auto,
                    padding: const EdgeInsets.all(8),
                    eyeStyle: QrEyeStyle(
                      color:
                          View.of(
                                context,
                              ).platformDispatcher.platformBrightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      eyeShape: QrEyeShape.square,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      color:
                          View.of(
                                context,
                              ).platformDispatcher.platformBrightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                ),
              ],
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
