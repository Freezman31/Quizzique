import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  final Client client;
  const Homepage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('QuizApp')),
      body: Column(
        children: [
          Spacer(flex: 4),
          Expanded(
            child: Center(
              child: Text(
                'Welcome to the QuizApp!',
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
                Navigator.pushNamed(context, '/code');
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
                  final User user = await Account(client).get();
                  if (user.email == '') {
                    // Session is anonymous, redirect to login
                    Navigator.of(context).pushNamed('/login');
                    return;
                  }
                } catch (e) {
                  Navigator.of(context).pushNamed('/login');
                  return;
                }
                Navigator.of(context).pushNamed('/create-quiz');
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
