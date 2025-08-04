import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

const String databaseId = '6859582600031c46e49c';
const String collectionId = '685d148300346d2203a7';
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';

Future main(final context) async {
  final Client client = Client()
      .setEndpoint(appwriteEndpoint)
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(Platform.environment['APPWRITE_KEY']);

  final Databases databases = Databases(client);
  final payload = jsonDecode(context.req.body.toString());

  try {
    final String answerId = payload['\$id'];
    final int userAnswer = payload['answerIndex'];
    final String questionId = payload['questionID'];
    final String playerId = payload['playerID'];
    final String playerName = payload['playerName'] ?? 'Unknown Player';
    final String gameId = payload['games']['\$id'];
    final Map<String, dynamic> scores = jsonDecode(payload['games']['scores']);
    final DateTime startTime = DateTime.parse(payload['games']['\$updatedAt']);
    final DateTime submitTime = DateTime.parse(payload['\$updatedAt']);
    final Duration timeAllowed = Duration(
        seconds:
            jsonDecode(payload['games']['currentQuestion'])['timeAllowed'] ??
                30); // Default to 30s
    final String? question = getQuestion(
      databases: databases,
      payload: payload,
      questionId: questionId,
      context: context,
    );
    final bool answerExists = await checkIfAnswerExists(
      databases: databases,
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
    final int correctAnswer = jsonDecode(question)['c'];
    context.log('Correct answer: $correctAnswer');
    context.log('User answer: $userAnswer');

    final bool isCorrect = userAnswer == correctAnswer;
    final int timeTaken = submitTime.difference(startTime).inSeconds - 3;
    final int score =
        (1000 * (1 - (timeTaken / 2) / timeAllowed.inSeconds)).ceil();
    if (timeTaken > timeAllowed.inSeconds) {
      context.log(
          'Time taken exceeds allowed time: $timeTaken seconds, whereas allowed is ${timeAllowed.inSeconds} seconds');
      databases.deleteDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: answerId);
      context.log('Answer deleted due to time limit exceeded');
      return context.res.send(
          jsonEncode({
            'status': 'error',
            'message': 'Time limit exceeded',
          }),
          408);
    }
    scores.putIfAbsent(playerId, () => {'s': 0, 'name': playerName});
    scores[playerId]['s'] = scores[playerId]['s'] + score;
    if (score > 0) {
      databases.updateDocument(
        databaseId: databaseId,
        collectionId: '685990a30018382797dc',
        documentId: gameId,
        data: {
          'scores': jsonEncode(scores),
        },
      );
    }
    databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: answerId,
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
  required final Databases databases,
  required final String answerId,
  required final String playerId,
  required final String questionId,
  required final Map<String, dynamic> payload,
  required final dynamic context,
}) async {
  final previousAnswer = await databases.listDocuments(
    databaseId: databaseId,
    collectionId: collectionId,
    queries: [
      Query.equal('playerID', playerId),
      Query.equal('questionID', questionId),
      Query.equal('games', payload['games']['\$id']),
      Query.limit(2), // Only need to check if more than 1 exists
    ],
  );

  if (previousAnswer.documents.length > 1) {
    context.log('Previous answer found for player: $playerId');
    databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: answerId);
    return true;
  }
  return false;
}

String? getQuestion({
  required final Databases databases,
  required final dynamic payload,
  required final String questionId,
  required final dynamic context,
}) {
  return (payload['games']['quiz']['questions'] as List<dynamic>)
      .firstWhere((q) => jsonDecode(q)['id'] == questionId, orElse: () => null);
}
