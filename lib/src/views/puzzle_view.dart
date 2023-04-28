/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:community_material_icon/community_material_icon.dart';

import 'dart:async';
import 'messages.dart';

import '../settings/settings_controller.dart';
import '../settings/settings_view.dart';
import '../settings/game_theme.dart';

import '../globals.dart';
import '../models/puzzle.dart';
// import '../models/puzzle_generator.dart';
// import '../models/puzzle_player.dart';
import '../models/puzzle_map.dart';

import 'puzzle_board_view.dart';
import 'puzzle_control_bar.dart';
import 'timer_widget.dart';

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

  final bool isDarkMode;	// Display in dark theme-mode colours or light.
  final SettingsController settings;
  Puzzle puzzle;

  PuzzleView(this.puzzle, this.isDarkMode, {required this.settings, Key? key,}) : super(key: key);

  final bool timerVisible = true;	// TODO - Make this a Setting...

  bool tappedInPuzzle = false;		// Whether the user tapped in a Puzzle.

  late PuzzlePlayer puzzlePlayer;

  Size   screenSize    = Size(0.0, 0.0);
  double edgeFactor    = 0.025;
  double edgePadding   = 5.0;
  double boardSide     = 200.0;
  double controlSide   = 18.0;
  int    nSymbols      = 9;
  double iconSize      = 8.0;

  @override
  Widget build(BuildContext context) {
    // Receive the parameters of the selected puzzle-type via the Navigator.
    final List<int> parameters =
                      ModalRoute.of(context)!.settings.arguments as List<int>;
    final int puzzleIndex = parameters.last;
    final int playOrTapIn = parameters.first;

    debugPrint('Build PuzzleView: puzzleIndex = $puzzleIndex,'
               ' playOrTapIn $playOrTapIn.');

    // Find the Puzzle and PuzzlePlayer models, as set up by Providers.

    // TODO - Maybe this should be one or more selects on Puzzle. A full build
    //        of PuzzleBoardView is needed after generating a puzzle, but not
    //        after the board was filled with a correct or incorrect solution.
    puzzle              = context.watch<Puzzle>();
    puzzlePlayer        = context.read<PuzzlePlayer>();
    // GameTheme gameTheme = context.read<GameTheme>();
    GameTheme gameTheme = context.watch<GameTheme>();
                      // ?????? final value = context.watch<GameTheme>();

    debugPrint('PuzzleView: FOUND PUZZLE STATUS ${puzzlePlayer.puzzlePlay}.');
    debugPrint('PuzzleView: GameTheme.isDarkMode is ${gameTheme.isDarkMode}.');
    debugPrint('PuzzleView: THIS.isDarkMode is ${this.isDarkMode}.');

    // Set portrait/landscape, depending on the device or window-dimensions.
    Orientation orientation = MediaQuery.of(context).orientation;
    screenSize = MediaQuery.of(context).size;

    // If a new puzzle has been requested, create a puzzle and board, else just
    // do a repaint, but DO NOT clobber puzzle play by creating a new puzzle!

    if (puzzlePlayer.puzzlePlay == Play.NotStarted) {
      // Create a Puzzle and board where all the cells are empty or unusable.
      // Internally this initializes the Puzzle model and creates the PuzzleMap.

      puzzle.createState(puzzleIndex);

      // Generate a puzzle of the required type and difficulty.
      // Deliver the results to the PuzzlePlayer object.
      // TODO - Compute-bound, maybe a few seconds, usually < 1 sec. What to do?

      if (playOrTapIn == forPlay) {
        tappedInPuzzle = false;
        debugPrint('\nPuzzleView: GENERATE PUZZLE, index $puzzleIndex.');
        puzzle.generatePuzzle(settings.difficulty, settings.symmetry);
      }
      else if (playOrTapIn == forTapIn) {
        tappedInPuzzle = true;
        debugPrint('\nPuzzleView: TAP IN PUZZLE, index $puzzleIndex.');
        puzzlePlayer.initialise(puzzle.puzzleMap, puzzle);
      }
    }
    else {
      debugPrint('\nPuzzleView: REPAINT PUZZLE - DO NOT re-generate it.');
    }

    // The information for configuring the Puzzle Board View is now available.
    PuzzleMap map = puzzle.puzzleMap;

    // Save the orientation, for later use by PuzzlePainters and paint().
    // A setter in Puzzle saves "portrait" in either 2D or 3D PaintingSpecs.
    bool portrait = (orientation == Orientation.portrait);

    // Set up Puzzle's theme in dark/light mode and get the icon button colours.
    Color background = gameTheme.backgroundColor;
    Color foreground = gameTheme.boldLineColor;

    // Provide some layout hints for Flutter, including 3D layout if applicable.
    calculateLayoutHints(map, portrait);

    // TODO - Can we put Icon list away somewhere and access list.length above?

    // Create the list of timer widget and action-icons.
    List<Widget> actionIcons = [
      SizedBox(	// If the timer is invisible, shrink it and center the icons.
        width: timerVisible ? 4.0 * iconSize : 1,
        child: TimerWidget(
          visible:   timerVisible,
          textColor: foreground,
        ),
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.exit_run), // exit_to_app),
        iconSize: iconSize,
        tooltip: 'Return to list of puzzles',
        color:   foreground,
        onPressed: () {
          exitScreen(context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        iconSize: iconSize,
        // tooltip: 'Settings',
        tooltip: 'Temporarily out of action',
        color:   foreground,
        onPressed: () {
          // Navigate to the settings page.
          // debugPrint('PuzzleView: Go to Settings screen.');
          // Navigator.restorablePushNamed(
            // context, SettingsView.routeName);
        },
      ),
      IconButton(
        icon: const Icon(Icons.save_outlined),
        iconSize: iconSize,
        // tooltip: 'Save puzzle',
        tooltip: 'Not yet implemented',
        color:   foreground,
        onPressed: () {
        },
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.lightbulb_on_outline),
        iconSize: iconSize,
        tooltip: 'Get a hint',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.hint();
        },
      ),
      IconButton(
        icon: const Icon(Icons.undo_outlined),
        iconSize: iconSize,
        tooltip: 'Undo a move',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.undo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.redo_outlined),
        iconSize: iconSize,
        tooltip: 'Redo a move',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.redo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.devices_outlined),
        iconSize: iconSize,
        tooltip: 'Create a new puzzle',
        color:   foreground,
        onPressed: () {
          createPuzzle(context);
        },
      ),
    ]; // End list of action icons

    // Paint the puzzle with the action icons and timer in a row at the top.
    // In Portrait mode, put a horizontal control-bar under the puzzle board.
    // In Landscape mode. put it vertically to the right of the puzzle board.

    if (portrait) {		// Portrait mode.
      debugPrint('PuzzleView: Paint puzzle view, portrait mode.');
      return Scaffold(		// Omit AppBar, to maximize real-estate.
        // Give puzzle-background colour to whole screen, including icons.
        backgroundColor: background,
        body: Padding(
          padding: EdgeInsets.all(edgePadding),
            child: Column(
              children: <Widget> [
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: actionIcons,
                ),
              ),
              const Spacer(),
              PuzzleBoardView(puzzle, boardSide, settings: settings),
              Padding(padding: EdgeInsets.only(top: edgePadding * 5.0)),
              PuzzleControlBar(boardSide, map,
                               horizontal: true,
                               hideNotes: puzzlePlayer.hideNotes),
              const Spacer(),
            ],
          ), // End body: Column(
        ), // End Padding(
      ); // End return Scaffold(
    }
    else {			// Landscape mode.
      debugPrint('PuzzleView: Paint puzzle view, landscape mode.');
      return Scaffold(		// Omit AppBar, to maximize real-estate.
        // Give puzzle-background colour to whole screen, including icons.
        backgroundColor: background,
        body: Column(
          children: <Widget> [
            InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actionIcons,
              ),
            ),
            // ?????? Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                PuzzleBoardView(puzzle, boardSide, settings: settings),
                Padding(padding: EdgeInsets.only(left: edgePadding * 5.0)),
                PuzzleControlBar(boardSide, map,
                                 horizontal: false,
                                 hideNotes: puzzlePlayer.hideNotes),
              ],
            ), // End Row(.
            // ?????? Spacer(),
          ],
        ), // End body: Column(
      ); // End return Scaffold(
    }
  } // End Widget build

  void calculateLayoutHints(PuzzleMap map, bool portrait)
  {
    double longSide     = screenSize.longestSide;
    double shortSide    = screenSize.shortestSide;
    double edgePadding  = shortSide * edgeFactor;
    shortSide           = shortSide - 2.0 * edgePadding;
    longSide            = longSide  - 2.0 * edgePadding;
    double nIcons       = 10.0;
    iconSize            = 0.5  * shortSide / nIcons;
    // debugPrint('Layout long $longSide short $shortSide, '
          // 'nIcons $nIcons, iconSize $iconSize edgePadding $edgePadding');
    nSymbols            = map.nSymbols;

////////////////////////////////////////////////////////////////////////////////
// TODO - Calculations need fine-tuning, also the widget-trees (pads? spacers?).
////////////////////////////////////////////////////////////////////////////////

    if (portrait) {
      // Vertical layout: icons, board, empty space, control bar.
      boardSide = longSide - (2.0 * iconSize) - edgePadding - controlSide;
      if (boardSide > shortSide) {
        boardSide = shortSide;
      }
    }
    else {
      // Horizontal layout: icons at top, board, empty space, control bar below.
      boardSide = longSide - edgePadding - controlSide;
      // double testValue = shortSide - (2.0 * iconSize) - edgePadding;
      double testValue = shortSide - (1.0 * iconSize); // - edgePadding;
      // debugPrint('testValue $testValue boardSide $boardSide');
      if (boardSide > testValue) {
        boardSide = testValue;
      }
    }
    if (nSymbols <= 6) {
      boardSide = nSymbols * (boardSide / 6.0);
    }
    controlSide = boardSide / (nSymbols + 2.0);;
/*
    if (map.specificType == SudokuType.Roxdoku) {	// 3D Puzzle.
      // Calculate the dimensions of the puzzle's arrangement of spheres.
    }
*/
  }

  // PROCEDURES FOR ICON ACTIONS AND USER MESSAGES.

  void createPuzzle(context)
  async
  {
    // Generate a puzzle of the requested level of difficulty
    // OR check a tapped-in puzzle and maybe make it into a playable puzzle.

    debugPrint('CREATE Puzzle: Play status ${puzzlePlayer.puzzlePlay}');
    if (puzzlePlayer.puzzlePlay == Play.BeingEntered) {
      checkPuzzle(context);
      return;
    }

    bool newPuzzleOK = (puzzlePlayer.puzzlePlay == Play.NotStarted) ||
                       (! tappedInPuzzle && (puzzlePlayer.puzzlePlay
                                                == Play.ReadyToStart)) ||
                       (puzzlePlayer.puzzlePlay == Play.Solved);
    if (! newPuzzleOK) {
      newPuzzleOK = await questionMessage(
        context,
        'Start a new puzzle?',
        'You could lose your work so far. Do you '
        ' really want to start a new puzzle?',
      );
    }
    debugPrint('PuzzleView: New puzzle OK $newPuzzleOK,'
               ' play status ${puzzlePlayer.puzzlePlay}.');
    if (newPuzzleOK) {
      // Erase the time-display and stop the clock, if it is running.
      debugPrint('CLEAR Clock.');
      puzzle.clearClock();
      Difficulty difficulty = settings.difficulty;
      Symmetry   symmetry   = settings.symmetry;
      puzzle.generatePuzzle(difficulty, symmetry);
    }
  }

  void checkPuzzle(BuildContext context)
  async
  {
    // Validate a puzzle that has been tapped in or loaded by the user.
    debugPrint('CHECK Puzzle: Play status ${puzzlePlayer.puzzlePlay}');
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
          cancelText: 'Continue Working',
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
        // Checking a puzzle retrieved from a file NOT IMPLEMENTED YET.
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

  void exitScreen(BuildContext context)
  async
  {
    // Quit the PuzzleView screen, maybe leaving a puzzle unfinished.
    bool okToQuit = (puzzlePlayer.puzzlePlay == Play.NotStarted) ||
                    (puzzlePlayer.puzzlePlay == Play.ReadyToStart) ||
                    (puzzlePlayer.puzzlePlay == Play.Solved);
    if (! okToQuit) {
      okToQuit = await questionMessage(
                 context,
                 'Quit?',
                 'You could lose your work so far. Do you really want to quit?',
                 );
    }
    if (okToQuit && context.mounted) {
      debugPrint('PuzzleView: RETURN TO LIST OF PUZZLES - exitScreen();');
      puzzlePlayer.resetPlayStatus();	// Needed in next build of PuzzleView.
      Navigator.pop(context);
    }
  }

  static const routeName = '/puzzle_view';

} // End class PuzzleView
