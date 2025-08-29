import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Row;
import 'package:logger/logger.dart';
import 'package:quizzique/utils/avatars.dart';
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
  TablesDB tablesDB = TablesDB(client);
  try {
    RowList result = await tablesDB.listRows(
      databaseId: Constants.databaseId,
      tableId: Constants.gamesTableId,
      queries: [Query.equal('code', int.parse(code))],
    );
    if (result.total == 0) return false;
    return jsonDecode(result.rows.first.data['currentQuestion'])['i'] == -1;
  } catch (e) {
    Logger().e('Error checking code validity: $e');
    return false;
  }
}

Future<Question> getCurrentQuestion({
  required Client client,
  required int code,
}) {
  TablesDB tablesDB = TablesDB(client);
  return tablesDB
      .listRows(
        databaseId: Constants.databaseId,
        tableId: Constants.gamesTableId,
        queries: [
          Query.equal('code', code),
          Query.select(['*', 'quiz.durationBeforeAnswer']),
        ],
      )
      .then((rows) {
        if (rows.total == 0) {
          throw Exception('No rows found for the given code.');
        }
        if (rows.total > 1) {
          throw Exception('Multiple rows found for the given code.');
        }
        Row row = rows.rows.first;

        final payload = jsonDecode(row.data['currentQuestion']);
        Logger().i('Current question ID: ${payload['id'].toString()}');
        return Question(
          gameID: row.$id,
          questionID: payload['id'].toString(),
          questionIndex: payload['i'] as int,
          question: payload['question'] as String,
          answers: List<String>.from(payload['answers'] as List),
          correctAnswerIndex: payload['correctAnswerIndex'] as int?,
          duration: payload['d'] as int,
          durationBeforeAnswer: row.data['quiz']['durationBeforeAnswer'] as int,
          type: QuestionType.values[payload['t'] as int],
          imageUrl: payload['imageUrl'] as String?,
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
  TablesDB tablesDB = TablesDB(client);

  final game = await tablesDB.getRow(
    databaseId: Constants.databaseId,
    tableId: Constants.gamesTableId,
    rowId: gameID,
    queries: [
      Query.select(['quiz.questions']),
    ],
  );
  final nextQuestion = jsonDecode(
    game.data['quiz']['questions'][currentQuestion.questionIndex + 1],
  );

  await tablesDB.updateRow(
    databaseId: Constants.databaseId,
    tableId: Constants.gamesTableId,
    rowId: gameID,
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
        'imageUrl': nextQuestion['imageUrl'],
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
  String? imageUrl;

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
    this.imageUrl,
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
        type == otherQuestion.type &&
        imageUrl == otherQuestion.imageUrl;
  }

  @override
  int get hashCode {
    return gameID.hashCode ^
        question.hashCode ^
        answers.hashCode ^
        (correctAnswerIndex?.hashCode ?? 0) ^
        type.hashCode ^
        (imageUrl?.hashCode ?? 0);
  }

  Future<AnswerResponse> answer({
    required Client client,
    required int answerIndex,
    required String playerName,
  }) async {
    TablesDB tablesDB = TablesDB(client);
    Logger().i('Answering question $questionID with answer index $answerIndex');
    final id = ID.unique();
    final row = await tablesDB.createRow(
      databaseId: Constants.databaseId,
      tableId: Constants.answersTableId,
      rowId: id,
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
          'games': (await tablesDB.getRow(
            databaseId: Constants.databaseId,
            tableId: Constants.gamesTableId,
            rowId: gameID,
            queries: [
              Query.select(['*', 'quiz.*']),
            ],
          )).data,
          'playerID': await _getDeviceID(client: client),
          'playerName': playerName,
          '\$id': id,
          '\$updatedAt': row.$updatedAt,
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
          tablesDB.deleteRow(
            databaseId: row.$databaseId,
            tableId: row.$tableId,
            rowId: row.$id,
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
      imageUrl: imageUrl,
    );
  }
}

enum QuestionType { fourChoices, twoChoices, guess }

Future<List<Score>> getScores({
  required Client client,
  required String gameID,
}) async {
  TablesDB tablesDB = TablesDB(client);
  final scores = await tablesDB.listRows(
    databaseId: Constants.databaseId,
    tableId: Constants.scoresTableId,
    queries: [
      Query.equal('game', gameID),
      Query.orderDesc('score'),
      Query.select(['*']),
    ],
  );

  final List<Map<String, dynamic>> players =
      ((await tablesDB.getRow(
                databaseId: Constants.databaseId,
                tableId: Constants.gamesTableId,
                rowId: gameID,
                queries: [
                  Query.select(['players']),
                ],
              )).data['players']
              as List<dynamic>)
          .map((e) => jsonDecode(e.toString()) as Map<String, dynamic>)
          .toList();

  Logger().i('Players in game $gameID: $players');

  final nonNull = scores.rows.map<Score>((row) {
    final data = row.data;
    return Score(
      playerID: data['playerID'],
      score: data['score'],
      playerName: data['playerName'],
      avatar:
          Avatar.values[players.firstWhere(
                (p) => p['id'] == data['playerID'],
              )['avatar'] ??
              0],
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
        avatar: Avatar.values[player['avatar'] ?? 0],
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
    orElse: () => Score(
      playerID: deviceID,
      score: 0,
      playerName: 'You',
      avatar: Avatar.values[0], // Should never happen
    ),
  );
  playerScore.ranking = scores.indexOf(playerScore) + 1;
  return playerScore;
}

Future<void> endGame({required Client client, required String gameID}) async {
  TablesDB tablesDB = TablesDB(client);
  try {
    await tablesDB.updateRow(
      databaseId: Constants.databaseId,
      tableId: Constants.gamesTableId,
      rowId: gameID,
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
  TablesDB tablesDB = TablesDB(client);
  try {
    await tablesDB.deleteRow(
      databaseId: Constants.databaseId,
      tableId: Constants.gamesTableId,
      rowId: gameID,
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
  TablesDB tablesDB = TablesDB(client);
  try {
    final User user = await account.get();
    await account.updateEmail(email: email, password: password);
    await account.updateName(name: username);
    // Create a table in the users collection
    await tablesDB.createRow(
      databaseId: Constants.databaseId,
      tableId: Constants.usersTableId,
      rowId: user.$id,
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

Future changePassword({
  required Client client,
  required String oldPassword,
  required String newPassword,
}) async {
  Account account = Account(client);
  try {
    await account.updatePassword(
      password: newPassword,
      oldPassword: oldPassword,
    );
    Logger().i('Password changed successfully');
  } catch (e) {
    Logger().e('Error changing password: $e');
    if (e is AppwriteException) {
      if (e.code == 401) {
        throw Exception('Old password is incorrect');
      } else if (e.code == 400) {
        throw Exception('Invalid input data');
      } else {
        throw Exception('Failed to change password: ${e.message}');
      }
    } else {
      throw Exception('Failed to change password: $e');
    }
  }
}

Future updateEmail({
  required Client client,
  required String email,
  required String password,
}) async {
  Account account = Account(client);
  try {
    await account.updateEmail(email: email, password: password);
  } catch (e) {
    Logger().e('Error updating account info: $e');
    if (e is AppwriteException) {
      if (e.code == 409) {
        throw Exception('Email already in use');
      } else if (e.code == 400) {
        throw Exception('Invalid input data');
      } else if (e.code == 401) {
        throw Exception('Wrong password');
      } else {
        throw Exception('Failed to update account info: ${e.message}');
      }
    } else {
      throw Exception('Failed to update account info: $e');
    }
  }
}

Future updateUsername({
  required Client client,
  required String username,
}) async {
  Account account = Account(client);
  try {
    await account.updateName(name: username);
  } catch (e) {
    Logger().e('Error updating username: $e');
    if (e is AppwriteException) {
      if (e.code == 409) {
        throw Exception('Username already in use');
      } else if (e.code == 400) {
        throw Exception('Invalid input data');
      } else {
        throw Exception('Failed to update username: ${e.message}');
      }
    } else {
      throw Exception('Failed to update username: $e');
    }
  }
}

Future<List<Quiz>> getQuizzesFromUser({required Client client}) async {
  TablesDB tablesDB = TablesDB(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Fetching quizzes for user: $userID');
  try {
    final userData = await tablesDB.getRow(
      databaseId: Constants.databaseId,
      tableId: Constants.usersTableId,
      rowId: userID,
      queries: [
        Query.select(['quizzes.*']),
      ],
    );
    final Map<String, dynamic> payload = userData.data;
    Logger().i('User data fetched: $payload');

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
  TablesDB tablesDB = TablesDB(client);

  int code = 0;
  while (true) {
    code = DateTime.now().millisecondsSinceEpoch % 1000000;
    // Check if the code is already in use
    final existingGames = await tablesDB.listRows(
      databaseId: Constants.databaseId,
      tableId: Constants.gamesTableId,
      queries: [
        Query.equal('code', code),
        Query.select(['code']),
      ],
    );
    if (existingGames.total == 0) {
      break; // Found a unique code
    }
  }
  final String id = ID.unique();

  await tablesDB.createRow(
    databaseId: Constants.databaseId,
    tableId: Constants.gamesTableId,
    rowId: id,
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

Future<List<Player>> getPlayers({
  required Client client,
  required String gameID,
}) async {
  TablesDB tablesDB = TablesDB(client);
  final game = await tablesDB.getRow(
    databaseId: Constants.databaseId,
    tableId: Constants.gamesTableId,
    rowId: gameID,
    queries: [
      Query.select(['players']),
    ],
  );
  return (game.data['players'] as List<dynamic>)
      .map(
        (p) => (Player(
          id: jsonDecode(p)['id']?.toString() ?? 'Unknown',
          username: jsonDecode(p)['username']?.toString() ?? 'Unknown',
          avatar: Avatar.values[jsonDecode(p)['avatar'] ?? 0],
        )),
      )
      .toList();
}

Future<void> addPlayer({
  required Client client,
  required int gameCode,
  required String username,
  required Avatar avatar,
}) async {
  TablesDB tablesDB = TablesDB(client);
  Account account = Account(client);
  String userID;
  try {
    userID = (await account.get()).$id;
  } catch (e) {
    final sess = await account.createAnonymousSession();
    userID = sess.userId;
  }

  final playerData = {
    'id': userID,
    'username': username,
    'avatar': avatar.index,
  };
  final RowList rows = await tablesDB.listRows(
    databaseId: Constants.databaseId,
    tableId: Constants.gamesTableId,
    queries: [
      Query.equal('code', gameCode),
      Query.select(['*']),
    ],
  );
  if (rows.total > 0) {
    final gameID = rows.rows.first.$id;
    await tablesDB.updateRow(
      databaseId: Constants.databaseId,
      tableId: Constants.gamesTableId,
      rowId: gameID,
      data: {
        'players': [
          ...((await tablesDB.getRow(
                databaseId: Constants.databaseId,
                tableId: Constants.gamesTableId,
                rowId: gameID,
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
  TablesDB tablesDB = TablesDB(client);
  final String userID = (await Account(client).get()).$id;
  Logger().i('Saving quiz ${quiz.id} for user: $userID');

  for (int i = 0; i < quiz.questions.length; i++) {
    if (quiz.questions[i].questionID.isEmpty) {
      quiz.questions[i].questionID = ID.unique();
    }
    quiz.questions[i].questionIndex = i;
  }

  await tablesDB.upsertRow(
    databaseId: Constants.databaseId,
    tableId: Constants.quizzesTableId,
    rowId: quiz.id,
    data: quiz.toJson()..addAll({'owner': userID}),
    permissions: [
      'update("user:$userID")',
      'delete("user:$userID")',
      'read("user:$userID")',
      if (quiz.isPublic) 'read("any")',
    ],
  );
}

Future<void> deleteQuiz({required Client client, required Quiz quiz}) async {
  TablesDB tablesDB = TablesDB(client);
  if (quiz.id.isEmpty) {
    return; // Nothing to delete
  }
  await tablesDB.deleteRow(
    databaseId: Constants.databaseId,
    tableId: Constants.quizzesTableId,
    rowId: quiz.id,
  );
}

Future<List<Quiz>> browseQuiz({
  required Client client,
  String? searchQuery,
}) async {
  TablesDB tablesDB = TablesDB(client);
  final rows = await tablesDB.listRows(
    databaseId: Constants.databaseId,
    tableId: Constants.quizzesTableId,
    queries: [
      Query.equal('isPublic', true),
      Query.notEqual('owner', (await Account(client).get()).$id),
      Query.select(['*']),
      Query.limit(10),
      Query.orderDesc('\$updatedAt'),
      if (searchQuery != null && searchQuery.isNotEmpty)
        Query.search('name', searchQuery),
    ],
  );
  return rows.rows.map((row) => Quiz.fromJson(row.data)).toList();
}

Future<File> uploadFile({required Client client, required String path}) async {
  Storage storage = Storage(client);
  File file = await storage.createFile(
    bucketId: Constants.bucketId,
    fileId: ID.unique(),
    file: InputFile.fromPath(path: path),
  );
  return file;
}

String fileToPath({required File file}) {
  return '${Constants.appwriteUrl}/storage/buckets/${Constants.bucketId}/files/${file.$id}/view?project=${Constants.appwriteProjectId}';
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
  String description;
  bool isPublic;

  Quiz({
    required this.id,
    required this.name,
    required this.questions,
    required this.durationBeforeAnswer,
    required this.description,
    required this.isPublic,
  });

  Quiz.empty()
    : id = '',
      name = 'New Quiz',
      questions = [Question.empty()],
      durationBeforeAnswer = 5,
      description = '',
      isPublic = true;

  Quiz.fromJson(Map<String, dynamic> json)
    : id = json['\$id'] as String,
      name = json['name'] as String,
      durationBeforeAnswer = json['durationBeforeAnswer'] as int,
      isPublic = json['isPublic'] as bool,
      description = json['description'] as String,
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
              type: QuestionType.values[q['t'] as int? ?? 0],
              imageUrl: q['imageUrl'] as String?,
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
      'description': description,
      'isPublic': isPublic,
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
          'imageUrl': q.imageUrl,
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
      description: description,
      isPublic: isPublic,
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
  final Avatar avatar;

  Score({
    required this.playerID,
    required this.score,
    required this.playerName,
    required this.avatar,
    this.ranking,
  });
}

class Player {
  final String id;
  final String username;
  final Avatar avatar;

  Player({required this.id, required this.username, required this.avatar});
}

enum AnswerStatus { correct, incorrect, alreadyAnswered, tooLate }
