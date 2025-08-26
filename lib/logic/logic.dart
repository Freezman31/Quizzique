import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:quizzique/utils/constants.dart';

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
    if (result.total == 0) return false;
    return jsonDecode(result.documents.first.data['currentQuestion'])['i'] ==
        -1;
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
          type: QuestionType.values[payload['t'] as int],
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
        't': nextQuestion['t'],
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
  QuestionType type;

  Question({
    required this.gameID,
    required this.question,
    required this.answers,
    this.correctAnswerIndex,
    required this.questionID,
    required this.duration,
    required this.questionIndex,
    required this.durationBeforeAnswer,
    required this.type,
  });
  Question.empty()
    : gameID = '',
      question = '',
      answers = ['', '', '', ''],
      questionID = '',
      correctAnswerIndex = 0,
      questionIndex = 0,
      durationBeforeAnswer = 0,
      duration = 30,
      type = QuestionType.fourChoices;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Question otherQuestion = other as Question;
    return gameID == otherQuestion.gameID &&
        question == otherQuestion.question &&
        listEquals(answers, otherQuestion.answers) &&
        correctAnswerIndex == otherQuestion.correctAnswerIndex &&
        type == otherQuestion.type;
  }

  @override
  int get hashCode {
    return gameID.hashCode ^
        question.hashCode ^
        answers.hashCode ^
        (correctAnswerIndex?.hashCode ?? 0) ^
        type.hashCode;
  }

  Future<AnswerResponse> answer({
    required Client client,
    required int answerIndex,
    required String playerName,
  }) async {
    Databases databases = Databases(client);
    Logger().i('Answering question $questionID with answer index $answerIndex');
    final id = ID.unique();
    final doc = await databases.createDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.answersCollectionId,
      documentId: id,
      data: {
        'questionID': questionID,
        'answer': answerIndex,
        'playerID': await _getDeviceID(client: client),
        'games': gameID,
      },
    );
    Functions func = Functions(client);
    Execution res;
    while (true) {
      res = await func.createExecution(
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
          'playerName': playerName,
          '\$id': id,
          '\$updatedAt': doc.$updatedAt,
        }),
      );
      if (res.responseStatusCode != 200) {
        if (res.responseStatusCode == 400) {
          return AnswerResponse(score: 0, status: AnswerStatus.alreadyAnswered);
        } else if (res.responseStatusCode == 408) {
          return AnswerResponse(score: 0, status: AnswerStatus.tooLate);
        } else if (res.responseStatusCode == 500) {
          //if (res.errors != '') break;
          //continue;
          break;
        } else {
          databases.deleteDocument(
            databaseId: doc.$databaseId,
            collectionId: doc.$collectionId,
            documentId: doc.$id,
          );
          break;
        }
      } else {
        break;
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

  Question copy() {
    return Question(
      gameID: gameID,
      question: question,
      answers: List<String>.from(answers),
      questionID: questionID,
      correctAnswerIndex: correctAnswerIndex,
      questionIndex: questionIndex,
      durationBeforeAnswer: durationBeforeAnswer,
      duration: duration,
      type: type,
    );
  }
}

enum QuestionType { fourChoices, twoChoices, guess }

Future<List<Score>> getScores({
  required Client client,
  required String gameID,
}) async {
  Databases databases = Databases(client);
  final scores = await databases.listDocuments(
    databaseId: Constants.databaseId,
    collectionId: Constants.scoresCollectionId,
    queries: [Query.equal('game', gameID), Query.orderDesc('score')],
  );

  final List<Map<String, dynamic>> players =
      ((await databases.getDocument(
                databaseId: Constants.databaseId,
                collectionId: Constants.gamesCollectionId,
                documentId: gameID,
              )).data['players']
              as List<dynamic>)
          .map((e) => jsonDecode(e.toString()) as Map<String, dynamic>)
          .toList();

  Logger().i('Players in game $gameID: $players');

  final nonNull = scores.documents.map<Score>((doc) {
    final data = doc.data;
    return Score(
      playerID: data['playerID'],
      score: data['score'],
      playerName: data['playerName'],
    );
  }).toList();

  final nullPlayers = players
      .where(
        (player) => !nonNull.any((score) => score.playerID == player['id']),
      )
      .toList();
  nonNull.addAll(
    nullPlayers.map(
      (player) => Score(
        playerID: player['id'],
        score: 0,
        playerName: player['username'],
      ),
    ),
  );
  return nonNull;
}

Future<Score> getPlayerScore({
  required Client client,
  required String gameID,
}) async {
  final List<Score> scores = await getScores(client: client, gameID: gameID);
  final String deviceID = await _getDeviceID(client: client);
  final Score playerScore = scores.firstWhere(
    (score) => score.playerID == deviceID,
    orElse: () => Score(playerID: deviceID, score: 0, playerName: 'You'),
  );
  playerScore.ranking = scores.indexOf(playerScore) + 1;
  return playerScore;
}

Future<void> endGame({required Client client, required String gameID}) async {
  Databases databases = Databases(client);
  try {
    await databases.updateDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.gamesCollectionId,
      documentId: gameID,
      data: {'ended': true},
    );
    Logger().i('Game $gameID ended successfully');
  } catch (e) {
    Logger().e('Error ending game $gameID: $e');
    throw Exception('Failed to end game: $e');
  }
}

Future<void> deleteGame({
  required Client client,
  required String gameID,
}) async {
  Databases databases = Databases(client);
  try {
    await databases.deleteDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.gamesCollectionId,
      documentId: gameID,
    );
    Logger().i('Game $gameID deleted successfully');
  } catch (e) {
    Logger().e('Error deleting game $gameID: $e');
    throw Exception('Failed to delete game: $e');
  }
}

