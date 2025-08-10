import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:quizzique/utils/constants.dart';
import 'package:quizzique/views/create/editpage.dart';
import 'package:quizzique/views/create/listpage.dart';
import 'package:quizzique/views/homepage.dart';
import 'package:quizzique/views/loginpage.dart';
import 'package:quizzique/views/play/code.dart';
import 'package:quizzique/views/play/customizationpage.dart';
import 'package:quizzique/views/play/finalpodiumpage.dart';
import 'package:quizzique/views/play/playpage.dart';
import 'package:quizzique/views/play/podiumpage.dart';
import 'package:quizzique/views/play/presentpage.dart';
import 'package:quizzique/views/play/waitingpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "dotenv");

  Constants.init(
    appwriteUrl: dotenv.get('APPWRITE_URL'),
    appwriteProjectId: dotenv.get('APPWRITE_PROJECT_ID'),
    databaseId: dotenv.get('DATABASE_ID'),
    usersCollectionId: dotenv.get('USERS_COLLECTION_ID'),
    quizzesCollectionId: dotenv.get('QUIZZES_COLLECTION_ID'),
    answersCollectionId: dotenv.get('ANSWERS_COLLECTION_ID'),
    gamesCollectionId: dotenv.get('GAMES_COLLECTION_ID'),
    answerCheckFunctionId: dotenv.get('ANSWER_CHECK_FUNCTION_ID'),
    scoresCollectionId: dotenv.get('SCORES_COLLECTION_ID'),
    url: dotenv.get('URL'),
    port: dotenv.get('PORT'),
    isDemo: dotenv.getBool('DEMO'),
  );

  Client client = Client()
    ..setEndpoint(Constants.appwriteUrl) // Your Appwrite endpoint
    ..setProject(Constants.appwriteProjectId); // Your Appwrite project ID
  try {
    await client.ping(); // Optional: Check if the client is connected
  } catch (e) {
    Logger().e('Error connecting to Appwrite: $e');
    return;
  }
  final acc = Account(client);
  try {
    if (Constants.isDemo) {
      Logger().i('Creating anonymous session for demo mode');
      await acc.deleteSessions();
      await acc.createAnonymousSession();
    } else {
      await acc.get();
    }
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
      title: 'Quizzique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff0b172e)),
        useMaterial3: true,
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xff0b172e),
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(client: client),
      routes: {
        CodePage.route: (context) => CodePage(client: client),
        PlayPage.route: (context) => PlayPage(client: client),
        PresentPage.route: (context) => PresentPage(client: client),
        PodiumPage.route: (context) => PodiumPage(client: client),
        LoginPage.route: (context) => LoginPage(client: client),
        ListPage.route: (context) => ListPage(client: client),
        WaitingPage.route: (context) => WaitingPage(client: client),
        EditPage.route: (context) => EditPage(client: client),
        CustomizationPage.route: (context) => CustomizationPage(client: client),
        FinalPodiumPage.route: (context) => FinalPodiumPage(client: client),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == CustomizationPage.route) {
          final code = uri.queryParameters['code'];
          if (code != null) {
            return MaterialPageRoute(
              builder: (context) => CustomizationPage(client: client),
              settings: RouteSettings(arguments: {'code': int.tryParse(code)}),
            );
          }
        }
        return null;
      },
    );
  }
}
