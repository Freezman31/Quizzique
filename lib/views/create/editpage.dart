import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/widgets/quiz_edit.dart';

class EditPage extends StatefulWidget {
  static const String route = '/create/edit';
  final Client client;
  const EditPage({super.key, required this.client});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  Quiz quiz = Quiz.empty();
  Quiz savedQuiz = Quiz.empty();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    if (quiz == Quiz.empty()) {
      setState(() {
        quiz = args['quiz'] as Quiz? ?? Quiz.empty();
        savedQuiz = quiz.copy();
      });
    }
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _showSaveDialog();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Quiz'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _showSaveDialog()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                if (quiz == Quiz.empty()) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Quiz is default. Cannot save.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                if (quiz.id.isEmpty) {
                  quiz.id = ID.unique();
                }
                await saveQuiz(client: widget.client, quiz: quiz);
                savedQuiz = quiz;
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    quiz.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await editQuizName();
                    },
                    tooltip: 'Edit Quiz Name',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: QuizEdit(client: widget.client, quiz: quiz),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showSaveDialog() async {
    if (quiz == savedQuiz) {
      return true;
    }
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to save them?',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (quiz.id.isEmpty) {
                  quiz.id = ID.unique();
                }
                await saveQuiz(client: widget.client, quiz: quiz);
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<void> editQuizName() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
          text: quiz.name,
        );
        return AlertDialog(
          title: const Text('Edit Quiz Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter quiz name'),
            autocorrect: true,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
            keyboardType: TextInputType.text,
            onSubmitted: (value) {
              setState(() {
                quiz.name = nameController.text;
              });
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  quiz.name = nameController.text;
                });
                nameController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                nameController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
