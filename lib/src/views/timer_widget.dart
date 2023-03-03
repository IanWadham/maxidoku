import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/puzzle.dart';

class TimerWidget extends StatelessWidget
{
  // Show or hide a game-timer from the Puzzle class. If the timer has not
  // yet started or has not yet counted off one second, its value is String '',
  // so this widget will not display anything then...

  TimerWidget({required this.visible,		// User's setting...
               this.textColor,
               Key? key}) : super(key: key);

  final bool   visible;
  final Color? textColor;	// If null, default to Flutter-theme color.

  late Puzzle puzzle;		// Located by Provider's watch<Puzzle> function.

  @override
  Widget build(BuildContext context) {

    Puzzle puzzle   = context.watch<Puzzle>();
    String userTime = puzzle.userTimeDisplay;

    if (visible) {
      return Text(userTime,	// Show the timer, if it has started, else ''.
                  maxLines:  1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold,
                                   color:      textColor,
                   ),
                 );
    }
    else {
      return Text('');		// Timer is hidden: nothing to paint.
    }
  }
}
