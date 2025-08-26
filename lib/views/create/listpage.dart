import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/utils.dart';
import 'package:quizzique/views/loginpage.dart';
import 'package:quizzique/views/play/waitingpage.dart';

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchQuizzes),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Account(widget.client).deleteSession(sessionId: 'current');
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginPage.route,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: quizzes.isEmpty
          ? const Center(child: Text('No quizzes found. Create one!'))
          : ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return ListTile(
                  hoverColor: Colors.grey[300],
                  tileColor: index.isEven
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
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
                          backgroundColor: colorScheme.errorContainer,
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
                          ).then((_) => fetchQuizzes());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
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
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          await deleteQuiz(client: widget.client, quiz: quiz);
                          fetchQuizzes();
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Quiz newQuiz = Quiz.empty();
          Navigator.pushNamed(
            context,
            '/create/edit',
            arguments: {'quiz': newQuiz},
          ).then((_) => fetchQuizzes());
        },
        tooltip: 'Create Quiz',
        child: const Icon(Icons.add),
      ),
    );
  }
}
