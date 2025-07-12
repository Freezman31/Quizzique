import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:quizapp/utils/constants.dart';

Future<bool> isCodeValid(String code, {required Client client}) async {
  if (code.length != 6) {
    return false;
  }
  for (int i = 0; i < code.length; i++) {
    if (!RegExp(r'^\d$').hasMatch(code[i])) {
      return false;
    }
  }
  Databases databases = Databases(client);
  try {
    DocumentList result = await databases.listDocuments(
      databaseId: Constants.databaseId,
      collectionId: Constants.gamesCollectionId,
      queries: [Query.equal('code', int.parse(code))],
    );
    return result.total > 0;
  } catch (e) {
    Logger().e('Error checking code validity: $e');
    return false;
  }
}

Future<Question> getCurrentQuestion({
  required Client client,
  required int code,
}) {
  Databases databases = Databases(client);
  return databases
      .listDocuments(
        databaseId: Constants.databaseId,
        collectionId: Constants.gamesCollectionId,
        queries: [Query.equal('code', code)],
      )
      .then((documents) {
        if (documents.total == 0) {
          throw Exception('No documents found for the given code.');
        }
        if (documents.total > 1) {
          throw Exception('Multiple documents found for the given code.');
        }
        Document document = documents.documents.first;

        final payload = jsonDecode(document.data['currentQuestion']);
        Logger().i('Current question ID: ${payload['id'].toString()}');
        return Question(
          gameID: document.$id,
          questionID: payload['id'].toString(),
          questionIndex: payload['i'] as int,
          question: payload['question'] as String,
          answers: List<String>.from(payload['answers'] as List),
          correctAnswerIndex: payload['correctAnswerIndex'] as int?,
          duration: payload['d'] as int,
          durationBeforeAnswer:
              document.data['quiz']['durationBeforeAnswer'] as int,
        );
      })
      .catchError((error) {
        throw error;
      });
}

Future<void> goToNextQuestion({
  required Client client,
  required String gameID,
  required Question currentQuestion,
}) async {
  Databases databases = Databases(client);

  final game = await databases.getDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    documentId: gameID,
  );
  final nextQuestion = jsonDecode(
    game.data['quiz']['questions'][currentQuestion.questionIndex + 1],
  );

  await databases.updateDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    documentId: gameID,
    data: {
      'currentQuestion': jsonEncode({
        'id': nextQuestion['id'].toString(),
        'i': currentQuestion.questionIndex + 1,
        'question': nextQuestion['q'],
        'answers': [
          nextQuestion['1'],
          nextQuestion['2'],
          nextQuestion['3'],
          nextQuestion['4'],
        ],
        'd': nextQuestion['d'],
      }),
    },
  );
}

class Question {
  String gameID;
  String questionID;
  String question;
  List<String> answers;
  int? correctAnswerIndex;
  int questionIndex;
  int duration;
  int durationBeforeAnswer;

