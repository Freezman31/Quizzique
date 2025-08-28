import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/views/create/listpage.dart';
import 'package:quizzique/views/play/waitingpage.dart';

class BrowsePage extends StatefulWidget {
  static const String route = '/create/browse';

  final Client client;
  const BrowsePage({super.key, required this.client});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Quizzes')),
      body: FutureBuilder(
        future: browseQuiz(
          client: widget.client,
          searchQuery: _searchController.text,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            Logger().e(
              'Error fetching quizzes: ${snapshot.error}\n${snapshot.stackTrace}',
            );
            return const Center(child: Text('Error loading quizzes'));
          } else {
            final List<Quiz> quizzes = snapshot.data as List<Quiz>;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onFieldSubmitted: (v) => setState(() {}),
                    onTapOutside: (e) => setState(() {}),
                    autocorrect: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        return ListTile(
                          title: Text(
                            '${quiz.name} - ${quiz.questions.length}',
                          ),
                          subtitle: Text(quiz.description),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  getDialog(context, quiz, widget),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

Widget getDialog(BuildContext context, Quiz quiz, BrowsePage widget) {
  return AlertDialog(
    title: Text(quiz.name),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        itemCount: quiz.questions.length,
        itemBuilder: (context, index) {
          final question = quiz.questions[index];
          return ListTile(
            tileColor: index.isEven
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            title: Text(question.question),
            subtitle: switch (question.type) {
              QuestionType.fourChoices => RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Answers: '),
                    ...question.answers.map(
                      (answer) => TextSpan(
                        text:
                            '$answer${answer == question.answers[3] ? '' : ', '}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              question.correctAnswerIndex ==
                                  question.answers.indexOf(answer)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              question.correctAnswerIndex ==
                                  question.answers.indexOf(answer)
                              ? Theme.of(context).colorScheme.inversePrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              QuestionType.twoChoices => RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Answers: '),
                    ...[question.answers[0], question.answers[1]].map(
                      (answer) => TextSpan(
                        text:
                            '$answer${answer == question.answers[1] ? '' : ', '}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              question.correctAnswerIndex ==
                                  question.answers.indexOf(answer)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color:
                              question.correctAnswerIndex ==
                                  question.answers.indexOf(answer)
                              ? Theme.of(context).colorScheme.inversePrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              QuestionType.guess => Text(
                'Numerical value between ${question.answers[0]} and ${question.answers[1]} ±${question.answers[2]}, expected ${question.correctAnswerIndex}',
              ),
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
      TextButton(
        onPressed: () async {
          final Quiz newQuiz = quiz.copy();
          newQuiz.id = ID.unique();
          newQuiz.name = '${quiz.name} (Remix)';
          await saveQuiz(client: widget.client, quiz: newQuiz);
          Navigator.of(context).pushNamed(ListPage.route);
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
        ),
        child: const Text('Remix'),
      ),
      TextButton(
        onPressed: () async {
          final game = await presentQuiz(client: widget.client, quiz: quiz);
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
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Present'),
      ),
    ],
  );
}
