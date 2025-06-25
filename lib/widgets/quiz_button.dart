import 'dart:math';

import 'package:flutter/material.dart';

class QuizButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Symbols symbol; // Default symbol, can be changed
  const QuizButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: getSymbolColor(symbol),
      height: double.infinity,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            child: Icon(
              getSymbolIcon(symbol),
              color: Colors.white,
              size: min(
                label == ''
                    ? MediaQuery.of(context).size.height * 0.2
                    : MediaQuery.of(context).size.height * 0.2,
                min(
                  label == ''
                      ? MediaQuery.of(context).size.width * 0.2
                      : MediaQuery.of(context).size.width * 0.2,
                  75,
                ),
              ),
            ),
          ),
          label != '' ? SizedBox(width: 10) : const SizedBox.shrink(),
          label != ''
              ? Expanded(
                  child: Text(
                    label,
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

IconData getSymbolIcon(Symbols symbol) {
  switch (symbol) {
    case Symbols.square:
      return Icons.square_outlined;
    case Symbols.circle:
      return Icons.circle_outlined;
    case Symbols.triangle:
      return Icons.change_history_outlined;
    case Symbols.diamond:
      return Icons.pentagon_outlined;
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
