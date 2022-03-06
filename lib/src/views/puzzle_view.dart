import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/src/foundation/binding.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import '../models/puzzle_types.dart';
import 'painting_specs_2d.dart';
import 'messages.dart';

/* ************************************************************************** **
   ICON BUTTONS - Mark and go back to Mark???

   Set symmetry, set difficulty in Settings. Message to user about this???
** ************************************************************************** */

/* ************************************************************************** **
  // Can get device/OS/platform at https://pub.dev/packages/device_info_plus
  // See also the "Dependencies" list in the column at RHS of that page re
  // info on MacOS, Linux, Windows, etc.
** ************************************************************************** */

/// Displays a Sudoku puzzle of a selected type and size.
class PuzzleView extends StatelessWidget
{
  final int       index;	// Position in puzzle-specifications list.

  const PuzzleView(this.index, {Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Find the Puzzle object, which has been created empty by Provider.
    Puzzle puzzle = context.read<Puzzle>();

    // Create a Puzzle state for the type of puzzle selected by the user.
    // This sets up a puzzle-area of the required size and shape, which is left
    // empty (0n the screen) until the user taps in a puzzle or generates one.

    puzzle.createState(index);

    // TODO - Could make PaintingSpecs a COMPONENT of Puzzle, not a reference.

    // Precalculate and save the operations for paint(Canvas canvas, Size size).
    // These are held in unit form and scaled up when the canvas-size is known.

    PaintingSpecs paintingSpecs = PaintingSpecs(puzzle.puzzleMap);

    puzzle.paintingSpecs = paintingSpecs;	// Save the reference.
    paintingSpecs.calculatePainting();

    // Set vertical/horizontal, depending on the device or window-dimensions.
    paintingSpecs.portrait =
            (MediaQuery.of(context).orientation == Orientation.portrait);

    // Create the list of action-icons.
    List<Widget> actionIcons = [
      IconButton(
        icon: const Icon(CommunityMaterialIcons.exit_run), // exit_to_app),
        tooltip: 'Return to list of puzzles',
        onPressed: () {
          exitScreen(context);
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
          // Navigate to the settings page.
          Navigator.restorablePushNamed(
            context, SettingsView.routeName);
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

    if (! paintingSpecs.portrait) {
      // Landscape orientation.
      // Paint the puzzle with the action icons in a column on the RHS.
      return Scaffold(			// Omit AppBar, to maximize real-estate.
        body: Row(
          children: <Widget>[
            Expanded(
              child: _PuzzleView(),
            ),
            Ink(   // Give puzzle-background colour to column of IconButtons.
              color: Colors.amber.shade100,
              // DEBUGGING width: 200.0,
              child: Column(
                children: actionIcons,
              ),
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
              child: _PuzzleView(),
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
                         context, 'Generate Puzzle', m.messageText);
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

  void exitScreen(BuildContext context)
  async
  {
    // Quit the Puzzle screen, maybe leaving a puzzle unfinished.
    bool okToQuit = await questionMessage(
      context,
      'Quit?',
      'You could lose your work so far. Do you really want to quit?',
    );
    if (okToQuit) {
      Navigator.pop(context);
    }
  }

  static const routeName = '/puzzle_view';

} // End class PuzzleView


class _PuzzleView extends StatelessWidget
{
  Offset hitPos    = Offset(-1.0, -1.0);
  late Puzzle        puzzle;	// Located by Provider's watch<Puzzle> function.

  @override
  // This widget tree contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {

    // Locate the puzzle's model and repaint this widget tree when the model
    // changes and emits notifyListeners(). Changes can be due to user-moves
    // (taps) or actions on icon-buttons such as Undo/Redo, Generate and Hint.

    puzzle = context.watch<Puzzle>();

    // Enable the issuing of messages to the userafter major changes.
    WidgetsBinding.instance?.addPostFrameCallback((_)
                             {executeAfterBuild(context);});

    return Container(
      // We wish to fill the parent, in either Portrait or Landscape layout.
      height: (MediaQuery.of(context).size.height),
      width:  (MediaQuery.of(context).size.width),
      child:  Listener(
        onPointerDown: _possibleHit,
        child: CustomPaint(
          painter: PuzzlePainter(puzzle),
        ),
      ),
    );
  } // End Widget build()

  Future<void> executeAfterBuild(BuildContext context) async
  {
    // TODO - Not seeing the HasError message. Seems to happen when last move
    //        is an error, but seems OK if an earlier move is incorrect.

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
  void _possibleHit(PointerEvent details)
  {
    hitPos = details.localPosition;
    print ('_possibleHit at $hitPos');
    PaintingSpecs paintingSpecs = puzzle.paintingSpecs;
    Rect r = paintingSpecs.puzzleRect;
    bool modelChanged = false;
    bool puzzleHit = r.contains(hitPos);
    if (puzzleHit) {
      // Hit is on puzzle-area: get integer co-ordinates of cell.
      Offset point = hitPos - Offset(topLeftX, topLeftY);
      double cellSize = r.width / paintingSpecs.sizeX;
      int x = (point.dx / cellSize).floor();
      int y = (point.dy / cellSize).floor();
      print('Hit is at puzzle-cell ($x, $y)');
      // If hitting this cell is a valid move, the Puzzle model will be updated.
      modelChanged = puzzle.hitPuzzleArea(x, y);
    }
    else {
      Rect r = paintingSpecs.controlRect;
      if (r.contains(hitPos)) {
        // Hit is on control-area: get current number of controls.
        int nSymbols = paintingSpecs.nSymbols;
        int nCells = (puzzle.puzzlePlay == Play.NotStarted) ||
                     (puzzle.puzzlePlay == Play.BeingEntered) ?
                     nSymbols + 1 : nSymbols + 2;
        bool portrait = paintingSpecs.portrait;
        double cellSize = portrait ? r.width / nCells : r.height / nCells;
        Offset point = hitPos - Offset(topLeftXc, topLeftYc);
        int x = (point.dx / cellSize).floor();
        int y = (point.dy / cellSize).floor();
        print('Hit is at control-cell ($x, $y)');
        int selection = portrait ? x : y;	// Get the selected control num.
        modelChanged = puzzle.hitControlArea(selection);
      }
      else {
        print('_possibleHit: NOT A HIT');
        return;			// Not a hit. Don't repaint.
      }
    }
    print('MODEL CHANGED $modelChanged');
    // NOTE: If the hit led to a valid change in the puzzle model,
    //       notifyListeners() has been called and a repaint will
    //       be scheduled by Provider. If the attempted move was
    //       invalid, there is no model-change and no repaint.
  }
} // End class _PuzzleView extends StatelessWidget


  // TODO - Find out for sure how to use Listenable and repaint param properly.
  //
  //        For now, adding 2nd param and super() seems to get repaints OK.
  //        Oh, and adding "repaint: repaint" to the super's parameters is
  //        harmless and might help us get re-painting on value-change later. 

class PuzzlePainter extends CustomPainter
{
  final Puzzle puzzle;

  PuzzlePainter(this.puzzle);

  // NOTE: PuzzlePainter does not use the Listenable? repaint parameter of
  //       CustomerPainter, nor the technique of re-implementing it with
  //       ChangeNotifier (which has been tried). Instead PuzzlePainter and
  //       the Puzzle class rely on Provider to trigger repaints on any change
  //       in the Puzzle model, whether the user taps on icon-buttons or Canvas.

  Offset topLeft  = Offset (0.0, 0.0);
  double cellSide = 1.0;

  Offset hitPosition = Offset(-1.0, -1.0);
  Size   prevSize = Size(10.0, 10.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint or re-paint the puzzle-area, the puzzle-controls (symbols),
    // the given-values (clues) for the puzzle and the symbols and notes
    // that the user has entered as their solution.

    canvas.clipRect((Offset(0.0, 0.0) & size));
    // print('\n\nENTERED PuzzlePainter.paint(Canvas canvas, Size size)');
    // print('Size $size, previous size $prevSize');
    bool sizeChanged = (size != prevSize);
    if (sizeChanged) {
      prevSize = size;
    }

    // ******** DEBUG ********
    int w = size.width.floor();
    int h = size.height.floor();
    // print('ENTERED PuzzlePainter W $w, H $h');
    // ***********************

    PaintingSpecs paintingSpecs = puzzle.paintingSpecs;

    int  nSymbols      = paintingSpecs.nSymbols;
    int  sizeX         = paintingSpecs.sizeX;
    int  sizeY         = paintingSpecs.sizeY;

    bool portrait      = paintingSpecs.portrait;
    bool hideNotes     = (puzzle.puzzlePlay == Play.NotStarted) ||
                         (puzzle.puzzlePlay == Play.BeingEntered);
    int  nControls     = hideNotes ? nSymbols + 1 : nSymbols + 2;
    List<double> xy    = calculatePuzzleLayout (portrait, size,
                                                paintingSpecs, hideNotes);

    // Co-ordinates of top-left corner of puzzle-area.
    topLeftX           = xy[0];
    topLeftY           = xy[1];
    topLeft            = Offset(xy[0], xy[1]);
    cellSide           = cellSize;     // xy[4];

    // Co-ordinates of top-left corner of puzzle-controls (symbols).
    topLeftXc          = xy[2];
    topLeftYc          = xy[3];

    // Cell sizes for puzzle-area and controls (symbols).
    // NOTE: Can we make this a file-global?  double cellSize    = xy[4];
    double controlSize = xy[5];

    var lightScheme = ColorScheme.fromSeed(seedColor: Colors.amber.shade200);
    var darkScheme  = ColorScheme.fromSeed(seedColor: Colors.amber.shade200,
                                           brightness: Brightness.dark);
    // Save the resulting rectangles for use in hit tests.
    paintingSpecs.canvasSize = size;
    paintingSpecs.puzzleRect = Rect.fromLTWH(
          topLeftX, topLeftY, sizeX * cellSize, sizeY * cellSize);
    Size controlRectSize = paintingSpecs.portrait ?
          Size(controlSize * nControls, controlSize) : // Horizontal.
          Size(controlSize, controlSize * nControls);  // Vertical.
    paintingSpecs.controlRect = Rect.fromLTWH(
          topLeftXc, topLeftYc, controlRectSize.width, controlRectSize.height);
    // Paints (and brushes/pens) for areas and lines.
    var paint1 = Paint()		// Background colour of canvas.
      ..color = Colors.amber.shade100
      ..style = PaintingStyle.fill;
    var paint2 = Paint()		// Background colour of cells.
      ..color = Colors.amber.shade200
      ..style = PaintingStyle.fill;
    var paint3 = Paint()		// Colour of Given cells.
      // ..color = Colors.amberAccent.shade700
      ..color = Color(0xffffd600)	// yellow.shade700
      ..style = PaintingStyle.fill;
    var paintSpecial = Paint()		// Colour of Special cells.
      ..color = Colors.lime.shade400	// amberAccent.shade400
      ..style = PaintingStyle.fill;
    var paintError = Paint()		// Colour of Error cells.
      ..color = Colors.red.shade300
      ..style = PaintingStyle.fill;
    var thinLinePaint = Paint()		// Style for lines between cells.
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    var thickLinePaint = Paint()	// Style for edges of groups of cells.
      ..color = Colors.brown.shade600
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    var highlight      = Paint()	// Style for highlights.
      ..color = Colors.red.shade400
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    var cageLinePaint = Paint()		// Style for lines around cages.
      // ..color = Colors.lime.shade800
      ..color = Colors.lightGreen
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSize / 30.0;
    cageLinePaint.strokeWidth  = cellSize / 30.0;
    thickLinePaint.strokeWidth = cellSize / 15.0;
    highlight.strokeWidth      = cellSize / 15.0;

    // Now paint the background of the canvas.
    canvas.drawRect(Offset(0, 0) & size, paint1);

    // Paint the backgrounds of puzzle-cells, as required by the puzzle-type.
    int nCells   = sizeX * sizeY;
    double gap = 0.0;
    double o1, o2;
    // TODO - Think about using a gradient in cell-painting, as opposed to gaps.
    for (int i = 0; i < nCells; i++) {
      o1 = topLeftX + gap/2.0 + (i~/sizeY) * cellSize;
      o2 = topLeftY + gap/2.0 + (i %sizeY) * cellSize;
      Paint cellPaint;
      switch (paintingSpecs.cellBackG[i]) {
        case GIVEN:
          cellPaint = paint3;
          break;
        case SPECIAL:
          cellPaint = paintSpecial;
          break;
        case VACANT:
        default:
          cellPaint = paint2;
      }
      if (paintingSpecs.cellBackG[i] != UNUSABLE) {	// Skip unused areas.
        // Paint the cells that are within the puzzle-area (note Samurai type).
        canvas.drawRect(Offset(o1,o2) & Size(cellSize - gap, cellSize - gap),
                        cellPaint);
      }
    }

    // Paint backgrounds of control_cells (symbols), including Erase and Notes.
    for (int i = 0; i < nControls; i++) {
      double o1, o2;
      if (portrait) {
        o1 = topLeftXc + i * controlSize;
        o2 = topLeftYc;
      }
      else {
        o1 = topLeftXc;
        o2 = topLeftYc + i * controlSize;
      } 
      canvas.drawRect(Offset(o1, o2) & Size(controlSize, controlSize), paint2);
    }

    // TODO - Draw thin edges first, then thick edges. Use different "heights"?

    // Draw light and dark edges of puzzle-area, as required by the puzzle type.
    int nEdges   = sizeY * (sizeX + 1);
    for (int i = 0; i < nEdges; i++) {
      double o1 = topLeftX + (i~/(sizeY + 1)) * cellSize;
      double o2 = topLeftY + (i%(sizeY + 1))  * cellSize;
      int paintType = paintingSpecs.edgesEW[i];
      if (paintType > 0) {
        Paint p = (paintType == 1) ? thinLinePaint : thickLinePaint;
        canvas.drawLine(Offset(o1, o2), Offset(o1 + cellSize, o2), p);
      }
      o1 = topLeftX + (i~/sizeY) * cellSize;
      o2 = topLeftY + (i%sizeY)  * cellSize;
      paintType = paintingSpecs.edgesNS[i];
      if (paintType > 0) {
        Paint p = (paintType == 1) ? thinLinePaint : thickLinePaint;
        canvas.drawLine(Offset(o1, o2), Offset(o1, o2 + cellSize), p);
      }
      // print('i = $i x = ${i~/(nSymbols + 1)} y = ${i%(nSymbols + 1)} EW = ${paintingSpecs.edgesEW[i]} NS = ${paintingSpecs.edgesNS[i]}');
    }

    // In Mathdoku or Killer Sudoku, paint the outlines and labels of the cages.
    if (puzzle.puzzleMap.cageCount() > 0) {
      paintCages(canvas, puzzle.puzzleMap.cageCount(),
                paint3, paint2, cageLinePaint);
    }

    // Paint framework of control-area, thick lines last, to cover thin ends.
    // Draw the lines between cells, horizontal or vertical, as required.
    if (portrait) {
      // Horizontal - at the bottom of the screen or window.
      for (int n = 0; n < nControls - 1; n++) {
        double o1 = topLeftXc + (n + 1) * controlSize;
        double o2 = topLeftYc + controlSize;
        canvas.drawLine(Offset(o1, topLeftYc), Offset(o1, o2), thinLinePaint);
      }
      canvas.drawRect(Offset(topLeftXc, topLeftYc) &
                      Size(nControls * controlSize, controlSize),
                      thickLinePaint);
    }
    else {
      // Vertical - at the side of the screen or window.
      for (int n = 0; n < nControls - 1; n++) {
        double o1 = topLeftXc + controlSize;
        double o2 = topLeftYc + (n + 1) * controlSize;
        canvas.drawLine(Offset(topLeftXc, o2), Offset(o1, o2), thinLinePaint);
      }
      canvas.drawRect(Offset(topLeftXc, topLeftYc) &
                      Size(controlSize, nControls * controlSize),
                      thickLinePaint);
    }

    // Add the graphics for the control symbols.
    Offset cellPos;
    int st = hideNotes ? 0 : 1;
    for (int n = 1; n <= nSymbols; n++) {
      if (portrait) {
        // Step over Erase and Notes at the left, then add the symbols.
        cellPos = Offset(topLeftXc + (n + st) * controlSize, topLeftYc);
      }
      else {
        // Step over Erase and Notes at the top, then add the symbols.
        cellPos = Offset(topLeftXc, topLeftYc + (n + st) * controlSize);
      }
      paintingSpecs.paintSymbol(canvas, n, cellPos, controlSize,
                                isNote: false, isCell: false);
    }

    // Paint/repaint the graphics for all the symbols in the puzzle area.
    int puzzleSize = paintingSpecs.sizeX * paintingSpecs.sizeY;
    for (int pos = 0; pos < puzzleSize; pos++) {
      int ns = puzzle.stateOfPlay[pos];
      if (ns == UNUSABLE) {
        continue;
      }
      int status = puzzle.cellStatus[pos];
      if ((status == GIVEN) || (status == ERROR)) {
        Paint cellPaint = (status == GIVEN) ? paint3 : paintError;
        gap = 12.0;
        o1 = topLeftX + gap/2.0 + (pos~/sizeY) * cellSize;
        o2 = topLeftY + gap/2.0 + (pos %sizeY) * cellSize;
        canvas.drawOval(Offset(o1, o2) & Size(cellSize - gap, cellSize - gap),
                        cellPaint);
      }
      int i = puzzle.puzzleMap.cellPosX(pos);
      int j = puzzle.puzzleMap.cellPosY(pos);
      cellPos = Offset(topLeftX, topLeftY) + Offset(i * cellSize, j * cellSize);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                cellSize, isNote: (ns > 1024), isCell: true);
      if (pos == puzzle.lastCellHit) {
        canvas.drawRect(cellPos & Size(cellSize, cellSize), highlight);
      }
    }

    // Highlight the user's latest control-selection.
    cellPos   = Offset(topLeftXc, topLeftYc);
    int    n  = puzzle.selectedControl + (hideNotes ? 0 : 1);
    double d  = n * controlSize;
    cellPos  = cellPos + (paintingSpecs.portrait ? Offset(d, 0) : Offset(0, d));
    canvas.drawRect(cellPos & Size(controlSize, controlSize), highlight);

    // Add the label for the Notes button and highlight it, if required.
    cellPos = Offset(topLeftXc, topLeftYc);
    if (! hideNotes) {
      cellPos = Offset(topLeftXc, topLeftYc);
      for (int n = 1; n <= 3; n++) {
        paintingSpecs.paintSymbol(canvas, n, cellPos,
                  controlSize, isNote: true, isCell: false);
      }
      if (puzzle.notesMode) {
        canvas.drawRect(cellPos & Size(controlSize, controlSize), highlight);
      }
    }
  } // End void paint(Canvas canvas, Size size)

  @override
  bool shouldRepaint(PuzzlePainter oldDelegate) {
    print('ENTERED PuzzlePainter shouldRepaint()');
    return true;
  }

  @override
  // Don't need hitTest function? Can do everything required in _possibleHit().
  bool? hitTest(Offset position)
  {
    return null;
  }

  void paintCages(Canvas canvas, int cageCount, 
                 Paint labelPaint_fg, Paint labelPaint_bg, Paint cageLinePaint)
  {
    PaintingSpecs paintingSpecs = puzzle.paintingSpecs;

    List<int> cageBoundaryBits = paintingSpecs.cageBoundaries;
    double inset = cellSide/12.0;

    for (int n = 0; n < puzzle.puzzleMap.size; n++) {
      int lineBits = cageBoundaryBits[n];
      // TODO - Single-cell cages are NOT displaying NOR behaving as GIVENS.
      if (lineBits == 1170) {
        // Single-cell cages are not painted (1170 = octal 2222).
        continue;
      }
      for (int side = 0; side < 4; side++) {
        int bits = lineBits & 7;
        lineBits = lineBits >> 3;
        if (bits == 0) {
          continue;
        }
        int i = puzzle.puzzleMap.cellPosX(n);
        int j = puzzle.puzzleMap.cellPosY(n);
        Offset cellOrigin = topLeft + Offset(i * cellSide, j * cellSide);
        double x1 = 0.0, x2 = 0.0;
        // double x2 = 0.0;
        double y1 = 0.0;
        double y2 = 0.0;
        switch(side) {
        case 0:
          x1 = cellSide - inset;
          x2 = x1;
          y1 = (bits & 1) > 0 ? 0.0 : inset;
          y2 = (bits & 4) > 0 ? cellSide : cellSide - inset;
          break;
        case 1:
          x1 = (bits & 1) > 0 ? cellSide : cellSide - inset;
          x2 = (bits & 4) > 0 ? 0.0 : inset;
          y1 = cellSide - inset;
          y2 = y1; 
          break;
        case 2:
          x1 = inset;
          x2 = x1; 
          y1 = (bits & 1) > 0 ? cellSide : cellSide - inset;
          y2 = (bits & 4) > 0 ? 0.0 : inset;
          break;
        case 3:
          x1 = (bits & 1) > 0 ? 0.0 : inset;
          x2 = (bits & 4) > 0 ? cellSide : cellSide - inset;
          y1 = inset;
          y2 = y1;
          break;
        }
        canvas.drawLine(cellOrigin + Offset(x1, y1),
                        cellOrigin + Offset(x2, y2), cageLinePaint);
      }
    }
    // print('CAGE COUNT ${puzzle.puzzleMap.cageCount()}');
    PuzzleMap map = puzzle.puzzleMap;
    for (int cageNum = 0; cageNum < map.cageCount(); cageNum++) {
      String cageLabel  = getCageLabel(map, cageNum);

      int labelCell     = map.cageTopLeft(cageNum);
      int cellX         = map.cellPosX(labelCell);
      int cellY         = map.cellPosY(labelCell);
      double textSize   = cellSide / 6.0;
      Offset cellOrigin = topLeft + Offset(cellX * cellSide, cellY * cellSide);
      paintingSpecs.paintCageLabelText(canvas, cageLabel,
                                       textSize, cellOrigin,
                                       labelPaint_fg, labelPaint_bg);
    }
  }

  String getCageLabel (PuzzleMap map, int cageNum) // bool killerStyle)
  {
    bool killerStyle = false;	// TODO - For testing only.
    if (map.cage(cageNum).length < 2) {
	return '';		// 1-cell cages are displayed as Givens (clues).
    }

    String cLabel = map.cageValue(cageNum).toString();
    if (! killerStyle) {	// No operator is shown in KillerSudoku.
        int opNum = map.cageOperator(cageNum).index;
	cLabel = cLabel + " /-x+".substring(opNum, opNum + 1);
    }
    // print('Cage Label $cLabel, cage $cageNum, cell $topLeft');
    return cLabel;
  }

  // Result: 12 bits for each cell in the cage.
  //           bits 0-2   East side,
  //           bits 3-5   South side,
  //           bits 6-8   West side,
  //           bits 9-11  North side.
  //
  //         Within a cell, there are 3 bits for each possible cell-boundary
  //         line. The three bits represent:
  //           bit  0     First part of possible cage-boundary line,
  //           bit  1     Second or middle part,
  //           bit  2     Third part.
  //
  // If the three bits == 0, that side of the cell is not a cage-boundary.
  // If the three bits == 7, the boundary line is full-length. Values 6, 3
  // or 2, mean that the boundary turns a corner at one end or the other or
  // both. Values 1, 4 and 5 are not used: the line would have no middle part.

  // TODO: Does "first" mean nearest to top-left origin or first in ESWN order?

  // List<Offset> outerCorners = [(lSide, 0.0),       (lSide, lSide),
                               // (0.0, lSide),       (0.0, 0.0)];
  // List<Offset> innerCorners = [(lSide - 1.0, 1.0), (lSide - 1.0, lSide - 1.0),
                               // (1.0, lSide - 1.0), (1.0, 1.0)];
// TODO - Maybe use the above in PuzzlePainter?

} // End class PuzzlePainter extends CustomPainter


// ************************************************************************** //
//   This function is outside any class... It is used by class PuzzlePainter.
// ************************************************************************** //
double cellSize    = 10.0;
double controlSize = 10.0;
double topLeftX    = 10.0;
double topLeftY    = 10.0;
double topLeftXc   = 10.0;
double topLeftYc   = 10.0;

List<double> calculatePuzzleLayout (bool portrait, Size size,
                                    PaintingSpecs paintingSpecs,
                                    bool hideNotes)
{
  // print('LAYOUT: Portrait $portrait, Size $size, hideNotes $hideNotes');

  // Set up the layout calculation for landscape orientation.
  double shortSide   = size.height;
  double longSide    = size.width;
  int    puzzleCells = paintingSpecs.sizeY;
  if (portrait) {
    // Change to portrait setup.
    shortSide   = size.width;
    longSide    = size.height;
    puzzleCells = paintingSpecs.sizeX;
  }
  // Fix the size of the margin in relation to the canvas size.
  double margin   = shortSide / 35.0;

  // Fix the spaces now remaining for the puzzle and the symbol buttons.
  shortSide = shortSide - margin * 2.0;
  longSide  = longSide  - margin * 3.0;
  // print('MARGIN: $margin, shortSide $shortSide, longSide $longSide');

  // Calculate the space allocations. Initially assume that the puzzle-area
  // will fill the short side, except for the two margins.
         cellSize        = shortSide / puzzleCells;	// Calculate cell size.
  int    x               = hideNotes ? 1 : 2;
  int    nControls       = paintingSpecs.nSymbols + x;	// Add Erase and Notes.
         controlSize     = shortSide / nControls;
  double padding         = longSide - shortSide - controlSize;
  bool   longSidePadding = (padding >= 1.0);	// Enough space for padding?

  // print('X $x, nControls $nControls, shortSide $shortSide');
  // print('longSide $longSide, padding $padding, controlSize $controlSize');

  // If everything fits, fine...
  if (longSidePadding) {
    // Calculate space left at top-left corner.
    // print('LONG SIDE PADDING $padding');
    longSide  = margin + padding / 2.0;
    shortSide = margin;
    // print('Long side $longSide, short side $shortSide');
  }
  else {
    // ...otherwise make the puzzle-area smaller and pad the short side.
    cellSize    = (shortSide + padding) / puzzleCells;
    controlSize = (shortSide + padding) / nControls;
    padding     = shortSide - puzzleCells * cellSize;   // Should be +'ve now.
    // print('SHORT SIDE PADDING $padding');
    // Calculate space left at top-left corner.
    shortSide   = margin + padding / 2.0;
    longSide    = margin;
    // print('Long side $longSide, short side $shortSide');
  }
  // Set the offsets and sizes to be used for co-ordinates within the puzzle.
  // Order is topLeftX, topLeftY, topLeftXc, topLeftYc, cellSize, controlSize.
  List<double> result;
  if (portrait) {
    result = [shortSide, longSide,
              shortSide, size.height - controlSize - margin];
              // margin, size.height - controlSize - margin];
  }
  else {
    result = [longSide, shortSide,
              size.width - controlSize - margin, shortSide];
              // size.width - controlSize - margin, margin];
  }
  result.add(cellSize);
  result.add(controlSize);
  return result;
}
