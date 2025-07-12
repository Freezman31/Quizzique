import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizapp/logic/logic.dart';
import 'package:quizapp/widgets/quiz_button.dart';

class QuizEdit extends StatefulWidget {
  final Client client;
  final Quiz quiz;
  const QuizEdit({super.key, required this.client, required this.quiz});

  @override
  State<QuizEdit> createState() => _QuizEditState();
}

class _QuizEditState extends State<QuizEdit> {
  int currentQuestionIndex = 0;
  late TextEditingController questionController;
  late TextEditingController durationController;

  @override
  void initState() {
    super.initState();
    final currentQuestion = widget.quiz.questions[currentQuestionIndex];
    questionController = TextEditingController(text: currentQuestion.question);
    durationController = TextEditingController(
      text: currentQuestion.duration.toString(),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Question currentQuestion = widget.quiz.questions[currentQuestionIndex];
    final double buttonHeight = (MediaQuery.of(context).size.height * 0.2);
    final ScrollController scrollController = ScrollController();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Stack(
              children: [
                Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: false,
                  controller: scrollController,
                  child: ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) => setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = widget.quiz.questions.removeAt(oldIndex);
                      widget.quiz.questions.insert(newIndex, item);
                      if (oldIndex == currentQuestionIndex) {
                        currentQuestionIndex = newIndex;
                      } else if (newIndex <= currentQuestionIndex &&
                          oldIndex > currentQuestionIndex) {
                        currentQuestionIndex++;
                      } else if (newIndex > currentQuestionIndex &&
                          oldIndex < currentQuestionIndex) {
                        currentQuestionIndex--;
                      }
                    }),
                    scrollController: scrollController,
                    buildDefaultDragHandles: false,
                    itemCount: widget.quiz.questions.length,
                    itemBuilder: (context, index) {
                      final question = widget.quiz.questions[index];
                      return ReorderableDragStartListener(
                        index: index,
                        key: Key(index.toString()),
                        child: ListTile(
                          title: Text(
                            question.question,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Duration: ${question.duration} seconds',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {
                            setState(() {
                              currentQuestionIndex = index;
                            });
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                widget.quiz.questions.removeAt(index);
                                if (currentQuestionIndex >= index) {
                                  currentQuestionIndex =
                                      (currentQuestionIndex - 1).clamp(
                                        0,
                                        widget.quiz.questions.length - 1,
                                      );
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(10.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        widget.quiz.questions.add(Question.empty());
                        currentQuestionIndex = widget.quiz.questions.length - 1;
                      });
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 236, 207),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(16),
                    topRight: Radius.circular(8),
                    topLeft: Radius.circular(16),
                  ),
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: InputBorder.none,
                  ),
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 200,
                  autocorrect: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                  controller: questionController,
                  onFieldSubmitted: (value) {
                    setState(() {
                      currentQuestion.question = value;
                    });
                  },
                  onTapOutside: (event) {
                    setState(() {
                      currentQuestion.question = questionController.text;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Duration (seconds)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                controller: durationController,
                onFieldSubmitted: (value) {
                  setState(() {
                    currentQuestion.duration = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: QuizButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestion.correctAnswerIndex = 0;
                                });
                              },
                              isCorrect:
                                  currentQuestion.correctAnswerIndex == 0,
                              label: currentQuestion.answers[0],
                              symbol: Symbols.square,
                              isEditable: true,
                              onFieldSubmitted: (value) {
                                setState(() {
                                  currentQuestion.answers[0] = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: QuizButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestion.correctAnswerIndex = 1;
                                });
                              },
                              isCorrect:
                                  currentQuestion.correctAnswerIndex == 1,
                              label: currentQuestion.answers[1],
                              symbol: Symbols.circle,
                              isEditable: true,
                              onFieldSubmitted: (value) {
                                setState(() {
                                  currentQuestion.answers[1] = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: QuizButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestion.correctAnswerIndex = 2;
                                });
                              },
                              isCorrect:
                                  currentQuestion.correctAnswerIndex == 2,
                              label: currentQuestion.answers[2],
                              symbol: Symbols.triangle,
                              isEditable: true,
                              onFieldSubmitted: (value) {
                                setState(() {
                                  currentQuestion.answers[2] = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: buttonHeight,
                            child: QuizButton(
                              onPressed: () {
                                setState(() {
                                  currentQuestion.correctAnswerIndex = 3;
                                });
                              },
                              isCorrect:
                                  currentQuestion.correctAnswerIndex == 3,
                              label: currentQuestion.answers[3],
                              symbol: Symbols.diamond,
                              isEditable: true,
                              onFieldSubmitted: (value) {
                                setState(() {
                                  currentQuestion.answers[3] = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
