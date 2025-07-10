import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:quizapp/views/create/listpage.dart';
import 'package:quizapp/views/homepage.dart';
import 'package:quizapp/views/loginpage.dart';
import 'package:quizapp/views/play/code.dart';
import 'package:quizapp/views/play/playpage.dart';
import 'package:quizapp/views/play/podiumpage.dart';
import 'package:quizapp/views/play/presentpage.dart';

void main() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1') // Your Appwrite endpoint
    ..setProject(dotenv.get('PROJECT_ID')); // Your Appwrite project ID
  try {
    await client.ping(); // Optional: Check if the client is connected
  } catch (e) {
    Logger().e('Error connecting to Appwrite: $e');
    return;
  }
  final acc = Account(client);
  try {
    await acc.get();
  } catch (e) {
    await acc.createAnonymousSession();
  }
  usePathUrlStrategy();
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
        useMaterial3: true,
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(),
      ),
      home: Homepage(client: client),
      routes: {
        CodePage.route: (context) => CodePage(client: client),
        PlayPage.route: (context) => PlayPage(client: client),
        PresentPage.route: (context) => PresentPage(client: client),
        PodiumPage.route: (context) => PodiumPage(client: client),
        LoginPage.route: (context) => LoginPage(client: client),
        ListPage.route: (context) => ListPage(client: client),
      },
    );
  }
}
