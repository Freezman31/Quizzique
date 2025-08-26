import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzique/logic/logic.dart';

class Guess extends StatefulWidget {
  const Guess({
    super.key,
    required this.buttonHeight,
    required this.currentQuestion,
    required this.editMode,
  });

  final double buttonHeight;
  final Question currentQuestion;
  final bool editMode;

  @override
  State<Guess> createState() => _GuessState();
}

class _GuessState extends State<Guess> {
  final TextEditingController _minController = TextEditingController(
    text: 'aaa',
  );
  final TextEditingController _maxController = TextEditingController(
    text: 'aaa',
  );
  final _rangeController = TextEditingController(text: '5');

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_minController.text == 'aaa') {
      _minController.text = widget.currentQuestion.answers[0] == ''
          ? '0'
          : widget.currentQuestion.answers[0];
    }
    if (_maxController.text == 'aaa') {
      _maxController.text = widget.currentQuestion.answers[1] == ''
          ? '100'
          : widget.currentQuestion.answers[1];
    }
    if (widget.currentQuestion.correctAnswerIndex == null ||
        widget.currentQuestion.correctAnswerIndex! <
            int.parse(_minController.text) ||
        widget.currentQuestion.correctAnswerIndex! >
            int.parse(_maxController.text)) {
      widget.currentQuestion.correctAnswerIndex = int.parse(
        _minController.text,
      );
    }
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: RoundedRectSliderTrackShape(),
              trackHeight: 4.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
              tickMarkShape: RoundSliderTickMarkShape(),
              activeTrackColor: theme.colorScheme.secondary.withAlpha(200),
              valueIndicatorShape: DropSliderValueIndicatorShape(),
              valueIndicatorTextStyle: theme.textTheme.labelLarge!.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
              showValueIndicator: widget.editMode
                  ? ShowValueIndicator.alwaysVisible
                  : ShowValueIndicator.never,
            ),
            child: Slider(
              value: widget.currentQuestion.correctAnswerIndex!.toDouble(),
              min: double.parse(_minController.text),
              max: double.parse(_maxController.text),
              label: '${widget.currentQuestion.correctAnswerIndex}',
              onChanged: (value) {
                if (!widget.editMode) return;
                setState(() {
                  widget.currentQuestion.correctAnswerIndex = value.toInt();
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: widget.editMode
                    ? TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: _minController,
                        onTap: () {
                          _minController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _minController.text.length),
                          );
                        },
                        onChanged: (value) {
                          if (int.parse(value) >=
                              int.parse(_maxController.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Min must be less than max.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _minController.text =
                                (int.parse(_maxController.text) - 1).toString();
                            _minController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: _minController.text.length),
                            );
                          }
                          widget.currentQuestion.answers[0] = value;
                        },
                      )
                    : Text(
                        widget.currentQuestion.answers[0],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
              ),
              const Spacer(flex: 5),
              Expanded(
                child: widget.editMode
                    ? TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: _maxController,
                        onTap: () {
                          // Move cursor to the end when tapped
                          _maxController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _maxController.text.length),
                          );
                        },
                        onChanged: (value) {
                          if (int.parse(value) <=
                              int.parse(_minController.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Max must be more than min.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            _maxController.text =
                                (int.parse(_minController.text) + 1).toString();
                            _maxController
                                .selection = TextSelection.fromPosition(
                              TextPosition(offset: _maxController.text.length),
                            );
                          }
                          widget.currentQuestion.answers[1] = value;
                        },
                      )
                    : Text(
                        widget.currentQuestion.answers[1],
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.right,
                      ),
              ),
            ],
          ),
          widget.editMode ? const SizedBox(height: 20) : SizedBox.shrink(),
          widget.editMode
              ? Center(
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Range (± for answer to be valid)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: _rangeController,
                      onTap: () {
                        // Move cursor to the end when tapped
                        _rangeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _rangeController.text.length),
                        );
                      },
                      onChanged: (value) {
                        widget.currentQuestion.answers[2] = value;
                      },
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
