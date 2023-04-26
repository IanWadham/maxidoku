import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:community_material_icon/community_material_icon.dart';

import 'dart:async';
import 'messages.dart';

import '../settings/settings_controller.dart';
// import '../settings/settings_view.dart';
import '../settings/game_theme.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import '../layouts/board_layout_3d.dart';
// import 'round_cell_view.dart';
import 'symbol_view.dart';

import 'board_view.dart';
import 'board_grid_view.dart';

class PuzzleBoardView extends StatelessWidget
{
  PuzzleBoardView(this.puzzle, this.boardSide,
                  {Key? key, required this.settings})
    : super(key: key);

  // TODO - StatelessWidget is an immutable class, but puzzle and hitPos cannot
  //        be "final" and so the PuzzleBoardView constructor cannot be "const".
  //        What to do?

  final double boardSide;
  final SettingsController settings;
  final Puzzle puzzle;

  Offset hitPos    = const Offset(-1.0, -1.0);

  // Located by Provider's read<>() function.
  late PuzzlePlayer puzzlePlayer;

  @override
  // This widget tree contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {

    // Locate the puzzle's models and repaint this widget tree when a model
    // changes and emits notifyListeners(). Changes can be due to user-moves
    // (taps) or actions on icon-buttons such as Undo/Redo, Generate and Hint.
    // In 3D puzzles, the repaint can be due to rotation, with no data change.

    puzzlePlayer        = context.read<PuzzlePlayer>();
    GameTheme gameTheme = context.watch<GameTheme>();

    Color foreground    = gameTheme.boldLineColor;

    PuzzleMap map = puzzle.puzzleMap;

    Rect boardSpace = const Offset(0.0, 0.0) & Size(boardSide, boardSide);
    // debugPrint('PuzzleBoardView: Context size ${MediaQuery.of(context).size}'
               // ' board space $boardSpace');

    // Find out if the System (O/S) or Flutter colour Theme is dark or light.
    bool isDarkMode = (Theme.of(context).brightness == Brightness.dark);

    // Enable messages to the user after major changes of puzzle-status.
    WidgetsBinding.instance.addPostFrameCallback((_)
                            {executeAfterBuild(context);});

    // TODO - Re-activate debugPrints and check where repaints are occurring.

    // Fill the board area with a 3D Roxdoku Puzzle (in simulated 3D).
    if (map.specificType == SudokuType.Roxdoku) {
    // TODO - Tune the layouts of 3D puzzles, especially the rotation buttons.
    //        Allow the board area to be rectangular if required. BoardLayout3D
    //        is probably where the underlying problems are.
    // TODO - If green (special) circles are GIVENs, put a darker green
    //        on the outside, not a darker amber.
      List<Positioned> roundCellViews = [];
      List<RoundCell> roundCells = puzzle.roundCells3D;
      for (RoundCell c in roundCells) {
        if (c.used) {
          double viewDiameter = c.diameter * boardSide;
          Rect r = Rect.fromCenter(
                     center: boardSpace.center + c.centre * boardSide,
                     width:  viewDiameter,
                     height: viewDiameter);
          roundCellViews.add(
            Positioned.fromRect(
              rect:  r,
              child: SymbolView('3D', map, c.index, viewDiameter),
            )
          );
        }
      }

      // Add rotation buttons (left, right, upward, downward) to the view.
      double size = 30.0;
      for (int n = 0; n < 4; n++) {
        roundCellViews.add(rotationButton(n, boardSpace, size, foreground));
      }

      // We wish to fill the parent, in either Portrait or Landscape layout.
      debugPrint('PuzzleBoardView: Paint 3D Puzzle, boardSide $boardSide.');
      return SizedBox(
        width:  boardSide,
        height: boardSide,
        child:  Stack(
          children: roundCellViews,
        ),
      );
    }

   // Fill the board area with a 2D Sudoku variant, Killer Sudoku or Mathdoku.
    else {
      int    n = puzzle.puzzleMap.sizeY;
      double cellSide = boardSide / n;
      debugPrint('PuzzleBoardView: Paint 2D Puzzle, boardSide $boardSide;');
      return SizedBox(
        width: boardSide,
        height: boardSide,
        child: Stack(
          children: [
            // TODO - Merge BoardView2D code into BoardGridView2D. Colour cellBG
            //        into grid before building (transparent) CellView
            //        (SymbolViews-to-be). Would need to move the Stack( and
            //        children: lines in there too.
            BoardGridView2D(
              boardSide,
              puzzleMap: map),
            BoardView2D(map, cellSide),
            // TODO - Disconnect the Cage painter from this. So that it can be
            //        instantiated and painted only ONCE per caged puzzle, using
            //        RepaintBoundary and deleted and re-created whenever there
            //        is a new caged puzzle. The function shared by the grid and
            //        cage calculations might become a "helper" function.
          ],
        ),
      );
    }
  } // End Widget build()

  Positioned rotationButton(int buttonID, Rect boardSpace, double buttonSize,
                            Color foreground)
  {
    Icon   icon;
    String tooltip;
    Offset center;

    if (buttonID == 0) {
      icon    = const Icon(Icons.arrow_circle_left);
      tooltip = 'Rotate Left';
      center  = boardSpace.centerLeft + Offset(buttonSize, 0.0);
    }
    else if (buttonID == 1) {
        icon    = const Icon(Icons.arrow_circle_right);
        tooltip = 'Rotate Right';
        center  = boardSpace.centerRight + Offset(-buttonSize, 0.0);
    }
    else if (buttonID == 2) {
        icon    = const Icon(Icons.arrow_circle_up);
        tooltip = 'Rotate Upward';
        center  = boardSpace.topCenter + Offset(0.0, buttonSize);
    }
    else if (buttonID == 3) {
        icon    = const Icon(Icons.arrow_circle_down);
        tooltip = 'Rotate Downward';
        center  = boardSpace.bottomCenter + Offset(0.0, -buttonSize);
    }
    else {
        icon    = const Icon(Icons.arrow_circle_down);
        tooltip = 'Rotate Downward';
        center  = boardSpace.bottomCenter + Offset(0.0, -buttonSize);
    }

    Rect r = Rect.fromCenter(
               center: center,
               width:  buttonSize * 2,
               height: buttonSize * 2,
             );
    return Positioned.fromRect(		// A Positioned IconButton.
             rect:  r,
             child: IconButton(
               icon: icon,
               iconSize: buttonSize,
               tooltip: tooltip,
               color: foreground,
               onPressed: () {
                 print('Button ID: $buttonID');
                 puzzle.rotateLayout3D(buttonID);
               }
             ),
           );
  }

  Future<void> executeAfterBuild(BuildContext context) async
  {
    debugPrint('PuzzleBoardView: ENTERED executeAfterBuild...\n');
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
          // TODO - After 200 tries, Mathdoku/Killer returns type F because
          //        the Puzzle board is still empty. This can easily happen.
          //        Just choose a small board-size and a high Difficulty.
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
        puzzle.generatePuzzle(settings.difficulty, settings.symmetry);
      }
      else {
        // A puzzle was selected, generated and accepted, so start the clock!
        debugPrint('START Clock.');
        puzzle.startClock();
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
      await infoMessage(context,
                        'WELL DONE!!!',
                        'You have reached the end of the puzzle!'
                        ' Congratulations!!!');
    }
    else if (playNow == Play.HasError) {
      await infoMessage(context,
                        'Incorrect Solution',
                        'Your solution contains one or more errors.'
                        ' Please correct it and try again.');
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

} // End class PuzzleBoardView extends StatelessWidget
