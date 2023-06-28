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
// if a screen repaint occurs. Some messages originate from actions within the
// puzzle model. These are deferred and later handled by a postFrameCallback()
// procedure in the PuzzleBoardView's Widget build(). PuzzleBoardView is a
// sub-Widget of the PuzzleView Widget.

  final bool isDarkMode;	// Display in dark theme-mode colours or light.
  final SettingsController settings;
  Puzzle puzzle;

  PuzzleView(this.puzzle, this.isDarkMode,
    {required this.settings, Key? key,}) : super(key: key);

  final bool timerVisible = true;	// TODO - Make this a Setting...

  late PuzzlePlayer puzzlePlayer;
  late GameTheme    gameTheme;

  final double iconSize      = 30.0;
  final double iconPad       = 8.0;	// IconButton default all-round padding.

  @override
  Widget build(BuildContext context) {
    // Receive the parameters of the selected puzzle-type via the Navigator.
    final List<int> parameters =
                      ModalRoute.of(context)!.settings.arguments as List<int>;
    final int puzzleIndex = parameters.last;
    final int playOrTapIn = parameters.first;

    // Is the user tapping in a Puzzle from the "Tap In A Puzzle" menu?
    final bool isTappedInPuzzle = (playOrTapIn == forTapIn);

    debugPrint('Build PuzzleView: puzzleIndex = $puzzleIndex,'
               ' playOrTapIn $playOrTapIn.');

    // Find the Puzzle and PuzzlePlayer models, as set up by Providers.

    // TODO - Maybe this should be one or more selects on Puzzle. A full build
    //        of PuzzleBoardView is needed after generating a puzzle, but not
    //        after the board was filled with a correct or incorrect solution.
    puzzle              = context.watch<Puzzle>();
    puzzlePlayer        = context.read<PuzzlePlayer>();
    gameTheme           = context.read<GameTheme>();
    // ?????? gameTheme           = context.watch<GameTheme>();

    debugPrint('PuzzleView: FOUND PUZZLE STATUS ${puzzlePlayer.puzzlePlay}.');
    debugPrint('PuzzleView: GameTheme.isDarkMode is ${gameTheme.isDarkMode}.');
    debugPrint('PuzzleView: THIS.isDarkMode is ${this.isDarkMode}.');

    // Set portrait/landscape, depending on the device or window-dimensions.
    Orientation orientation = MediaQuery.of(context).orientation;

    // Get the available screen/window/webpage size - in logical pixels.
    Size        screenSize  = MediaQuery.of(context).size;

    // If a new puzzle has been requested, create a puzzle and board, else just
    // do a repaint, but DO NOT clobber puzzle play by creating a new puzzle!

    if ((puzzle.nPuzzlesGenerated == 0) &&
        (puzzlePlayer.puzzlePlay == Play.NotStarted)) {
      // Create a Puzzle and board where all the cells are empty or unusable.
      // Internally this initializes the Puzzle model and creates the PuzzleMap.

      puzzle.createState(puzzleIndex);

      if (playOrTapIn == forPlay) {
        // Generate a puzzle of the required type and difficulty.
        // Deliver the results to the PuzzlePlayer object. The Puzzle is
        // generated async, in an Isolate, using Flutter compute().
        debugPrint('\n==== PuzzleView: GENERATE PUZZLE FROM WIDGET BUILD: '
                   'index $puzzleIndex.');
        puzzle.generatePuzzle(settings.difficulty, settings.symmetry);
      }
      else if (playOrTapIn == forTapIn) {
        debugPrint('\n==== PuzzleView: TAP IN PUZZLE, index $puzzleIndex.');
        puzzlePlayer.initialise(puzzle.puzzleMap, puzzle);
      }
    }
    else {
      debugPrint('\n==== PuzzleView: REPAINT PUZZLE - DO NOT re-generate it.');
    }

    // The information for configuring the Puzzle Board View is now available.
    PuzzleMap map = puzzle.puzzleMap;
    debugPrint('PuzzleView: Ready to paint the Puzzle board...');

    // Save the orientation.
    bool portrait = (orientation == Orientation.portrait);

    // Set up Puzzle's theme in dark/light mode and get the icon button colours.
    Color background = gameTheme.backgroundColor;
    Color foreground = gameTheme.boldLineColor;

    // Provide some layout hints for Flutter, including 3D layout if applicable.
    List<double> layoutHints = calculateLayoutHints(
                                 map, portrait, screenSize, isTappedInPuzzle
                               );
    double boardSide       = layoutHints[0];
    double edgePadding     = layoutHints[1];
    double controlsPadding = layoutHints[2];
    double controlSide     = layoutHints[3];

    EdgeInsetsGeometry iconPadding = EdgeInsets.all(iconPad);
    debugPrint('ICON SIZE $iconSize, ICON PAD $iconPad.');

    // TODO - Can we put Icon list away somewhere and access list.length above?

    // Create the list of timer widget and action-icons.
    List<Widget> actionIcons = [
      SizedBox(	// If the timer is invisible, shrink it and center the icons.
        width: timerVisible ? 2.0 * iconSize : 1,
        child: TimerWidget(
          visible:   timerVisible,
          textColor: foreground,
        ),
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.exit_run), // exit_to_app),
        iconSize: iconSize,
        padding:  iconPadding,
        tooltip: 'Return to list of puzzles',
        color:   foreground,
        onPressed: () {
          exitScreen(context);
        },
      ),
      IconButton(
        icon: const Icon(Icons.save_outlined),
        iconSize: iconSize,
        padding:  iconPadding,
        // tooltip: 'Save puzzle',
        tooltip: 'Not yet implemented',
        color:   foreground,
        onPressed: () {
        },
      ),
      IconButton(
        icon: const Icon(CommunityMaterialIcons.lightbulb_on_outline),
        iconSize: iconSize,
        padding:  iconPadding,
        tooltip: 'Get a hint',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.hint();
        },
      ),
      IconButton(
        icon: const Icon(Icons.undo_outlined),
        iconSize: iconSize,
        padding:  iconPadding,
        tooltip: 'Undo a move',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.undo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.redo_outlined),
        iconSize: iconSize,
        padding:  iconPadding,
        tooltip: 'Redo a move',
        color:   foreground,
        onPressed: () {
          puzzlePlayer.redo();
        },
      ),
      IconButton(
        icon: const Icon(Icons.devices_outlined),
        iconSize: iconSize,
        padding:  iconPadding,
        tooltip: 'Create a new puzzle',
        color:   foreground,
        onPressed: () {
          createPuzzle(context, isTappedInPuzzle);
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
              Padding(padding: EdgeInsets.only(top: controlsPadding)),
              PuzzleControlBar(boardSide, controlSide, map,
                               horizontal: true,
                               hideNotes: puzzlePlayer.hideNotes),
              const Spacer(),
            ],
          ), // End Column
        ), // End body: Padding
      ); // End return Scaffold
    }
    else {			// Landscape mode.
      debugPrint('PuzzleView: Paint puzzle view, landscape mode.');
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
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget> [
                PuzzleBoardView(puzzle, boardSide, settings: settings),
                Padding(padding: EdgeInsets.only(left: controlsPadding)),
                PuzzleControlBar(boardSide, controlSide, map,
                                 horizontal: false,
                                 hideNotes: puzzlePlayer.hideNotes),
              ],
            ), // End Row
            Spacer(),
          ],
        ), // End Column
        ), // End body: Padding
      ); // End return Scaffold
    }
  } // End Widget build


  List<double> calculateLayoutHints(
                 PuzzleMap map, bool portrait,
                 Size screenSize, bool isTappedInPuzzle)
  {
    double edgeFactor        = 0.025;
    List<double> layoutHints = [];

    double longSide     = screenSize.longestSide;
    double shortSide    = screenSize.shortestSide;
    double aspectRatio  = longSide/shortSide;
    double edgePadding  = shortSide * edgeFactor;
    double iconHitArea  = iconSize + 2.0 * iconPad;

    int nSymbols        = map.nSymbols;
    int nControls       = isTappedInPuzzle ? nSymbols + 1 : nSymbols + 2;

    debugPrint('Layout long $longSide short $shortSide, '
          'iconSize $iconSize edgePadding $edgePadding');

    iconHitArea         = iconHitArea > 40.0 ? iconHitArea : 40.0;
    edgePadding         = (edgePadding > 8.0) ? 8.0 : edgePadding;

    double controlsPadding = 5.0 * edgePadding;
    double boardSide       = 0.0;
    double controlSide     = 0.0;

    shortSide              = shortSide - 2.0 * edgePadding;
    longSide               = longSide  - 2.0 * edgePadding;

    if (portrait) {
      // Vertical layout: icons, board, empty space, control bar.
      controlSide = shortSide / nControls;

      // Get the vertical space available for the board area.
      boardSide   = longSide - iconHitArea - controlsPadding - controlSide;
    }
    else {
      // Horizontal layout: icons at top, board, empty space, control bar below.
      shortSide   = shortSide - iconHitArea - 4.0; // Safety factor.
      controlSide = shortSide / nControls;

      // Get the horizontal space available for the board area.
      boardSide = longSide - controlsPadding - controlSide;
      // debugPrint('Short side $shortSide boardSide $boardSide');
    }
    // If OK, board area fills available screen space, otherwise something less.
    if (boardSide > shortSide) {
      boardSide = shortSide;
    }

    // Choose smaller symbols and/or cells if there are < 6 of them.
    // NOTE: Tiny Samurai needs a full 10x10 board, but only 4 symbols.
    if (nSymbols < 6) {
      // controlSide = boardSide / (6.0 + nControls - nSymbols);
      controlSide = nSymbols * (boardSide / 6.0) / nControls;
    }
    if ((map.sizeY < 6) && (map.sizeZ == 1)) {	// 2D board, < 6x6 size..
      boardSide = map.sizeY * (boardSide / 6.0);
    }

    // Return nControls, controlSide, boardSide, controlsPadding.
    layoutHints = [boardSide, edgePadding, controlsPadding, controlSide];
    return layoutHints;
  }

  // PROCEDURES FOR ICON ACTIONS AND USER MESSAGES.

  void createPuzzle(context, bool isTappedInPuzzle)
  async
  {
    // Generate a puzzle of the requested level of difficulty
    // OR check a tapped-in puzzle and maybe make it into a playable puzzle.

    debugPrint('==== CREATE Puzzle: Play status ${puzzlePlayer.puzzlePlay}');
    if (puzzlePlayer.puzzlePlay == Play.BeingEntered) {
      checkPuzzle(context);
      return;
    }

    bool newPuzzleOK = (puzzlePlayer.puzzlePlay == Play.NotStarted) ||
                       (! isTappedInPuzzle && (puzzlePlayer.puzzlePlay
                                                == Play.ReadyToStart)) ||
                       (puzzlePlayer.puzzlePlay == Play.Solved);
    if (! newPuzzleOK) {
      newPuzzleOK = await questionMessage(
        context,
        'Start a new puzzle?',
        'You could lose your work so far. Do you '
        ' really want to start a new puzzle?',
        gameTheme: gameTheme,
      );
    }
    debugPrint('PuzzleView: New puzzle OK $newPuzzleOK,'
               ' play status ${puzzlePlayer.puzzlePlay}.');
    if (newPuzzleOK) {
      // Erase the time-display and stop the clock, if it is running.
      debugPrint('CLEAR Clock.');
      puzzle.clearClock();
      // TODO - REACTIVATE this? Makes any difference? ???????????????????
      // ??????? puzzleMap.clearCages();	// ????? Force cages to vanish.
      debugPrint('==== GENERATE Puzzle FROM BUTTON: '
                 'status ${puzzlePlayer.puzzlePlay}');
      puzzle.generatePuzzle(settings.difficulty, settings.symmetry);
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
          yesText: 'Finish Up',
          noText:  'Continue Working',
          gameTheme: gameTheme,
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
          ' again.',
          gameTheme: gameTheme,
        );
        return;
      case -2:
        // Checking a puzzle retrieved from a file NOT IMPLEMENTED YET.
        await infoMessage(
          context,
          '',
          '',
          gameTheme: gameTheme,
        );
        return;
      case -3:
        await infoMessage(
          context,
          'Solution Is Not Unique',
          'Your puzzle has more than one solution. Please check that you'
          ' entered all the data correctly and with no omissions, then edit it'
          ' and try again - maybe add some clues to narrow the possibilities.',
          gameTheme: gameTheme,
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
                 gameTheme: gameTheme,
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
