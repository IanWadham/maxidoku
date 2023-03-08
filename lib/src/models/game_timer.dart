import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import 'dart:async';		// Needed to compile Timer and _ticker.

class GameTimer with ChangeNotifier
{
  GameTimer();

  // Clock starts whenever the user decides to start playing a game or level.
  // Clock stops whenever he/she finishes the game or level or abandons it.
  Stopwatch  _userTime = Stopwatch();
  Timer?     _ticker = null;		// Null when there is no Timer running.
  String     userTimeDisplay = '0:00';	// Updated by Timer, once per second.

  void init()
  {
    _ticker?.cancel();
    _ticker = null;
  }

  void startClock()
  {
    return;	// Hook to disable Timer when testing BoardView, CellView, etc.

    // TODO - Test to make sure that this assert does not trigger.
    assert(_ticker == null, 'ASSERT ERROR startClock(): _ticker is NOT null.');
    debugPrint('START THE CLOCK!!!');
    _userTime.reset();
    _userTime.start();
    // Start a 1-second ticker, but only if it is null (not already running).
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_ticker)
      {
        // One tick per second.
        Duration t = _userTime.elapsed;
        userTimeDisplay = '${t.toString().split('.').first}'; // (h)h:mm:ss
        if (t < Duration(hours: 1)) {
          // Remove leading zero(s) and colon.
          int xxx = userTimeDisplay.indexOf(':') + 1;
          if (t < Duration(minutes: 10)) {
            xxx++;
          }
          userTimeDisplay = userTimeDisplay.substring(xxx /* to end */);
        }
        notifyListeners();			// Display the time (if reqd).
      }
    );
  }

  void stopClock()
  {
    return;	// Hook to disable Timer when testing BoardView, CellView, etc.

    // TODO - Test to make sure that this assert does not trigger.
    assert(_ticker != null, 'ASSERT ERROR stopClock(): _ticker IS NULL.');
    _userTime.stop();
    _ticker?.cancel();
    _ticker = null;
    debugPrint('STOP THE CLOCK!!!');
  }

} // End class GameTimer.
