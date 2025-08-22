import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/widgets/quiz_button.dart';

class TwoOptions extends StatefulWidget {
  const TwoOptions({
    super.key,
    required this.buttonHeight,
    required this.currentQuestion,
    required this.editMode,
  });

  final double buttonHeight;
  final Question currentQuestion;
  final bool editMode;

  @override
  State<TwoOptions> createState() => _TwoOptionsState();
}

class _TwoOptionsState extends State<TwoOptions> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: widget.buttonHeight * 2,
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
            height: widget.buttonHeight * 2,
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
    );
  }
}