  Question({
    required this.gameID,
    required this.question,
    required this.answers,
    this.correctAnswerIndex,
    required this.questionID,
    required this.duration,
    required this.questionIndex,
    required this.durationBeforeAnswer,
  });
  Question.empty()
    : gameID = '',
      question = '',
      answers = ['', '', '', ''],
      questionID = '',
      correctAnswerIndex = null,
      questionIndex = 0,
      durationBeforeAnswer = 0,
      duration = 30;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Question otherQuestion = other as Question;
    return gameID == otherQuestion.gameID &&
        question == otherQuestion.question &&
        listEquals(answers, otherQuestion.answers) &&
        correctAnswerIndex == otherQuestion.correctAnswerIndex;
  }

  @override
  int get hashCode {
    return gameID.hashCode ^
        question.hashCode ^
        answers.hashCode ^
        (correctAnswerIndex?.hashCode ?? 0);
  }

  Future<AnswerResponse> answer({
    required Client client,
    required int answerIndex,
  }) async {
    if (answerIndex < 0 || answerIndex >= answers.length) {
      throw Exception('Invalid answer index');
    }
    Databases databases = Databases(client);
    Logger().i('Answering question $questionID with answer index $answerIndex');
    final id = ID.unique();
    final doc = await databases.createDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.answersCollectionId,
      documentId: id,
      data: {
        'questionID': int.parse(questionID),
        'answer': answerIndex,
        'playerID': await _getDeviceID(client: client),
        'games': gameID,
      },
    );
    Functions func = Functions(client);
    final res = await func.createExecution(
      functionId: Constants.answerCheckFunctionId,
      body: jsonEncode({
        'questionID': questionID,
        'answerIndex': answerIndex,
        'games': (await databases.getDocument(
          databaseId: Constants.databaseId,
          collectionId: Constants.gamesCollectionId,
          documentId: gameID,
        )).data,
        'playerID': await _getDeviceID(client: client),
        '\$id': id,
        '\$updatedAt': doc.$updatedAt,
      }),
    );
    if (res.responseStatusCode != 200) {
      if (res.responseStatusCode == 400) {
        return AnswerResponse(score: 0, status: AnswerStatus.alreadyAnswered);
      } else if (res.responseStatusCode == 408) {
        return AnswerResponse(score: 0, status: AnswerStatus.tooLate);
      } else {
        databases.deleteDocument(
          databaseId: doc.$databaseId,
          collectionId: doc.$collectionId,
          documentId: doc.$id,
        );
      }
    }
    final payload = jsonDecode(res.responseBody)['data'];
    return payload['correct'] as bool
        ? AnswerResponse(
            score: payload['score'] as int,
            status: AnswerStatus.correct,
          )
        : AnswerResponse(score: 0, status: AnswerStatus.incorrect);
  }
}

Future<List<Score>> getPodium({
  required Client client,
  required String gameID,
}) async {
  Databases databases = Databases(client);
  final game = await databases.getDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    documentId: gameID,
  );
  final payload = jsonDecode(game.data['scores']) ?? <String, dynamic>{};
  final List<Score> podium = (payload as Map<String, dynamic>).entries
      .map(
        (entry) => Score(
          playerID: entry.key,
          score: entry.value['s'],
          playerName: entry.value['name'] ?? entry.key,
        ),
      )
      .toList();
  return podium..sort((a, b) => b.score.compareTo(a.score));
}

Future<String> _getDeviceID({required Client client}) async {
  return (await Account(client).get()).$id;
}

Future<User> createAccount({
  required String username,
  required String email,
  required String password,
  required Client client,
}) async {
  Account account = Account(client);
  Databases databases = Databases(client);
  try {
    final User user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: username,
    );
    // Create a document in the users collection
    databases.createDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.usersCollectionId,
      documentId: user.$id,
      data: {'userID': user.$id},
    );
    // Remove any existing anonymous session
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      Logger().w('No current session to delete: $e');
    }
    await account.createEmailPasswordSession(email: email, password: password);
    Logger().i('Account created for user: ${user.name}');
    return user;
  } catch (e) {
    Logger().e('Error creating account: $e');
    if (e is AppwriteException) {
      if (e.code == 409) {
        throw Exception('Email already in use');
      } else if (e.code == 400) {
        throw Exception('Invalid input data');
      } else {
        throw Exception('Failed to create account: ${e.message}');
      }
    } else {
      throw Exception('Failed to create account: $e');
    }
  }
}

Future<User> login({
  required String email,
  required String password,
  required Client client,
}) async {
  Account account = Account(client);
  try {
    await account.createEmailPasswordSession(email: email, password: password);
    final user = await account.get();
    Logger().i('User logged in: ${user.name}');
    return user;
  } catch (e) {
    Logger().e('Error logging in: $e');
    if (e is AppwriteException) {
      if (e.code == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Failed to log in: ${e.message}');
      }
    } else {
      throw Exception('Failed to log in: $e');
    }
  }
}

Future<List<Quiz>> getQuizzesFromUser({required Client client}) async {
  Databases databases = Databases(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Fetching quizzes for user: $userID');
  final userData = await databases.getDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.usersCollectionId,
    documentId: userID,
  );
  final Map<String, dynamic> payload = userData.data;

  return (payload['quizzes'] as List<dynamic>)
      .map((quiz) => Quiz.fromJson(quiz))
      .toList();
}

