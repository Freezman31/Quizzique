import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

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
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/play/present',
                  arguments: {
                    'code':
                        123456, // Placeholder for code, replace with actual logic
                  },
                );
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
