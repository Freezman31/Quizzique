import 'dart:async';

import 'package:flutter/material.dart';

class Countdown extends StatefulWidget {
  final int duration;
  final int durationBeforeAnswer;
  const Countdown({
    super.key,
    required this.duration,
    required this.durationBeforeAnswer,
  });

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  double progress = 0;
  Timer? timer;
  final Duration _increment = const Duration(milliseconds: 50);
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: widget.durationBeforeAnswer),
      startCountdown,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    timer = Timer.periodic(_increment, (timer) {
      setState(() {
        progress += _increment.inMicroseconds / 1000000 / widget.duration;
      });
      if (progress >= 1) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: CircularProgressIndicator(
            value: progress,
            color: progress <= 1
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.error,
            strokeWidth: mq.size.height * 0.02,
          ),
        ),
        Center(
          child: Text(
            progress < 1
                ? '${(widget.duration - (widget.duration * progress)).round()}s'
                : 'Time\'s up!',
            style: progress < 1
                ? Theme.of(context).textTheme.headlineLarge
                : Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }
}
