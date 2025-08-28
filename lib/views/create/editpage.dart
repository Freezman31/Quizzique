import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/utils.dart';
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
                  Text(
                    quiz.description.max(50),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await editQuizInfos();
                    },
                    tooltip: 'Edit Quiz Infos',
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    icon: Icon(quiz.isPublic ? Icons.lock_open : Icons.lock),
                    onPressed: () async {
                      setState(() {
                        quiz.isPublic = !quiz.isPublic;
                      });
                    },
                    tooltip:
                        'Set visibility to ${quiz.isPublic ? "private" : "public"}',
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

  Future<void> editQuizInfos() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
          text: quiz.name,
        );
        final TextEditingController descController = TextEditingController(
          text: quiz.description,
        );
        final MediaQueryData mq = MediaQuery.of(context);
        return AlertDialog(
          title: const Text('Edit Quiz Infos'),
          content: SizedBox(
            height: mq.size.height * 0.3,
            width: mq.size.width * 0.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter quiz name',
                  ),
                  autocorrect: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  keyboardType: TextInputType.text,
                ),
                TextField(
                  autocorrect: true,
                  controller: descController,
                  decoration: const InputDecoration(
                    hintText: 'Enter quiz description',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 256,
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  quiz.name = nameController.text;
                  quiz.description = descController.text;
                });
                nameController.dispose();
                descController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                nameController.dispose();
                descController.dispose();
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
