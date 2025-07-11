import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/widgets/quiz_edit.dart';

class EditPage extends StatefulWidget {
  static const String route = '/create/edit';
  final Client client;
  const EditPage({super.key, required this.client});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  Quiz quiz = Quiz.empty();
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    if (quiz == Quiz.empty()) {
      setState(() {
        quiz = args['quiz'] as Quiz? ?? Quiz.empty();
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              // await updateQuiz(client: widget.client, quiz: quiz);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Text(
                quiz.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: QuizEdit(client: widget.client, quiz: quiz),
            ),
          ],
        ),
      ),
    );
  }
}