Future<String> _getDeviceID({required Client client}) async {
  return (await Account(client).get()).$id;
}

Future<User> createAccount({
  required String username,
  required String email,
  required String password,
  required Client client,
  required BuildContext context,
}) async {
  Account account = Account(client);
  Databases databases = Databases(client);
  try {
    final User user = await account.get();
    await account.updateEmail(email: email, password: password);
    await account.updateName(name: username);
    // Create a document in the users collection
    await databases.createDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.usersCollectionId,
      documentId: user.$id,
      data: {'userID': user.$id, 'username': username},
    );
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
    await account.get();
    await account.deleteSession(
      sessionId: 'current',
    ); // Delete session only if there is
  } catch (_) {
    Logger().i('User not logged in');
  }
  try {
    await account.createEmailPasswordSession(email: email, password: password);
  } catch (e) {
    Logger().i('Error logging in: $e');
    if (e is AppwriteException) {
      if (e.code == 401 && e.type != 'general_unauthorized_scope') {
        throw Exception('Invalid email or password');
      } else if (e.type != 'general_unauthorized_scope') {
        throw Exception('Failed to log in: $e');
      }
    } else {
      throw Exception('Failed to log in: $e');
    }
  }
  try {
    Logger().i('Creating session for user: $email');
    Logger().i('Session created for user: $email');
    await Future.delayed(Duration(milliseconds: 100));
    final user = await account.get();
    Logger().i('User logged in: ${user.name}');
    return user;
  } catch (e) {
    Logger().i('Error fetching user: $e');
    rethrow;
  }
}

Future<List<Quiz>> getQuizzesFromUser({required Client client}) async {
  Databases databases = Databases(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Fetching quizzes for user: $userID');
  try {
    final userData = await databases.getDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.usersCollectionId,
      documentId: userID,
    );
    final Map<String, dynamic> payload = userData.data;

    return (payload['quizzes'] as List<dynamic>)
        .map((quiz) => Quiz.fromJson(quiz))
        .toList();
  } catch (e) {
    Logger().e(
      'Error fetching quizzes: $e, probably not quizzes yet from user',
    );
    return [];
  }
}

Future<GameCreationResponse> presentQuiz({
  required Client client,
  required Quiz quiz,
}) async {
  Databases databases = Databases(client);

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
        'id': '',
        'i': -1,
        'question': '',
        'answers': ['', '', '', ''],
        'd': 0,
        'durationBeforeAnswer': 0,
        't': 0,
      }),
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
      .map((p) => (jsonDecode(p)['username']?.toString() ?? 'Unknown'))
      .toList();
}

Future<void> addPlayer({
  required Client client,
  required int gameCode,
  required String username,
}) async {
  Databases databases = Databases(client);
  Account account = Account(client);
  String userID;
  try {
    userID = (await account.get()).$id;
  } catch (e) {
    final sess = await account.createAnonymousSession();
    userID = sess.userId;
  }

  final playerData = {'id': userID, 'username': username};
  final DocumentList docs = await databases.listDocuments(
    databaseId: Constants.databaseId,
    collectionId: Constants.gamesCollectionId,
    queries: [Query.equal('code', gameCode)],
  );
  if (docs.total > 0) {
    final gameID = docs.documents.first.$id;
    await databases.updateDocument(
      databaseId: Constants.databaseId,
      collectionId: Constants.gamesCollectionId,
      documentId: gameID,
      data: {
        'players': [
          ...((await databases.getDocument(
                databaseId: Constants.databaseId,
                collectionId: Constants.gamesCollectionId,
                documentId: gameID,
              )).data['players']
              as List<dynamic>),
          jsonEncode(playerData),
        ],
      },
    );
  } else {
    throw Exception('Game with code $gameCode not found');
  }
}

Future<void> saveQuiz({required Client client, required Quiz quiz}) async {
  Databases databases = Databases(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Saving quiz ${quiz.id} for user: $userID');

  for (int i = 0; i < quiz.questions.length; i++) {
    if (quiz.questions[i].questionID.isEmpty) {
      quiz.questions[i].questionID = ID.unique();
    }
    quiz.questions[i].questionIndex = i;
  }

  await databases.upsertDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.quizzesCollectionId,
    documentId: quiz.id,
    data: quiz.toJson()..addAll({'owner': userID}),
    permissions: [
      'update("user:$userID")',
      'delete("user:$userID")',
      'read("user:$userID")',
      'read("any")',
    ],
  );
}

Future<void> deleteQuiz({required Client client, required Quiz quiz}) async {
  Databases databases = Databases(client);
  if (quiz.id.isEmpty) {
    return; // Nothing to delete
  }
  await databases.deleteDocument(
    databaseId: Constants.databaseId,
    collectionId: Constants.quizzesCollectionId,
    documentId: quiz.id,
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

  Quiz.empty()
    : id = '',
      name = 'New Quiz',
      questions = [Question.empty()],
      durationBeforeAnswer = 5;
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
              type: QuestionType.values[q['t'] as int],
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
          't': q.type.index,
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

  Quiz copy() {
    return Quiz(
      id: id,
      name: name,
      questions: List<Question>.from(questions.map((e) => e.copy())),
      durationBeforeAnswer: durationBeforeAnswer,
    );
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
  int? ranking;
  final String playerName;

  Score({
    required this.playerID,
    required this.score,
    required this.playerName,
    this.ranking,
  });
}

enum AnswerStatus { correct, incorrect, alreadyAnswered, tooLate }
