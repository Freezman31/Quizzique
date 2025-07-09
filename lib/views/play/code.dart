import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/views/play/playpage.dart';

class CodePage extends StatefulWidget {
  static const String route = '/code';
  final Client client;
  const CodePage({super.key, required this.client});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Code')),
      body: Center(
        child: Column(
          children: [
            TextField(
              readOnly: false,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter Quiz Code',
                hintStyle: Theme.of(context).textTheme.headlineSmall,
              ),
              autocorrect: false,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (value) async {
                if (await isCodeValid(value, client: widget.client)) {
                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      PlayPage.route,
                      arguments: {'code': int.parse(value)},
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
