import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/widgets/question_types_edit/four_options.dart';
import 'package:quizzique/widgets/question_types_edit/guess.dart';
import 'package:quizzique/widgets/question_types_edit/two_options.dart';

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
    _initializeControllers();
  }

  void _initializeControllers() {
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

    // Update controllers when question changes
    if (questionController.text != currentQuestion.question) {
      questionController.text = currentQuestion.question;
    }
    if (durationController.text != currentQuestion.duration.toString()) {
      durationController.text = currentQuestion.duration.toString();
    }
    final MediaQueryData mq = MediaQuery.of(context);
    final double buttonHeight = (mq.size.height * 0.2);
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
                decoration: BoxDecoration(
                  color:
                      View.of(context).platformDispatcher.platformBrightness ==
                          Brightness.light
                      ? Color.fromARGB(255, 255, 236, 207)
                      : Color.fromARGB(255, 145, 115, 69),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(16),
                    topRight: Radius.circular(8),
                    topLeft: Radius.circular(16),
                  ),
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      setState(() {
                        currentQuestion.question = questionController.text;
                      });
                    }
                  },
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
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    setState(() {
                      currentQuestion.duration =
                          int.tryParse(durationController.text) ?? 0;
                    });
                  }
                },
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Duration (seconds)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  controller: durationController,
                  onTap: () {
                    // Move cursor to the end when tapped
                    durationController.selection = TextSelection.fromPosition(
                      TextPosition(offset: durationController.text.length),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                child: DropdownButton(
                  menuWidth: mq.size.width * 0.7,
                  items: [
                    DropdownMenuItem(
                      value: QuestionType.fourChoices,
                      child: Padding(
                        padding: EdgeInsets.only(left: 2.0),
                        child: Text('Four Choices'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.twoChoices,
                      child: Padding(
                        padding: EdgeInsets.only(left: 2.0),
                        child: Text('Two Choices'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.guess,
                      child: Padding(
                        padding: EdgeInsets.only(left: 2.0),
                        child: Text('Guess'),
                      ),
                    ),
                  ],
                  onChanged: (element) {
                    currentQuestion.type = element!;
                  },
                  value: currentQuestion.type,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: switch (currentQuestion.type) {
                  QuestionType.fourChoices => FourOptions(
                    buttonHeight: buttonHeight,
                    currentQuestion: currentQuestion,
                    editMode: true,
                  ),
                  QuestionType.twoChoices => TwoOptions(
                    buttonHeight: buttonHeight,
                    currentQuestion: currentQuestion,
                    editMode: true,
                  ),
                  QuestionType.guess => Guess(
                    buttonHeight: buttonHeight,
                    currentQuestion: currentQuestion,
                    editMode: true,
                  ),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
