import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

const String databaseId = '6859582600031c46e49c';
const String answerTableId = '685d148300346d2203a7';
const String scoreTableId = '68953e9100224ddb0584';

Future main(final dynamic context) async {
  final Client client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT']!)
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(context.req.headers['x-appwrite-key']);

  final TablesDB tablesDB = TablesDB(client);
  final payload = jsonDecode(context.req.body.toString());

  try {
    final String answerId = payload['\$id'];
    final int userAnswer = payload['answerIndex'];
    final String questionId = payload['questionID'];
    final String playerId = payload['playerID'];
    final String playerName = payload['playerName'] ?? 'Unknown Player';
    final String gameId = payload['games']['\$id'];
    final DateTime startTime = DateTime.parse(payload['games']['\$updatedAt']);
    final DateTime submitTime = DateTime.parse(payload['\$updatedAt']);
    final QuestionType questionType = QuestionType
        .values[jsonDecode(payload['games']['currentQuestion'])['t']];
    final Duration timeAllowed = Duration(
        seconds:
            jsonDecode(payload['games']['currentQuestion'])['timeAllowed'] ??
                30); // Default to 30s
    final String? question = getQuestion(
      tablesDB: tablesDB,
      payload: payload,
      questionId: questionId,
      context: context,
    );
    final bool answerExists = await checkIfAnswerExists(
      tablesDB: tablesDB,
      answerId: answerId,
      playerId: playerId,
      questionId: questionId,
      payload: payload,
      context: context,
    );
    if (answerExists) {
      context.log('Answer already exists for player: $playerId');
      return context.res.send(
          jsonEncode({
            'status': 'error',
            'message': 'Answer already exists',
          }),
          400);
    }
    if (question == null) {
      context.log('Payload: $payload');
      context.log('Question list: ${payload['games']['quiz']['questions']}');
      context.log(question ?? 'null');
      context.error('Question not found for ID: $questionId');
      return context.res.send('Question not found', 404);
    }
    final questionPayload = jsonDecode(question);
    final int correctAnswer = questionPayload['c'];
    context.log('Correct answer: $correctAnswer');
    context.log('User answer: $userAnswer');
    bool isCorrect;
    final int timeTaken = submitTime.difference(startTime).inSeconds - 3;
    int score;
    if (questionType == QuestionType.guess) {
      final int range = int.parse(questionPayload['3'].toString());
      isCorrect = (userAnswer - correctAnswer).abs() <= range;
      score = (1000 * (1 - (timeTaken / 2) / timeAllowed.inSeconds)).ceil() *
          ((range - (userAnswer - correctAnswer).abs() * .5) / range).ceil();
    } else {
      isCorrect = userAnswer == correctAnswer;
      score = (1000 * (1 - (timeTaken / 2) / timeAllowed.inSeconds)).ceil();
    }
    if (timeTaken > timeAllowed.inSeconds) {
      context.log(
          'Time taken exceeds allowed time: $timeTaken seconds, whereas allowed is ${timeAllowed.inSeconds} seconds');
      tablesDB.deleteRow(
          databaseId: databaseId, tableId: answerId, rowId: answerId);
      context.log('Answer deleted due to time limit exceeded');
      return context.res.send(
          jsonEncode({
            'status': 'error',
            'message': 'Time limit exceeded',
          }),
          408);
    }

    if (score > 0 && isCorrect) {
      final scores = await tablesDB.listRows(
        databaseId: databaseId,
        tableId: scoreTableId,
        queries: [
          Query.equal('game', gameId),
          Query.equal('playerID', playerId),
        ],
      );
      if (scores.rows.isEmpty) {
        await tablesDB.createRow(
          databaseId: databaseId,
          tableId: scoreTableId,
          rowId: ID.unique(),
          data: {
            'playerID': playerId,
            'playerName': playerName,
            'game': gameId,
            'score': isCorrect ? score : 0,
          },
        );
      } else {
        final existingScore = scores.rows.first;
        final newScore =
            (existingScore.data['score'] as int) + (isCorrect ? score : 0);
        await tablesDB.updateRow(
          databaseId: databaseId,
          tableId: scoreTableId,
          rowId: existingScore.$id,
          data: {'score': newScore},
        );
      }
    }
    tablesDB.updateRow(
      databaseId: databaseId,
      tableId: answerId,
      rowId: answerId,
      data: {'correct': isCorrect, 'score': isCorrect ? score : 0},
    );

    return context.res.send(
        jsonEncode({
          'status': 'success',
          'message': 'Answer verified',
          'data': {
            'correct': isCorrect,
            'score': isCorrect ? score : 0,
          },
        }),
        200);
  } catch (e, stacktrace) {
    context.error('Error processing answer: $e');
    context.log('Error details: ${e.toString()}');
    context.log('Stack trace: ${stacktrace.toString()}');
    context.log('Payload: $payload');
    return context.res.send('Internal Server Error', 500);
  }
}

Future<bool> checkIfAnswerExists({
  required final TablesDB tablesDB,
  required final String answerId,
  required final String playerId,
  required final String questionId,
  required final Map<String, dynamic> payload,
  required final dynamic context,
}) async {
  final previousAnswer = await tablesDB.listRows(
    databaseId: databaseId,
    tableId: answerTableId,
    queries: [
      Query.equal('playerID', playerId),
      Query.equal('questionID', questionId),
      Query.equal('games', payload['games']['\$id']),
      Query.limit(2), // Only need to check if more than 1 exists
      Query.select(['*', 'games.*'])
    ],
  );

  if (previousAnswer.rows.length > 1) {
    context.log('Previous answer found for player: $playerId');
    tablesDB.deleteRow(
        databaseId: databaseId, tableId: answerTableId, rowId: answerId);
    return true;
  }
  return false;
}

String? getQuestion({
  required final TablesDB tablesDB,
  required final dynamic payload,
  required final String questionId,
  required final dynamic context,
}) {
  return (payload['games']['quiz']['questions'] as List<dynamic>)
      .firstWhere((q) => jsonDecode(q)['id'] == questionId, orElse: () => null);
}

enum QuestionType {
  fourChoices,
  twoChoices,
  guess,
}
