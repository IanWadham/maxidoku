import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:community_material_icon/community_material_icon.dart';

import 'dart:async';
import 'messages.dart';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';

import 'timer_widget.dart';
import 'puzzle_board_view.dart';

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

  /* const */ PuzzleView(this.darkMode, {Key? key,}) : super(key: key);

  final bool timerVisible = false;

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
    // TODO: Work out required width of timer: visible or not visible.
    //       Allow for padding, etc. Allow space for 99:59:59... ? Maybe
    //       give the clock a pseudo-fixed font, based on puzzle digit sizes?
    //       At least we must center the timer in a SizedBox, so that the
    //       whole row of icons does not dart about as the text-width changes.

    // List<IconButton> actionIcons = [
    List<Widget> actionIcons = [
      SizedBox(
        width: 3.0 * iconSize,
        child: TimerWidget(
          visible:  timerVisible,
        ),
      ),
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

    // Paint the puzzle with the action icons and timer in a row at the top.
    return Scaffold(		// Omit AppBar, to maximize real-estate.
      // Give puzzle-background colour to whole screen, including icon buttons.
      backgroundColor: background,
      body: Column(
        children: <Widget> [
          InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actionIcons, // [TimerWidget(), actionIcons,]
            ),
          ),
          // TODO - Temporary. Lay out PuzzleBoardView (empty square), Control
          //                   Bar and spacing, taking account of Portrait and
          //                   Landscape modes.
          const Spacer(),
          PuzzleBoardView(),
          const Spacer(),
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