Future<GameCreationResponse> presentQuiz({
  required Client client,
  required Quiz quiz,
}) async {
  Databases databases = Databases(client);

  final firstQuestion = quiz.questions.first;
  int code = 0;
  while (true) {
    code = DateTime.now().millisecondsSinceEpoch % 1000000;
    // Check if the code is already in use
    final existingGames = await databases.listDocuments(
      databaseId: Constants.databaseId,
      collectionId: Constants.gamesCollectionId,
      queries: [Query.equal('code', code)],
    );
    if (existingGames.total == 0) {
      break; // Found a unique code
    }
  }
  final String id = ID.unique();

  await databases.createDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    documentId: id,
    data: {
      'quiz': quiz.id,
      'currentQuestion': jsonEncode({
        'id': firstQuestion.questionID,
        'i': 0,
        'question': firstQuestion.question,
        'answers': jsonEncode(firstQuestion.answers),
        'd': firstQuestion.duration,
      }),
      'scores': '{}',
      'code': code,
      'owner': (await Account(client).get()).$id,
    },
  );

  return GameCreationResponse(gameID: id, code: code);
}

Future<List<String>> getPlayers({
  required Client client,
  required String gameID,
}) async {
  Databases databases = Databases(client);
  final game = await databases.getDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    documentId: gameID,
  );
  return (game.data['players'] as List<dynamic>)
      .map((p) => (p['username']?.toString() ?? 'Unknown'))
      .toList();
}

Future<void> saveQuiz({required Client client, required Quiz quiz}) async {
  Databases databases = Databases(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Saving quiz for user: $userID');

  for (int i = 0; i < quiz.questions.length; i++) {
    quiz.questions[i].questionIndex = i;
  }

  await databases.upsertDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.quizzesCollectionId,
    documentId: quiz.id,
    data: quiz.toJson(),
    permissions: [
      'update("user:$userID")',
      'delete("user:$userID")',
      'read("user:$userID")',
      'read("any")',
    ],
  );
}

class GameCreationResponse {
  final String gameID;
  final int code;

  GameCreationResponse({required this.gameID, required this.code});
}

class Quiz {
  String id;
  String name;
  List<Question> questions;
  int durationBeforeAnswer;

  Quiz({
    required this.id,
    required this.name,
    required this.questions,
    required this.durationBeforeAnswer,
  });

  Quiz.empty() : id = '', name = '', questions = [], durationBeforeAnswer = 0;
  Quiz.fromJson(Map<String, dynamic> json)
    : id = json['\$id'] as String,
      name = json['name'] as String,
      durationBeforeAnswer = json['durationBeforeAnswer'] as int,
      questions = (json['questions'] as List<dynamic>)
          .map((q) => jsonDecode(q.toString()))
          .map(
            (q) => Question(
              gameID: '',
              questionID: q['id'].toString(),
              questionIndex: q['i'] as int,
              question: q['q'] as String,
              answers: [
                q['1'] as String,
                q['2'] as String,
                q['3'] as String,
                q['4'] as String,
              ],
              correctAnswerIndex: q['c'] as int?,
              duration: q['d'] as int,
              durationBeforeAnswer: json['durationBeforeAnswer'] as int,
            ),
          )
          .toList();

  Map<String, dynamic> toJson() {
    if (id == '') {
      id = ID.unique();
    }
    return {
      '\$id': id,
      'name': name,
      'durationBeforeAnswer': durationBeforeAnswer,
      'questions': questions.map((q) {
        return jsonEncode({
          'id': q.questionID == '' ? ID.unique() : q.questionID,
          'i': q.questionIndex,
          'q': q.question,
          '1': q.answers[0],
          '2': q.answers[1],
          '3': q.answers[2],
          '4': q.answers[3],
          'c': q.correctAnswerIndex,
          'd': q.duration,
        });
      }).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Quiz otherQuiz = other as Quiz;
    return id == otherQuiz.id &&
        name == otherQuiz.name &&
        listEquals(questions, otherQuiz.questions) &&
        durationBeforeAnswer == otherQuiz.durationBeforeAnswer;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        questions.hashCode ^
        durationBeforeAnswer.hashCode;
  }
}

class AnswerResponse {
  final int score;
  final AnswerStatus status;

  AnswerResponse({required this.score, required this.status});
}

class Score {
  final String playerID;
  final int score;
  final String playerName;

  Score({
    required this.playerID,
    required this.score,
    required this.playerName,
  });
}

enum AnswerStatus { correct, incorrect, alreadyAnswered, tooLate }
