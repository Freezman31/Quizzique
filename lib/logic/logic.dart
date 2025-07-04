import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

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
      databaseId: '6859582600031c46e49c',
      collectionId: '685990a30018382797dc',
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
        databaseId: '6859582600031c46e49c',
        collectionId: '685990a30018382797dc',
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
    databaseId: '6859582600031c46e49c',
    collectionId: '685990a30018382797dc',
    documentId: gameID,
  );
  final nextQuestion = jsonDecode(
    game.data['quiz']['questions'][currentQuestion.questionIndex + 1],
  );

  await databases.updateDocument(
    databaseId: '6859582600031c46e49c',
    collectionId: '685990a30018382797dc',
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
  final String gameID;
  final String questionID;
  final String question;
  final List<String> answers;
  final int? correctAnswerIndex;
  final int questionIndex;
  final int duration;

  Question({
    required this.gameID,
    required this.question,
    required this.answers,
    this.correctAnswerIndex,
    required this.questionID,
    required this.duration,
    required this.questionIndex,
  });
  Question.empty()
    : gameID = '',
      question = '',
      answers = ['', '', '', ''],
      questionID = '',
      correctAnswerIndex = null,
      questionIndex = 0,
      duration = 0;

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
      databaseId: '6859582600031c46e49c',
      collectionId: '685d148300346d2203a7',
      documentId: id,
      data: {
        'questionID': int.parse(questionID),
        'answer': answerIndex,
        'playerID': await _getDeviceID(),
        'games': gameID,
      },
    );
    Functions func = Functions(client);
    final res = await func.createExecution(
      functionId: '685d5b460009ba42e17f',
      body: jsonEncode({
        'questionID': questionID,
        'answerIndex': answerIndex,
        'games': (await databases.getDocument(
          databaseId: '6859582600031c46e49c',
          collectionId: '685990a30018382797dc',
          documentId: gameID,
        )).data,
        'playerID': await _getDeviceID(),
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
    databaseId: '6859582600031c46e49c',
    collectionId: '685990a30018382797dc',
    documentId: gameID,
  );
  final payload = jsonDecode(game.data['scores']);
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

final String? deviceId = null;

Future<String> _getDeviceID() async {
  return deviceId ?? (await const FlutterSecureStorage().read(key: 'id') ?? '');
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
