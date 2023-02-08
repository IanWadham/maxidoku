import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:community_material_icon/community_material_icon.dart';

// import 'package:flutter/src/foundation/binding.dart';
// import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'messages.dart';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';

// TO BE TESTED --- import 'board_view.dart';
// import 'painting_specs.dart';

import 'painting_specs_2d.dart';
import 'puzzle_painter_2d.dart';

import 'painting_specs_3d.dart';
import 'puzzle_painter_3d.dart';

/* ************************************************************************** **
   ICON BUTTONS - Mark and go back to Mark???
** ************************************************************************** */

/* ************************************************************************** **
  // Can get device/OS/platform at https://pub.dev/packages/device_info_plus
  // See also the "Dependencies" list in the column at RHS of that page re
  // info on MacOS, Linux, Windows, etc.
** ************************************************************************** */

class PuzzleView extends StatelessWidget
{
// Displays a 2D or 3D Sudoku puzzle of a selected type, difficulty and size.
//
// Widget build() paints or repaints the entire screen with a puzzle. Entered
// initially from app.dart via Provider, operating on the Puzzle model. Can then
// be entered automatically by Flutter whenever IT needs to repaint (e.g. during
// a window-resize on a computer desktop) OR whenever the puzzle changes in any
// way (due to a user action) OR when the timer display is updated OR when the
// puzzle's view has to change without changing any puzzle data (e.g. to view
// the sides or back of a 3D puzzle). All of these repaints are triggered by
// Provider, using calls to notifyListeners(), mostly from the Puzzle methods.
//
// A further complication is that messages to the user can be issued only when
// there is no repainting going on and they must not be accidentally RE-issued
// if a screen repaint occurs, otherwise the screen darkens and goes black. Some
// messages originate from actions within the puzzle model. These are deferred
// and later handled by a postFrameCallback() procedure in the PuzzleBoardView's
// Widget build(). PuzzleBoardView is a sub-Widget of the PuzzleView Widget.

  final bool darkMode;		// Display in dark theme-mode colours or light.

