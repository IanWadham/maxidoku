import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_timer.dart';

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

  String userTime = ' ';

  // late Puzzle puzzle;	// Located by Provider's read function.
  late GameTimer gameTimer;	// Located by Provider's watch function.

  @override
  Widget build(BuildContext context) {

    gameTimer = context.read<GameTimer>();

    // Test whether the Timer has incremented. If so, display it (optionally).
    userTime  = context.select((GameTimer gameTimer)
                        => gameTimer.userTimeDisplay);

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
