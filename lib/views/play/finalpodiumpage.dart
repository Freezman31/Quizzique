import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/avatars.dart';
import 'package:quizzique/views/homepage.dart';
import 'package:quizzique/widgets/score_view.dart';

class FinalPodiumPage extends StatefulWidget {
  static const String route = '/play/finalpodium';

  final Client client;
  const FinalPodiumPage({super.key, required this.client});

  @override
  State<FinalPodiumPage> createState() => _FinalPodiumPageState();
}

class _FinalPodiumPageState extends State<FinalPodiumPage> {
  List<Score> podium = [];
  Quiz quiz = Quiz.empty();
  int questionIndex = 0;
  String gameID = '';
  @override
  Widget build(BuildContext context) {
    final arguments =
        (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{})
            as Map;

    if (podium.isEmpty) {
      getScores(client: widget.client, gameID: arguments['gameID'] ?? '').then((
        pod,
      ) {
        setState(() {
          quiz = arguments['quiz'] as Quiz;
          questionIndex = arguments['currentQuestionIndex'] ?? 0;
          podium = pod;
          gameID = arguments['gameID'] ?? '';
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
            if (podium.isNotEmpty)
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (podium.length > 1)
                      Container(
                        color: Color(0xffc0c0c0),
                        height: mq.size.height * 0.25,
                        width: mq.size.width * 0.3,
                        child: Column(
                          children: [
                            Text(
                              podium[1].playerName,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              podium[1].score.toString(),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            Image(
                              image: ResizeImage(
                                AssetImage(
                                  avatarToFile(avatar: podium[1].avatar),
                                ),
                                policy: ResizeImagePolicy.fit,
                                height: (mq.size.height * 0.125).toInt(),
                                width: (mq.size.height * 0.125).toInt(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      height: mq.size.height * 0.3,
                      width: mq.size.width * 0.3,
                      color: Color(0xffFFD700),
                      child: Column(
                        children: [
                          Text(
                            podium[0].playerName,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            podium[0].score.toString(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          Image(
                            image: ResizeImage(
                              AssetImage(
                                avatarToFile(avatar: podium[0].avatar),
                              ),
                              policy: ResizeImagePolicy.fit,
                              height: (mq.size.height * 0.15).toInt(),
                              width: (mq.size.height * 0.15).toInt(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (podium.length > 2)
                      Container(
                        color: Color(0xffcd7f32),
                        height: mq.size.height * 0.2,
                        width: mq.size.width * 0.3,
                        child: Column(
                          children: [
                            Text(
                              podium[2].playerName,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              podium[2].score.toString(),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            Image(
                              image: ResizeImage(
                                AssetImage(
                                  avatarToFile(avatar: podium[2].avatar),
                                ),
                                policy: ResizeImagePolicy.fit,
                                height: (mq.size.height * 0.1).toInt(),
                                width: (mq.size.height * 0.1).toInt(),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (podium.isNotEmpty)
              Expanded(
                child: SizedBox(
                  height: mq.size.height * 0.5,
                  width: mq.size.width * 0.8,
                  child: ListView.builder(
                    itemCount: podium.length,
                    itemBuilder: (context, index) {
                      final score = podium[index];
                      return ScoreView(score: score, rank: index + 1);
                    },
                  ),
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
        onPressed: () async {
          await deleteGame(client: widget.client, gameID: gameID);
          Navigator.of(context).popUntil((route) {
            return route.settings.name == HomePage.route;
          });
        },
        tooltip: 'Finish',
        child: const Icon(Icons.sports_score),
      ),
    );
  }
}
