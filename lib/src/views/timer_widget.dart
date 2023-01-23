import 'package:flutter/foundation.dart';
import 'dart:async';		// Needed to compile Timer and _ticker.


  // Clock starts whenever the user decides to start solving a Puzzle.
  // Clock stops whenever he/she finishes solving the Puzzle or abandons it.
  Stopwatch  _solutionTime = Stopwatch();
  Timer?     _ticker = null;		// Null when there is no Timer running.
  String     solutionTimeDisplay = '';	// Updated by Timer, once per second.

  void startClock()
  {
    // return;			// Hook for testing BoardView, CellView, etc.

    // TODO - Test to make sure that this assert does not trigger.
    assert(_ticker == null, 'ASSERT ERROR startClock(): _ticker is NOT null.');
    print('START THE CLOCK!!!');
    _solutionTime.reset();
    _solutionTime.start();
    // Start a 1-second ticker, but only if it is null (not already running).
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_ticker)
      {
        // One tick per second.
        Duration t = _solutionTime.elapsed;
        solutionTimeDisplay = '${t.toString().split('.').first}'; // (h)h:mm:ss
        if (t < Duration(hours: 1)) {
          // Remove leading zero(s) and colon.
          int xxx = solutionTimeDisplay.indexOf(':') + 1;
          if (t < Duration(minutes: 10)) {
            xxx++;
          }
          solutionTimeDisplay = solutionTimeDisplay.substring(xxx /* to end */);
        }
        notifyListeners();			// Display the time (if reqd).
      }
    );
  }

  void stopClock()
  {
    // return;			// Hook for testing BoardView, CellView, etc.

    // TODO - Test to make sure that this assert does not trigger.
    assert(_ticker != null, 'ASSERT ERROR stopClock(): _ticker IS NULL.');
    _solutionTime.stop();
    _ticker?.cancel();
    _ticker = null;
    print('STOP THE CLOCK!!!');
  }

