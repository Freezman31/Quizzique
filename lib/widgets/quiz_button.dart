import 'package:flutter/material.dart';

class QuizButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final double height;
  const QuizButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: Colors.blue,
      height: height,
      child: Text(label),
    );
  }
}
