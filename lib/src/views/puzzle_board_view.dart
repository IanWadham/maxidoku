import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:community_material_icon/community_material_icon.dart';

import 'dart:async';
import 'messages.dart';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import '../models/puzzle_3d.dart';
import 'round_cell_view.dart';

// TO BE TESTED --- import 'board_view.dart';

import 'board_view.dart';
import 'board_grid_view.dart';

class PuzzleBoardView extends StatelessWidget
{
  PuzzleBoardView(/* {super.key}, */ this.boardSide);

  // TODO - StatelessWidget is an immutable class, but puzzle and hitPos cannot
  //        be "final" and so the PuzzleBoardView constructor cannot be "const".
  //        What to do?

  final double boardSide;

  Offset hitPos    = const Offset(-1.0, -1.0);

  // Located by Provider's watch<>() or read<>() function.
  late Puzzle          puzzle;
  late PuzzlePlayer    puzzlePlayer;

  @override
  // This widget tree contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {

    // Locate the puzzle's models and repaint this widget tree when a model
    // changes and emits notifyListeners(). Changes can be due to user-moves
    // (taps) or actions on icon-buttons such as Undo/Redo, Generate and Hint.
    // In 3D puzzles, the repaint can be due to rotation, with no data change.

    puzzle          = context.watch<Puzzle>();
    puzzlePlayer    = puzzle.puzzlePlayer;

    PuzzleMap map   = puzzle.puzzleMap;

    // Set painting requirements for UNUSABLE, VACANT and SPECIAL cells.
    List<int> cellBackground = [...map.emptyBoard];
    for (int index in map.specialCells) {
      cellBackground[index] = SPECIAL;	// Used in XSudoku and 3D puzzles.
    }

    Rect boardSpace = const Offset(0.0, 0.0) & Size(boardSide, boardSide);
    debugPrint('Context size ${MediaQuery.of(context).size} board space $boardSpace');

    // Enable messages to the user after major changes of puzzle-status.
    WidgetsBinding.instance.addPostFrameCallback((_)
                            {executeAfterBuild(context);});

    // Find out if the System (O/S) or Flutter colour Theme is dark or light.
    bool isDarkMode = (Theme.of(context).brightness == Brightness.dark);

    if (puzzle.puzzleMap.specificType == SudokuType.Roxdoku) {	// 3D Puzzle.
      Puzzle3D puzzle3D = Puzzle3D(map);
      puzzle3D.calculate3dLayout();

      List<Positioned> roundCellViews = [];
      List<RoundCell> roundCells = puzzle3D.calculateProjection(boardSpace);
      for (RoundCell c in roundCells) {
        if (c.used) {
// Cells 6. 13 and 20 are at the bottom, centre and top of the view.
// if ((c.id == 6) || (c.id == 13) || (c.id == 20)) {
          Rect r = Rect.fromCenter(
                     center: boardSpace.center + c.centre,
                     width:  c.diameter,
                     height: c.diameter);
          // debugPrint('ID ${c.id} Centre ${c.centre} diameter ${c.diameter} $r');
          roundCellViews.add(
            Positioned.fromRect(
              rect:  r,
              child: RoundCellView(c.id),
            )
          );
// }
        }
      }
      // We wish to fill the parent, in either Portrait or Landscape layout.
      debugPrint('Board Side $boardSide;');
      // return LayoutBuilder(
        // builder: (BuildContext context, BoxConstraints constraints) {
          // print('Board Constraints $constraints');
          // return Stack(
      return SizedBox(
        width: boardSide,
        height: boardSide,
        child: Stack(
          children: roundCellViews,
        ),
      );
    }
    else {		// 2D Sudoku variant, Killer Sudoku or Mathdoku puzzle.
      int    n = puzzle.puzzleMap.sizeY;
      double fontHeight = 0.6 * (boardSide / n);
      return SizedBox(
        width: boardSide,
        height: boardSide,
        child: Stack(
          children: [
            BoardView2D(map, cellBackground, fontHeight),
            BoardGridView2D(
              boardSide,
              puzzleMap: map),
          ],
        ),
      );
/* ***************************
      return SizedBox(
        // We wish to fill the parent, in either Portrait or Landscape layout.
        height: (MediaQuery.of(context).size.height),
        width:  (MediaQuery.of(context).size.width),
        child:  BoardView2D(puzzleMap: puzzle.puzzleMap),
 ***************************
        child:  Listener(
          onPointerDown: _possibleHit2D,
          child: CustomPaint(
            painter: PuzzlePainter2D(puzzle, isDarkMode),
          ),
        ),
      );
   ************************** */
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
        // TODO - DISABLED...   puzzle.puzzlePlayer._puzzleTimer.startClock();
      }
      return;
    }

    // Check to see if there was any major change during the last repaint of
    // the Puzzle. If so, issue appropriate messages. Flutter does not allow
    // them to be issued or automatically queued during a repaint.
    Play playNow = puzzlePlayer.puzzlePlay;
    if (puzzlePlayer.isPlayUnchanged()) {
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
      // puzzle.stopClock();	// REDUNDANT???? Hasn't Puzzle already done it.
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
      puzzlePlayer.hitPuzzleArea(x, y);
    }
    else if (puzzleHit && (D == '3D')) {
      return true;		// Do the rest using 3D functions.
    }
    else {
      if (controlRect.contains(hitPos)) {
        // Hit is on control-area: get current number of controls.
        // Use the same control-area actions for both 2D and 3D puzzles.
        int nSymbols = puzzle.puzzleMap.nSymbols;
        int nCells = (puzzlePlayer.puzzlePlay == Play.NotStarted) ||
                     (puzzlePlayer.puzzlePlay == Play.BeingEntered) ?
                     nSymbols + 1 : nSymbols + 2;
        bool horizontal = controlRect.width > controlRect.height;
        double cellSide = horizontal ? controlRect.width / nCells
                                     : controlRect.height / nCells;
        Offset point = hitPos - controlRect.topLeft;
        int x = (point.dx / cellSide).floor();
        int y = (point.dy / cellSide).floor();
        int selection = horizontal ? x : y;	// Get the selected control num.
        puzzlePlayer.hitControlArea(selection);
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

/* OBSOLETE
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
*/

} // End class PuzzleBoardView extends StatelessWidget
