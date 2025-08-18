import 'package:flutter/material.dart';
import 'package:quizzique/logic/logic.dart';
import 'package:quizzique/utils/utils.dart';

class ScoreView extends StatelessWidget {
  final Score score;
  final int rank;
  const ScoreView({super.key, required this.score, required this.rank});

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return SizedBox(
      height: mq.size.height * 0.1,
      width: mq.size.width * 0.8,
      child: Container(
        margin: EdgeInsets.all(mq.size.width * 0.002),
        padding: EdgeInsets.symmetric(
          horizontal: mq.size.width * 0.02,
          vertical: mq.size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$rank.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: rank == 1
                    ? Color(0xffFFD700)
                    : rank == 2
                    ? Color(0xffc0c0c0)
                    : rank == 3
                    ? Color(0xffcd7f32)
                    : Colors.black,
              ),
            ),
            SizedBox(width: mq.size.width * 0.05),
            Text.rich(
              TextSpan(
                text: score.playerName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: '   -   ',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.black),
                  ),
                  TextSpan(
                    text: '${score.score} ${'point'.pluralize(score.score)}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
