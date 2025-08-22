import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/widgets/quiz_button.dart';

class FourOptions extends StatefulWidget {
  const FourOptions({
    super.key,
    required this.buttonHeight,
    required this.currentQuestion,
    required this.editMode,
  });

  final double buttonHeight;
  final Question currentQuestion;
  final bool editMode;
  @override
  State<FourOptions> createState() => _FourOptionsState();
}

class _FourOptionsState extends State<FourOptions> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: widget.buttonHeight,
                child: QuizButton(
                  onPressed: () {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.correctAnswerIndex = 0;
                    });
                  },
                  isCorrect: widget.currentQuestion.correctAnswerIndex == 0,
                  label: widget.currentQuestion.answers[0],
                  symbol: Symbols.square,
                  isEditable: widget.editMode,
                  onFieldSubmitted: (value) {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.answers[0] = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: widget.buttonHeight,
                child: QuizButton(
                  onPressed: () {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.correctAnswerIndex = 1;
                    });
                  },
                  isCorrect: widget.currentQuestion.correctAnswerIndex == 1,
                  label: widget.currentQuestion.answers[1],
                  symbol: Symbols.circle,
                  isEditable: widget.editMode,
                  onFieldSubmitted: (value) {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.answers[1] = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: widget.buttonHeight,
                child: QuizButton(
                  onPressed: () {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.correctAnswerIndex = 2;
                    });
                  },
                  isCorrect: widget.currentQuestion.correctAnswerIndex == 2,
                  label: widget.currentQuestion.answers[2],
                  symbol: Symbols.triangle,
                  isEditable: widget.editMode,
                  onFieldSubmitted: (value) {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.answers[2] = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: widget.buttonHeight,
                child: QuizButton(
                  onPressed: () {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.correctAnswerIndex = 3;
                    });
                  },
                  isCorrect: widget.currentQuestion.correctAnswerIndex == 3,
                  label: widget.currentQuestion.answers[3],
                  symbol: Symbols.diamond,
                  isEditable: widget.editMode,
                  onFieldSubmitted: (value) {
                    if (!widget.editMode) return;
                    setState(() {
                      widget.currentQuestion.answers[3] = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
