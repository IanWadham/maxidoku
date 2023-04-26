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
    clearClock();
  }

  void clearClock()
  {
    stopClock();
    userTimeDisplay = '';
    notifyListeners();				// Erase time display (if reqd).
  }

  void startClock()
  {
    assert(_ticker == null, 'ASSERT ERROR startClock(): _ticker is NOT null.');
    _userTime.reset();
    userTimeDisplay = '0:00';
    notifyListeners();				// Display zero time (if reqd).
    _userTime.start();
    // Start a 1-second ticker, but only if it is null (not already running).
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_ticker)
      {
        // One tick per second.
        Duration t = _userTime.elapsed;
        userTimeDisplay = '${t.toString().split('.').first}'; // (h)h:mm:ss
        if (t < Duration(hours: 1)) {
          // Remove leading zero(s) and colon.
          int index = userTimeDisplay.indexOf(':') + 1;
          if (t < Duration(minutes: 10)) {
            index++;
          }
          userTimeDisplay = userTimeDisplay.substring(index /* to end */);
        }
        notifyListeners();			// Bump time display (if reqd).
      }
    );
  }

  void stopClock()
  {
    // Stop the clock, but only if it is running, otherwise do nothing. This
    // makes it easy to interrupt the game, regardless of its current Play
    // status and of whether the player has won, is quitting or is restarting.

    if (_ticker != null) {
      _userTime.stop();
      _ticker?.cancel();
      _ticker = null;
      debugPrint('Clock STOPPED.');
    }
    else {
      debugPrint('DO NOTHING. Clock is not running.');
    }
  }

} // End class GameTimer.
