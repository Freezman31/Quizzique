import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final Symbols symbol; // Default symbol, can be changed
  final bool isEditable;
  final bool isCorrect;
  final Function(String)? onFieldSubmitted;
  const QuizButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.symbol,
    this.isEditable = false,
    this.onFieldSubmitted,
    this.isCorrect = false,
  });

  @override
  State<QuizButton> createState() => _QuizButtonState();
}

class _QuizButtonState extends State<QuizButton> {
  @override
  Widget build(BuildContext context) {
    TextEditingController textController = TextEditingController(
      text: widget.label,
    );
    return MaterialButton(
      onPressed: widget.onPressed,
      color: getSymbolColor(widget.symbol),
      height: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              getSymbolIcon(widget.symbol, widget.isCorrect),
              color: Colors.white,
              size: min(
                widget.label == ''
                    ? MediaQuery.of(context).size.height * 0.2
                    : MediaQuery.of(context).size.height * 0.2,
                min(
                  widget.label == ''
                      ? MediaQuery.of(context).size.width * 0.2
                      : MediaQuery.of(context).size.width * 0.2,
                  75,
                ),
              ),
            ),
          ),
          widget.label != '' ? SizedBox(width: 10) : const SizedBox.shrink(),
          widget.label != ''
              ? widget.isEditable
                    ? Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            counterStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          minLines: 1,
                          maxLines: 3,
                          maxLength: 200,
                          autocorrect: true,
                          textCapitalization: TextCapitalization.sentences,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                          controller: textController,
                          onFieldSubmitted: (value) {
                            if (widget.onFieldSubmitted != null) {
                              widget.onFieldSubmitted!(value);
                            }
                          },
                          onTapOutside: (event) {
                            if (widget.onFieldSubmitted != null) {
                              widget.onFieldSubmitted!(textController.text);
                            }
                          },
                        ),
                      )
                    : Expanded(
                        child: Text(
                          widget.label,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

enum Symbols { square, circle, triangle, diamond }

IconData getSymbolIcon(Symbols symbol, bool isCorrect) {
  switch (symbol) {
    case Symbols.square:
      return isCorrect ? Icons.square : Icons.square_outlined;
    case Symbols.circle:
      return isCorrect ? Icons.circle : Icons.circle_outlined;
    case Symbols.triangle:
      return isCorrect ? Icons.star : Icons.star_outline;
    case Symbols.diamond:
      return isCorrect ? Icons.pentagon : Icons.pentagon_outlined;
  }
}

Color getSymbolColor(Symbols symbol) {
  switch (symbol) {
    case Symbols.square:
      return Colors.red;
    case Symbols.circle:
      return Colors.green;
    case Symbols.triangle:
      return Colors.blue;
    case Symbols.diamond:
      return Colors.purple;
  }
}
