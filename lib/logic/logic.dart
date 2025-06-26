import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

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
          id: document.$id,
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
  final String id;
  final String question;
  final List<String> answers;
  final int? correctAnswerIndex;

  Question({
    required this.id,
    required this.question,
    required this.answers,
    this.correctAnswerIndex,
  });
  Question.empty()
    : id = '',
      question = '',
      answers = ['', '', '', ''],
      correctAnswerIndex = null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Question otherQuestion = other as Question;
    return id == otherQuestion.id &&
        question == otherQuestion.question &&
        listEquals(answers, otherQuestion.answers) &&
        correctAnswerIndex == otherQuestion.correctAnswerIndex;
  }
}
