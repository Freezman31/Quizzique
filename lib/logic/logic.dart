import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    print('Error fetching documents: $e');
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
        return Question(
          gameID: document.$id,
          questionID: jsonDecode(
            document.data['currentQuestion'],
          )['id'].toString(),
          question:
              jsonDecode(document.data['currentQuestion'])['question']
                  as String,
          answers: List<String>.from(
            jsonDecode(document.data['currentQuestion'])['answers'] as List,
          ),
          correctAnswerIndex:
              jsonDecode(document.data['currentQuestion'])['correctAnswerIndex']
                  as int?,
        );
      })
      .catchError((error) {
        throw error;
      });
}

class Question {
  final String gameID;
  final String questionID;
  final String question;
  final List<String> answers;
  final int? correctAnswerIndex;

  Question({
    required this.gameID,
    required this.question,
    required this.answers,
    this.correctAnswerIndex,
    required this.questionID,
  });
  Question.empty()
    : gameID = '',
      question = '',
      answers = ['', '', '', ''],
      questionID = '',
      correctAnswerIndex = null;

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

  Future<bool> answer({
    required Client client,
    required int answerIndex,
  }) async {
    if (answerIndex < 0 || answerIndex >= answers.length) {
      throw Exception('Invalid answer index');
    }
    Databases databases = Databases(client);
    print('Answering question with ID: $questionID');
    print('Answer index: $answerIndex');
    final id = ID.unique();
    await databases.createDocument(
      databaseId: '6859582600031c46e49c',
      collectionId: '685d148300346d2203a7',
      documentId: id,
      permissions: [Permission.read(Role.any())],
      data: {
        'questionID': int.parse(questionID),
        'answer': answerIndex,
        'playerID': await _getDeviceID(),
        'games': gameID,
      },
    );
    Realtime realtime = Realtime(client);
    bool? ret;
    realtime
        .subscribe([
          'databases.6859582600031c46e49c.collections.685d148300346d2203a7.documents.*',
          'databases.*.collections.*.documents.*',
        ])
        .stream
        .listen((event) async {
          print('Realtime event received: ${event.events}');
          final newDoc = await databases.getDocument(
            databaseId: '6859582600031c46e49c',
            collectionId: '685d148300346d2203a7',
            documentId: id,
          );
          ret = newDoc.data['correct'] as bool;
        });
    print('Subscribed to realtime updates for answers');
    // while (ret == null) {
    //   //await Future.delayed(Duration(milliseconds: 100));
    // }
    return ret ?? false;
  }
}

final String? deviceId = null;

Future<String> _getDeviceID() async {
  return deviceId ?? (await const FlutterSecureStorage().read(key: 'id') ?? '');
}
