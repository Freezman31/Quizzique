import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quizapp/views/homepage.dart';
import 'package:quizapp/views/play/code.dart';
import 'package:quizapp/views/play/playpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1') // Your Appwrite endpoint
    ..setProject(dotenv.get('PROJECT_ID')); // Your Appwrite project ID
  await client.ping(); // Optional: Check if the client is connected
  runApp(QuizApp(client: client));
}

class QuizApp extends StatelessWidget {
  final Client client;
  const QuizApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Homepage(),
      routes: {
        '/code': (context) => CodePage(client: client),
        '/play/quiz': (context) => PlayPage(client: client),
      },
    );
  }
}