  const PuzzleView(this.darkMode, {Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Set portrait/landscape, depending on the device or window-dimensions.
    Orientation orientation = MediaQuery.of(context).orientation;

    // Find the Puzzle objecti (the model), which has been created by Provider.
    Puzzle puzzle = context.read<Puzzle>();

    // Save the orientation, for later use by PuzzlePainters and paint().
    // A setter in Puzzle saves "portrait" in either 2D or 3D PaintingSpecs.
    puzzle.portrait = (orientation == Orientation.portrait);

    // Set up Puzzle's theme in dark/light mode and get the icon button colours.
    puzzle.setTheme(darkMode);
    Color background = Color(puzzle.background);
    Color foreground = Color(puzzle.foreground);

    // Create the list of action-icons, making the icons resizeable.
    double iconSize = MediaQuery.of(context).size.shortestSide;
    double nIcons = 10.0;
    iconSize = 0.4 * iconSize / nIcons;

    List<IconButton> actionIcons = [
      IconButton(
        icon: const Icon(CommunityMaterialIcons.exit_run), // exit_to_app),
        iconSize: iconSize,
        tooltip: 'Return to list of puzzles',
        color:   foreground,
        onPressed: () {
          exitScreen(context, puzzle);
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        iconSize: iconSize,
        tooltip: 'Settings',
        color:   foreground,
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(Icons.save_outlined),
        iconSize: iconSize,
        tooltip: 'Save puzzle',
        color:   foreground,
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(Icons.file_download),
        iconSize: iconSize,
        tooltip: 'Restore puzzle',
        color:   foreground,
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.lightbulb_on_outline),
        iconSize: iconSize,
        tooltip: 'Get a hint',
        color:   foreground,
        onPressed: () {
          puzzle.hint();
        },
      ),
      IconButton(
        icon: const Icon(Icons.undo_outlined),
        iconSize: iconSize,
        tooltip: 'Undo a move',
        color:   foreground,
        onPressed: () {
          puzzle.undo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.redo_outlined),
        iconSize: iconSize,
        tooltip: 'Redo a move',
        color:   foreground,
        onPressed: () {
          puzzle.redo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.devices_outlined),
        iconSize: iconSize,
        tooltip: 'Generate a new puzzle',
        color:   foreground,
        onPressed: () {
          generatePuzzle(puzzle, context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.check_circle_outline_outlined),
        iconSize: iconSize,
        tooltip: 'Check that the puzzle you have entered is valid',
        color:   foreground,
        onPressed: () async {
          checkPuzzle(puzzle, context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.restart_alt_outlined),
        iconSize: iconSize,
        tooltip: 'Start solving this puzzle again',
        color:   foreground,
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
    ]; // End list of action icons

    // Paint the puzzle with the action icons in a row at the top.
    return Scaffold(		// Omit AppBar, to maximize real-estate.
      body: Column(
        children: <Widget> [
          Ink( // Give puzzle-background colour to row of IconButtons.
            color: background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actionIcons,
            ),
          ),
          Expanded(
            child: PuzzleBoardView(),
          ),
        ],
      ), // End body: Column(
    ); // End return Scaffold(
  } // End Widget build


  // PROCEDURES FOR ICON ACTIONS AND USER MESSAGES.

  void generatePuzzle(Puzzle puzzle, BuildContext context)
  async
  {
    // Generate a puzzle of the requested level of difficulty.
    debugPrint('GENERATE Puzzle: Play status ${puzzle.puzzlePlay}');
    bool newPuzzleOK = (puzzle.puzzlePlay == Play.NotStarted) ||
                       (puzzle.puzzlePlay == Play.ReadyToStart);
    if (! newPuzzleOK) {
      newPuzzleOK = await questionMessage(
        context,
        'Generate a new puzzle?',
        'You could lose your work so far. Do you '
        ' really want to generate a new puzzle?',
      );
    }
    if (newPuzzleOK) {
      puzzle.generatePuzzle();
    }
  }

  void checkPuzzle(Puzzle puzzle, BuildContext context)
  async
  {
    // Validate a puzzle that has been tapped in or loaded by the user.
    debugPrint('CHECK Puzzle: Play status ${puzzle.puzzlePlay}');
    int error = puzzle.checkPuzzle();
    switch(error) {
      case 0:
        bool finished = await questionMessage(
          context,
          'Finished?',
          'Your puzzle has a single solution and is ready to be played.'
          ' Would you like to make it into a finished puzzle, ready to'
          ' solve, or continue working on it?',
          okText:     'Finish Up',
          cancelText: 'Continue',
        );
        if (finished) {
          // Convert the entered data into a Puzzle and re-display it.
          puzzle.convertDataToPuzzle();
          // TODO - Suggest saving the puzzle to a file before playing it.
        }
        return;
      case -1:
        await infoMessage(
          context,
          'No Solution Found',
          'Your puzzle has no solution. Please check that you entered all'
          ' the data correctly and with no omissions, then edit it and try'
          ' again.'
        );
        return;
      case -2:
        await infoMessage(
          context,
          '',
          ''
        );
        return;
      case -3:
        await infoMessage(
          context,
          'Solution Is Not Unique',
          'Your puzzle has more than one solution. Please check that you'
          ' entered all the data correctly and with no omissions, then edit it'
          ' and try again - maybe add some clues to narrow the possibilities.'
        );
        return;
      default:
    }
  }

  void exitScreen(BuildContext context, Puzzle puzzle)
  async
  {
    // Quit the Puzzle screen, maybe leaving a puzzle unfinished.
    bool okToQuit = (puzzle.puzzlePlay == Play.NotStarted) ||
                    (puzzle.puzzlePlay == Play.ReadyToStart) ||
                    (puzzle.puzzlePlay == Play.Solved);
    if (! okToQuit) {
      okToQuit = await questionMessage(
                 context,
                 'Quit?',
                 'You could lose your work so far. Do you really want to quit?',
                 );
    }
    if (okToQuit && context.mounted) {
      Navigator.pop(context);
    }
  }

  static const routeName = '/puzzle_view';

} // End class PuzzleView


class PuzzleBoardView extends StatelessWidget with ChangeNotifier
{
  PuzzleBoardView({super.key});

  // TODO - StatelessWidget is an immutable class, but ChangeNotifier mixin
  //        is not. Also hitPos cannot be "final" and so the PuzzleBoardView
  //        constructor cannot be "const". What to do?

  Offset hitPos    = const Offset(-1.0, -1.0);
  late Puzzle        puzzle;	// Located by Provider's watch<Puzzle> function.

  @override
  // This widget tree contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {

    // Locate the puzzle's model and repaint this widget tree when the model
    // changes and emits notifyListeners(). Changes can be due to user-moves
    // (taps) or actions on icon-buttons such as Undo/Redo, Generate and Hint.
    // In 3D puzzles, the repaint can be due to rotation, with no data change.

    puzzle = context.watch<Puzzle>();

    // Enable messages to the user after major changes of puzzle-status.
    WidgetsBinding.instance.addPostFrameCallback((_)
                            {executeAfterBuild(context);});

    // Find out if the System (O/S) or Flutter colour Theme is dark or light.
    bool darkMode = (Theme.of(context).brightness == Brightness.dark);
    if (puzzle.puzzleMap.specificType == SudokuType.Roxdoku) {
      return SizedBox(
        // We wish to fill the parent, in either Portrait or Landscape layout.
        height: (MediaQuery.of(context).size.height),
        width:  (MediaQuery.of(context).size.width),
        child:  Listener(
          onPointerDown: _possibleHit3D,
          child: CustomPaint(
            painter: PuzzlePainter3D(puzzle, darkMode),
          ),
        ),
      );
    }
    else {
      return SizedBox(
        // We wish to fill the parent, in either Portrait or Landscape layout.
        height: (MediaQuery.of(context).size.height),
        width:  (MediaQuery.of(context).size.width),
        child:  Listener(
          onPointerDown: _possibleHit2D,
          child: CustomPaint(
            painter: PuzzlePainter2D(puzzle, darkMode),
          ),
        ),
      );
    }
  } // End Widget build()

  Future<void> executeAfterBuild(BuildContext context) async
  {
    if (puzzle.delayedMessage.messageType != '') {
      // The user selected a new puzzle from the menu-screen or icon-button
      // or asked for a retry to get a more difficult puzzle (see below). The
      // delayed message is stored until after the puzzle area is repainted.
      Message m = puzzle.delayedMessage;

      // Clear the message, to avoid repaint and blacking out on resizes, etc.
      puzzle.delayedMessage = Message('', '');

      bool retrying = false;
      if (m.messageType == 'Q') {
        retrying = await questionMessage(
                         context, 'Generate Puzzle', m.messageText,
                         okText: 'Try Again', cancelText: 'Accept');
      }
      else {
        // Inform the user about the puzzle that was generated, then return.
        await infoMessage(context, 'Generate Puzzle', m.messageText);
        if (m.messageType == 'F') {
          // TODO - Improve the user-feedback when/if this happens...
          debugPrint('BAIL OUT');
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      }
      if (retrying) {
        // Keep re-generating and repainting to try for the required Difficulty.
        // N.B. Puzzle.generatePuzzle() will trigger a widget re-build and a
        //      repaint, returning control to executeAferBuild() (above) again.
        puzzle.delayedMessage = Message('', '');
        puzzle.generatePuzzle();
      }
      else {
        // A puzzle was selected, generated and accepted, so start the clock!
        // puzzle.startClock();
      }
      return;
    }

    // Check to see if there was any major change during the last repaint of
    // the Puzzle. If so, issue appropriate messages. Flutter does not allow
    // them to be issued or automatically queued during a repaint.
    Play playNow = puzzle.puzzlePlay;
    if (puzzle.isPlayUnchanged()) {
      return;
    }
    // Play-status of Puzzle has changed. Need to issue a message to the user?
    if (playNow == Play.BeingEntered) {
      await questionMessage(
                        context,
                        'Tap In Own Puzzle?',
                        'Do you wish to tap in your own puzzle?');
    // TODO - Expand this message a bit. Make it more explanatory.
    }
    else if (playNow == Play.Solved) {
      // puzzle.stopClock();
      await infoMessage(context,
                        'CONGRATULATIONS!!!',
                        'Well done!!'
                        ' You have reached the end of the puzzle!');
    }
    else if (playNow == Play.HasError) {
      await infoMessage(context,
                        'Incorrect Solution',
                        'Your solution contains one or more errors.'
                        ' Please correct them and try again.');
    }
  }

  // Handle the user's PointerDown actions on the puzzle-area and controls.
  bool _possibleHit(String D, Rect puzzleRect, Rect controlRect)
  {
    // debugPrint ('_possibleHit$D at $hitPos');
    bool puzzleHit = puzzleRect.contains(hitPos);
    if (puzzleHit && (D == '2D')) {
      // Hit is on puzzle-area: get integer co-ordinates of cell.
      Offset point = hitPos - puzzleRect.topLeft;
      double cellSide = puzzleRect.width / puzzle.puzzleMap.sizeX;
      int x = (point.dx / cellSide).floor();
      int y = (point.dy / cellSide).floor();
      // debugPrint('Hit is at puzzle-cell ($x, $y)');
      // If hitting this cell is a valid move, the Puzzle model will be updated.
      puzzle.hitPuzzleArea(x, y);
    }
    else if (puzzleHit && (D == '3D')) {
      return true;		// Do the rest using 3D functions.
    }
    else {
      if (controlRect.contains(hitPos)) {
        // Hit is on control-area: get current number of controls.
        // Use the same control-area actions for both 2D and 3D puzzles.
        int nSymbols = puzzle.puzzleMap.nSymbols;
        int nCells = (puzzle.puzzlePlay == Play.NotStarted) ||
                     (puzzle.puzzlePlay == Play.BeingEntered) ?
                     nSymbols + 1 : nSymbols + 2;
        bool horizontal = controlRect.width > controlRect.height;
        double cellSide = horizontal ? controlRect.width / nCells
                                     : controlRect.height / nCells;
        Offset point = hitPos - controlRect.topLeft;
        int x = (point.dx / cellSide).floor();
        int y = (point.dy / cellSide).floor();
        int selection = horizontal ? x : y;	// Get the selected control num.
        puzzle.hitControlArea(selection);
      }
      else {
        // Not a hit. Don't repaint.
        debugPrint('_possibleHit$D: NOT A HIT');
      }
    }
    // NOTE: If the hit led to a valid change in the puzzle model,
    //       notifyListeners() has been called and a repaint will
    //       be scheduled by Provider. If the attempted move was
    //       invalid, there is no model-change and no repaint.
    return false;
  }

  // Handle the user's PointerDown actions on a 2D puzzle-area and controls.
  void _possibleHit2D(PointerEvent details)
  {
    hitPos = details.localPosition;
    PaintingSpecs2D paintingSpecs = puzzle.paintingSpecs2D;
    _possibleHit('2D', paintingSpecs.puzzleRect, paintingSpecs.controlRect);
  }

  // Handle the user's PointerDown actions on a 3D puzzle-area and controls.
  void _possibleHit3D(PointerEvent details)
  {
    hitPos = details.localPosition;
    PaintingSpecs3D paintingSpecs = puzzle.paintingSpecs3D;
    if (paintingSpecs.hit3DViewControl(hitPos)) {
      // If true, the 3D Puzzle View is to be rotated and re-painted,
      // but the Puzzle Model's contents are actually unchanged.
      puzzle.triggerRepaint();	// No Model change, but View must be repainted.
    }
    else if (_possibleHit('3D', paintingSpecs.puzzleRect,
                                paintingSpecs.controlRect)) {
      // Hit on 3D puzzle-area - special processing required.
      // Hit on controlRect is handled by _possibleHit() exactly as for 2D case.
      int n = paintingSpecs.whichSphere(hitPos);
      if (n >= 0) {
        puzzle.hitPuzzleCellN(n);
      }
      else {
        debugPrint('_possibleHit3D: NO SPHERE HIT');
      }
    }
    // NOTE: If the hit led to a valid change in the puzzle model,
    //       notifyListeners() has been called and a repaint will
    //       be scheduled by Provider. If the attempted move was
    //       invalid, there is no model-change and no repaint.
  }

} // End class PuzzleBoardView extends StatelessWidget
