import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/widgets/score_view.dart';

class PodiumPage extends StatefulWidget {
  final Client client;
  const PodiumPage({super.key, required this.client});

  @override
  State<PodiumPage> createState() => _PodiumPageState();
}

class _PodiumPageState extends State<PodiumPage> {
  List<Score> podium = [];
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
          podium = pod;
        });
      });
    }
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
              ...podium.asMap().entries.map((entry) {
                int index = entry.key;
                Score score = entry.value;
                return ScoreView(score: score, rank: index + 1);
              })
            else
              const Text('No scores available', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle button press
        },
        tooltip: 'Next Question',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
