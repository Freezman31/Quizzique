import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:quizzique/utils/constants.dart';
import 'package:quizzique/views/create/listpage.dart';
import 'package:quizzique/views/loginpage.dart';
import 'package:quizzique/views/play/code.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';
  final Client client;
  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Constants.isDemo) {
        Logger().i('Running in demo mode');
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Demo Mode'),
              content: Text('''
                Hey! This is a demo version of Quizzique.
                All the features are available, but the data may not be saved.
                You can create quizzes, play them, and customize the experience.
                In order to play, you need to create a game code under the 'Create' tab.
                You can then share this code with your friends to play together.
                Moreover, as this is a demo, you loose your "account" when you close/refresh the app.
                Enjoy!
                PS: Please report any bugs you find on the GitHub repository (there will definitely be some).
                PS2: As this is a demo, if you open another tab, you can play against yourself (or alone) to test the game.
                ''', softWrap: true),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        Logger().i('Running in production mode');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzique')),
      body: Column(
        children: [
          Spacer(flex: 4),
          Expanded(
            child: Center(
              child: Text(
                'Welcome to Quizzique!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Spacer(flex: 2),
          SizedBox(
            width: mq.size.width * 0.95,
            height: mq.size.height * 0.1,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, CodePage.route);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Play Quiz',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SizedBox(height: mq.size.height * 0.02),
          SizedBox(
            width: mq.size.width * 0.95,
            height: mq.size.height * 0.1,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final User user = await Account(widget.client).get();
                  if (user.email == '' && !Constants.isDemo) {
                    // Session is anonymous, redirect to login
                    Navigator.of(context).pushNamed(LoginPage.route);
                    return;
                  }
                } catch (e) {
                  Navigator.of(context).pushNamed(LoginPage.route);
                  return;
                }
                Navigator.of(context).pushNamed(ListPage.route);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Create Quiz',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Spacer(flex: 6),
          Text(
            'Made with ❤️ - 2025',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
