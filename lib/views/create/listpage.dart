import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/utils/utils.dart';
import 'package:quizapp/views/play/waitingpage.dart';

class ListPage extends StatefulWidget {
  static const String route = '/create/list';
  final Client client;
  const ListPage({super.key, required this.client});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Quiz> quizzes = [];

  @override
  void initState() {
    super.initState();
    fetchQuizzes();
  }

  Future<void> fetchQuizzes() async {
    final fetchedQuizzes = await getQuizzesFromUser(client: widget.client);
    setState(() {
      quizzes = fetchedQuizzes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchQuizzes),
        ],
      ),
      body: quizzes.isEmpty
          ? const Center(child: Text('No quizzes found (yet).'))
          : ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return ListTile(
                  hoverColor: Colors.grey[300],
                  tileColor: index.isEven
                      ? Theme.of(context).colorScheme.surface
                      : Colors.blueGrey[50],
                  title: Text(quiz.name),
                  subtitle: Text(
                    '${quiz.questions.length} ${'question'.pluralize(quiz.questions.length)}',
                  ),
                  trailing: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final game = await presentQuiz(
                            client: widget.client,
                            quiz: quiz,
                          );
                          Navigator.pushNamed(
                            context,
                            WaitingPage.route,
                            arguments: {
                              'quiz': quiz,
                              'gameID': game.gameID,
                              'gameCode': game.code,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Present',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/create/edit',
                            arguments: {'quiz': quiz},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.pushNamed(context, '/create/quiz');
        },
        tooltip: 'Create Quiz',
        child: const Icon(Icons.add),
      ),
    );
  }
}
