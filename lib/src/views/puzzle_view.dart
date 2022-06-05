import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:community_material_icon/community_material_icon.dart';

import 'package:flutter/src/foundation/binding.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'messages.dart';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';

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
// Displays a Sudoku puzzle of a selected type and size. It may be 2D or 3D.

  const PuzzleView({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Set portrait/landscape, depending on the device or window-dimensions.
    Orientation orientation = MediaQuery.of(context).orientation;

    // Find the Puzzle object, which has been created by Provider.
    Puzzle puzzle = context.read<Puzzle>();

    // Save the orientation, for later use by PuzzlePainters and paint().
    // A setter in Puzzle saves "portrait" in either 2D or 3D PaintingSpecs.
    puzzle.portrait = (orientation == Orientation.portrait);

    // Create the list of action-icons.
    List<Widget> actionIcons = [
      IconButton(
        icon: const Icon(CommunityMaterialIcons.exit_run), // exit_to_app),
        tooltip: 'Return to list of puzzles',
        onPressed: () {
          exitScreen(context, puzzle);
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Settings',
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(Icons.save_outlined),
        tooltip: 'Save puzzle',
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(Icons.file_download),
        tooltip: 'Restore puzzle',
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.lightbulb_on_outline),
        tooltip: 'Get a hint',
        onPressed: () {
          puzzle.hint();
        },
      ),
      IconButton(
        icon: const Icon(Icons.undo_outlined),
        tooltip: 'Undo a move',
        onPressed: () {
          puzzle.undo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.redo_outlined),
        tooltip: 'Redo a move',
        onPressed: () {
          puzzle.redo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.devices_outlined),
        tooltip: 'Generate a new puzzle',
        onPressed: () {
          generatePuzzle(puzzle, context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.check_circle_outline_outlined),
        tooltip: 'Check that the puzzle you have entered is valid',
        onPressed: () async {
          checkPuzzle(puzzle, context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.restart_alt_outlined),
        tooltip: 'Start solving this puzzle again',
        onPressed: () {
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
        },
      ),
    ]; // End list of action icons

    if (orientation == Orientation.landscape) {
      // Landscape orientation.
      // Paint the puzzle with the action icons in a column on the left.
      return Scaffold(			// Omit AppBar, to maximize real-estate.
        body: Row(
          children: <Widget>[
            Ink(   // Give puzzle-background colour to column of IconButtons.
              color: Colors.amber.shade100,
              child: Column(
                // Contents of Column are vertically centred.
                mainAxisAlignment: MainAxisAlignment.center,
                children: actionIcons,
              ),
            ),
            Expanded(
              child: PuzzleBoardView(),
            ),
          ], // End Row children: [
        ), // End body: Row(
      ); // End return Scaffold(
    }
    else {
      // Portrait orientation.
      // Paint the puzzle with the action icons in a row at the top.
      return Scaffold(			// Omit AppBar, to maximize real-estate.
        body: Column(
          children: <Widget> [
            Ink( // Give puzzle-background colour to row of IconButtons.
              color: Colors.amber.shade100,
              child: Row(
                children: actionIcons,
              ),
            ),
            Expanded(
              child: PuzzleBoardView(),
            ),
          ],
        ), // End body: Column(
      ); // End return Scaffold(
    } // End if-then-else
  } // End Widget build

  // Procedures for icon actions and user messages.

  void generatePuzzle(Puzzle puzzle, BuildContext context)
  async
  {
    // Generate a puzzle of the requested level of difficulty.
    print('GENERATE Puzzle: Play status ${puzzle.puzzlePlay}');
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
    bool trying = true;
    while (trying) {
      Message m = puzzle.generatePuzzle();
      if (m.messageType == 'Q') {
        trying = await questionMessage(
                         context, 'Generate Puzzle', m.messageText,
                         okText: 'Try Again', cancelText: 'Accept');
        // If trying == true, keep looping to try for the required Difficulty.
      }
      else if (m.messageType != '') {
        // Inform the user about the puzzle that was generated, then return.
        await infoMessage(context, 'Generate Puzzle', m.messageText);
        break;
      }
    }
  }

  void checkPuzzle(Puzzle puzzle, BuildContext context)
  async
  {
    // Validate a puzzle that has been tapped in or loaded by the user.
    print('CHECK Puzzle: Play status ${puzzle.puzzlePlay}');
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
          cancelText: 'Continue'
        );
        if (finished) {
          // Convert the entered data into a Puzzle and re-display it.
          puzzle.convertDataToPuzzle();
          // TODO - Need to trigger a repaint here.
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
    if (okToQuit) {
      Navigator.pop(context);
    }
  }

  static const routeName = '/puzzle_view';

} // End class PuzzleView


class PuzzleBoardView extends StatelessWidget with ChangeNotifier
{
  Offset hitPos    = Offset(-1.0, -1.0);
  late Puzzle        puzzle;	// Located by Provider's watch<Puzzle> function.

  @override
  // This widget tree contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {

    // Locate the puzzle's model and repaint this widget tree when the model
    // changes and emits notifyListeners(). Changes can be due to user-moves
    // (taps) or actions on icon-buttons such as Undo/Redo, Generate and Hint.
    // In 3D puzzles, the repaint can be due to rotation, with no data change.

    puzzle = context.watch<Puzzle>();

    // Enable the issuing of messages to the user after major changes.
    WidgetsBinding.instance?.addPostFrameCallback((_)
                             {executeAfterBuild(context);});

    if (puzzle.puzzleMap.specificType == SudokuType.Roxdoku) {
      return Container(
        // We wish to fill the parent, in either Portrait or Landscape layout.
        height: (MediaQuery.of(context).size.height),
        width:  (MediaQuery.of(context).size.width),
        child:  Listener(
          onPointerDown: _possibleHit3D,
          child: CustomPaint(
            painter: PuzzlePainter3D(puzzle),
          ),
        ),
      );
    }
    else {
      return Container(
        // We wish to fill the parent, in either Portrait or Landscape layout.
        height: (MediaQuery.of(context).size.height),
        width:  (MediaQuery.of(context).size.width),
        child:  Listener(
          onPointerDown: _possibleHit2D,
          child: CustomPaint(
            painter: PuzzlePainter2D(puzzle),
          ),
        ),
      );
    }
  } // End Widget build()

  Future<void> executeAfterBuild(BuildContext context) async
  {
    // TODO - Not seeing the HasError message. Seems to happen when last move
    //        is an error, but seems OK if an earlier move is incorrect.

    if (puzzle.delayedMessage.messageType != '') {
      // We arrive here if the user selected a puzzle from the menu-screen or
      // asked for a retry, to get a more difficult puzzle (see below). The
      // delayed message is stored until after the puzzle area is repainted.
      Message m = puzzle.delayedMessage;
      bool retrying = false;
      if (m.messageType == 'Q') {
        retrying = await questionMessage(
                         context, 'Generate Puzzle', m.messageText,
                         okText: 'Try Again', cancelText: 'Accept');
      }
      else if (m.messageType != '') {
        // Inform the user about the puzzle that was generated, then return.
        await infoMessage(context, 'Generate Puzzle', m.messageText);
      }
      if (retrying) {
        // Keep re-generating and repainting to try for the required Difficulty.
        m = puzzle.generatePuzzle();
        puzzle.delayedMessage = m;
        notifyListeners();		// Trigger repaint of puzzle + message.
      }
      else {
        puzzle.delayedMessage = Message('', '');
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
      await infoMessage(context,
                        'CONGRATULATIONS!!!',
                        'You have solved the puzzle!!!\n\n'
                        'If you wish, you can use Undo and Redo to review'
                        ' your moves -'
                        ' or you could just try another puzzle...');
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
    // print ('_possibleHit$D at $hitPos');
    bool modelChanged = false;
    bool puzzleHit = puzzleRect.contains(hitPos);
    if (puzzleHit && (D == '2D')) {
      // Hit is on puzzle-area: get integer co-ordinates of cell.
      Offset point = hitPos - Offset(topLeftX, topLeftY);
      double cellSide = puzzleRect.width / puzzle.puzzleMap.sizeX;
      int x = (point.dx / cellSide).floor();
      int y = (point.dy / cellSide).floor();
      print('Hit is at puzzle-cell ($x, $y)');
      // If hitting this cell is a valid move, the Puzzle model will be updated.
      modelChanged = puzzle.hitPuzzleArea(x, y);
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
        Offset point = hitPos - Offset(topLeftXc, topLeftYc);
        int x = (point.dx / cellSide).floor();
        int y = (point.dy / cellSide).floor();
        print('Hit is at control-cell ($x, $y)');
        int selection = horizontal ? x : y;	// Get the selected control num.
        modelChanged = puzzle.hitControlArea(selection);
      }
      else {
        // Not a hit. Don't repaint.
        print('_possibleHit$D: NOT A HIT');
      }
    }
    print('MODEL CHANGED $modelChanged');
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
    bool modelChanged = false;
    if (paintingSpecs.hit3DViewControl(hitPos)) {
      // If true, the 3D Puzzle View is to be rotated and re-painted,
      // but the Puzzle Model's contents are actually unchanged.
      puzzle.triggerRepaint();	// No Model change, but View must be repainted.
      modelChanged = true;	// Force a repaint.
    }
    else if (_possibleHit('3D', paintingSpecs.puzzleRect,
                                paintingSpecs.controlRect)) {
      // Hit on 3D puzzle-area - special processing required.
      // Hit on controlRect is handled by _possibleHit() exactly as for 2D case.
      int n = paintingSpecs.whichSphere(hitPos);
      if (n >= 0) {
        modelChanged = puzzle.hitPuzzleCellN(n);
      }
      else {
        print('_possibleHit3D: NO SPHERE HIT');
      }
    }
    print('MODEL CHANGED $modelChanged');
    // NOTE: If the hit led to a valid change in the puzzle model,
    //       notifyListeners() has been called and a repaint will
    //       be scheduled by Provider. If the attempted move was
    //       invalid, there is no model-change and no repaint.
  }

} // End class PuzzleBoardView extends StatelessWidget
