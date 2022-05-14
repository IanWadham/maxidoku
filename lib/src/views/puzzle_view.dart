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
  // final int       index;	// Position in puzzle-specifications list.

  // const PuzzleView(this.index, {Key? key,}) : super(key: key);
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

    // TODO - CRASH!!!  generatePuzzle(puzzle, context);

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
      // Paint the puzzle with the action icons in a column on the right.
      return Scaffold(			// Omit AppBar, to maximize real-estate.
        body: Row(
          children: <Widget>[
            Expanded(
              child: _PuzzleView(),
            ),
            Ink(   // Give puzzle-background colour to column of IconButtons.
              color: Colors.amber.shade100,
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
      double cellSize = puzzleRect.width / puzzle.puzzleMap.sizeX;
      int x = (point.dx / cellSize).floor();
      int y = (point.dy / cellSize).floor();
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
        bool portrait = controlRect.width > controlRect.height;
        double cellSize = portrait ? controlRect.width / nCells
                                   : controlRect.height / nCells;
        Offset point = hitPos - Offset(topLeftXc, topLeftYc);
        int x = (point.dx / cellSize).floor();
        int y = (point.dy / cellSize).floor();
        print('Hit is at control-cell ($x, $y)');
        int selection = portrait ? x : y;	// Get the selected control num.
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
      modelChanged = true;
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

} // End class _PuzzleView extends StatelessWidget


class PuzzlePainter2D extends CustomPainter
{
  final Puzzle puzzle;

  PuzzlePainter2D(this.puzzle);

  // NOTE: PuzzlePainter2D does not use the Listenable? repaint parameter of
  //       CustomerPainter, nor does it re-implement CustomPainter with
  //       ChangeNotifier (which has been tried). Instead PuzzlePainter2D and
  //       the Puzzle class rely on Provider to trigger repaints on ANY change
  //       in the Puzzle model, whether the user taps on icon-buttons or Canvas.

  Offset topLeft  = Offset (0.0, 0.0);
  double cellSide = 1.0;

  Offset hitPosition = Offset(-1.0, -1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint or re-paint the puzzle-area, the puzzle-controls (symbols),
    // the given-values (clues) for the puzzle and the symbols and notes
    // that the user has entered as their solution.

    // If anything goes wrong, don't paint outside the Canvas.
    canvas.clipRect((Offset(0.0, 0.0) & size));

    // ******** DEBUG ********
    int w = size.width.floor();
    int h = size.height.floor();
    // print('ENTERED PuzzlePainter2D W $w, H $h');
    // ***********************

    PaintingSpecs2D paintingSpecs = puzzle.paintingSpecs2D;

    int  nSymbols      = paintingSpecs.nSymbols;
    int  sizeX         = paintingSpecs.sizeX;
    int  sizeY         = paintingSpecs.sizeY;

    bool portrait      = paintingSpecs.portrait;
    bool hideNotes     = (puzzle.puzzlePlay == Play.NotStarted) ||
                         (puzzle.puzzlePlay == Play.BeingEntered);
    int  nControls     = hideNotes ? nSymbols + 1 : nSymbols + 2;
    // List<double> xy    = paintingSpecs.calculatePuzzleLayout(size, hideNotes);
    paintingSpecs.calculatePuzzleLayout(size, hideNotes);

    topLeftX   = paintingSpecs.puzzleRect.left;
    topLeftY   = paintingSpecs.puzzleRect.top;
    topLeft    = paintingSpecs.puzzleRect.topLeft;
    cellSide   = paintingSpecs.cellSide;
    cellSize   = cellSide;

    topLeftXc  = paintingSpecs.controlRect.left;
    topLeftYc  = paintingSpecs.controlRect.top;
    double controlSize = paintingSpecs.controlSide;

    var lightScheme = ColorScheme.fromSeed(seedColor: Colors.amber.shade200);
    var darkScheme  = ColorScheme.fromSeed(seedColor: Colors.amber.shade200,
                                           brightness: Brightness.dark);

    // Paints (and brushes/pens) for areas and lines.
    var fill   = Paint()
      ..style = PaintingStyle.fill;
    var paint1 = fill
      ..color = Colors.amber.shade100;
    // var paint1 = Paint()		// Background colour of canvas.
      // ..color = Colors.amber.shade100
      // ..style = PaintingStyle.fill;
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
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // TODO - Paint Notes a little higher: bottom row clear of cage-lines.
    //        Make circles a bit smaller on Givens and Error cells (gradient?).
    //        Paint Symbols a little higher within the circles.
    //        Complete the "knees" on corners of some cages.

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSize / 30.0;
    cageLinePaint.strokeWidth  = cellSize / 20.0;
    thickLinePaint.strokeWidth = cellSize / 15.0;
    highlight.strokeWidth      = cellSize * paintingSpecs.highlightInset;

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
    }

    // Paint the control-area.
    paintingSpecs.paintPuzzleControls(canvas, nControls, thinLinePaint,
                  thickLinePaint, puzzle.notesMode, puzzle.selectedControl);

    // Paint/repaint the graphics for all the symbols in the puzzle area.
    int puzzleSize = paintingSpecs.sizeX * paintingSpecs.sizeY;
    Offset cellPos;
    Offset hilitePos = Offset(topLeftX, topLeftY);
    for (int pos = 0; pos < puzzleSize; pos++) {
      int ns = puzzle.stateOfPlay[pos];
      if (ns == UNUSABLE) {
        continue;
      }
      int status = puzzle.cellStatus[pos];
      if ((status == GIVEN) || (status == ERROR)) {
        Paint cellPaint = (status == GIVEN) ? paint3 : paintError;
        gap = cellSize / 8.0;		// TODO - Set this in a better place.
        o1 = topLeftX + gap/2.0 + (pos~/sizeY) * cellSize;
        o2 = topLeftY + gap/2.0 + (pos %sizeY) * cellSize;
        List<Color> shaderColors = [cellPaint.color, Color(0x00FFFFFF)];
        RadialGradient rg = RadialGradient(radius: 1.1, colors: shaderColors);
        Rect r = Offset(o1, o2) & Size(cellSize - gap, cellSize - gap);
        Shader shader = rg.createShader(r);
        Paint p = Paint();
        p.shader = shader;
        // TODO - Rethink this. Use Canvas.drawCircle(centre, radius, paint).
        canvas.drawOval(r, p);
      }
      int i = puzzle.puzzleMap.cellPosX(pos);
      int j = puzzle.puzzleMap.cellPosY(pos);
      cellPos = Offset(topLeftX, topLeftY) + Offset(i * cellSize, j * cellSize);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                cellSize, isNote: (ns > 1024), isCell: true);
      if (pos == puzzle.lastCellHit) {
        hilitePos = cellPos;		// Paint hilite last, on top of cages.
      }
    }

    // In Mathdoku or Killer Sudoku, paint the outlines and labels of the cages.
    if (puzzle.puzzleMap.cageCount() > 0) {
      paintCages(canvas, puzzle.puzzleMap.cageCount(),
                paint3, paint2, cageLinePaint);
    }

    // Paint the highlight of the last puzzle-cell hit.
    double shrinkBy = cellSize / 10.0;
    double inset = shrinkBy / 2.0;
    canvas.drawRect(hilitePos + Offset(inset, inset) &
               Size(cellSize - shrinkBy, cellSize - shrinkBy), highlight);

  } // End void paint(Canvas canvas, Size size)

  @override
  bool shouldRepaint(PuzzlePainter2D oldDelegate) {
    // print('ENTERED PuzzlePainter shouldRepaint()');
    return true;
  }

  @override
  // Can do everything required in _possibleHit2D().
  bool? hitTest(Offset position)
  {
    return null;
  }

  void paintCages(Canvas canvas, int cageCount, 
                  Paint labelPaint_fg, Paint labelPaint_bg, Paint cageLinePaint)
  {
    PaintingSpecs2D paintingSpecs  = puzzle.paintingSpecs2D;
    PuzzleMap       map            = puzzle.puzzleMap;
    List<List<int>> cagePerimeters = paintingSpecs.cagePerimeters;

    double inset = cellSide/12.0;
    List<Offset> corners = [Offset(inset, inset),			// NW
                            Offset(cellSide - inset, inset),		// NE
                            Offset(cellSide - inset, cellSide - inset),	// SE
                            Offset(inset, cellSide - inset)];		// SW

    // Paint lines to connect lists of right-turn and left-turn points in cage
    // perimeters. Lines are inset within cage edges and have a special colour.
    for (List<int> perimeter in cagePerimeters) {
      Offset? startLine   = null;
      for (Pair point in perimeter) {
        int cell          = point >> lowWidth;
        int corner        = point & lowMask;
        int i             = puzzle.puzzleMap.cellPosX(cell);
        int j             = puzzle.puzzleMap.cellPosY(cell);
        Offset cellOrigin = topLeft + Offset(i * cellSide, j * cellSide);
        Offset endLine    = cellOrigin + corners[corner];
        if (startLine != null) {
          canvas.drawLine(startLine, endLine, cageLinePaint);
        }
        startLine = endLine;		// Get ready for the next line.
      }
    }

    // Paint the cage labels.
    for (int cageNum = 0; cageNum < cageCount; cageNum++) {
      String cageLabel  = getCageLabel(map, cageNum);
      if (cageLabel == '') {
        continue;		// Don't paint labels on size 1 cages (Givens).
      }

      int labelCell     = map.cageTopLeft(cageNum);
      int cellX         = map.cellPosX(labelCell);
      int cellY         = map.cellPosY(labelCell);
      double textSize   = cellSide / 6.0;
      Offset cellOrigin = topLeft + Offset(cellX * cellSide, cellY * cellSide);
      Offset inset      = Offset(cellSide/20.0, cellSide/20.0);
      paintingSpecs.paintCageLabelText(canvas, cageLabel,
                                       textSize, cellOrigin + inset,
                                       labelPaint_fg, labelPaint_bg);
    }
  }

  String getCageLabel (PuzzleMap map, int cageNum) // bool killerStyle)
  {
    bool killerStyle = (map.specificType == SudokuType.KillerSudoku);
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

} // End class PuzzlePainter2D extends CustomPainter


// TODO - Phase these OUT. ALSO change cellSize to cellSide everywhere.
double cellSize    = 10.0;
double controlSize = 10.0;
double topLeftX    = 10.0;
double topLeftY    = 10.0;
double topLeftXc   = 10.0;
double topLeftYc   = 10.0;

class PuzzlePainter3D extends CustomPainter
{
  final Puzzle puzzle;

  PuzzlePainter3D(this.puzzle);

  // NOTE: PuzzlePainter3D does not use the Listenable? repaint parameter of
  //       CustomerPainter, nor does it re-implement CustomPainter with
  //       ChangeNotifier (which has been tried). Instead PuzzlePainter3D and
  //       the Puzzle class rely on Provider to trigger repaints on ANY change
  //       in the Puzzle model, whether the user taps on icon-buttons or Canvas.

  Offset topLeft  = Offset (0.0, 0.0);
  double cellSide = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint or re-paint the puzzle-area, the puzzle-controls (symbols),
    // the given-values (clues) for the puzzle and the symbols and notes
    // that the user has entered as their solution so far.

    // If anything goes wrong, don't paint outside the Canvas.
    canvas.clipRect((Offset(0.0, 0.0) & size));

    // ******** DEBUG ********
    int w = size.width.floor();
    int h = size.height.floor();
    // print('ENTERED PuzzlePainter3D.paint() W $w, H $h');
    // ***********************

    PaintingSpecs3D paintingSpecs = puzzle.paintingSpecs3D;

    int  nSymbols      = paintingSpecs.nSymbols;

    bool hideNotes     = (puzzle.puzzlePlay == Play.NotStarted) ||
                         (puzzle.puzzlePlay == Play.BeingEntered);
    int  nControls     = hideNotes ? nSymbols + 1 : nSymbols + 2;

    paintingSpecs.calculatePuzzleLayout(size, hideNotes);

    // Paints (and brushes/pens) for areas and lines.
    var paint1 = Paint()		// Background colour of canvas.
      ..color = Colors.amber.shade100
      ..style = PaintingStyle.fill;
    var thinLinePaint = Paint()		// Style for lines between cells.
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    var thickLinePaint = Paint()	// Style for edges of groups of cells.
      ..color = Colors.brown.shade300
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..strokeWidth = 1.5;
    var paintError = Paint()		// Colour of Error cells.
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;
    var paint3 = Paint()		// Colour of Given cells.
      // ..color = Colors.amberAccent.shade700
      ..color = Color(0xffffd600)	// yellow.shade700
      ..style = PaintingStyle.fill;
    var paint2 = Paint()		// Background colour of cells.
      ..color = Colors.amber.shade200
      ..style = PaintingStyle.fill;
    var paintSpecial = Paint()		// Colour of Special cells.
      ..color = Colors.lime.shade400	// amberAccent.shade400
      ..style = PaintingStyle.fill;

    // Now paint the background of the canvas.
    canvas.drawRect(Offset(0, 0) & size, paint1);

    paintingSpecs.add3DViewControls(canvas);

    paintingSpecs.paintPuzzleControls(canvas, nControls, thinLinePaint,
                  thickLinePaint, puzzle.notesMode, puzzle.selectedControl);

    paintingSpecs.calculateScale();

    double sc     = paintingSpecs.scale;
    double diam   = paintingSpecs.diameter * sc;
    Offset origin = paintingSpecs.origin;

    int nCircles  = paintingSpecs.rotated.length;
    for (int n = 0; n < nCircles; n++) {
      if (! paintingSpecs.rotated[n].used) {
        continue;			// Don't paint UNUSED cells.
      }

      // Scale the XY co-ordinates and reverse the Y-axis for 2D display.
      Offset centre = paintingSpecs.rotatedXY(n).scale(sc, -sc) + origin;

      // Set the colour for this cell. The order of priority
      // is ERROR, SPECIAL, GIVEN and then Normal.
      int ID = paintingSpecs.rotated[n].ID;
      int status = puzzle.cellStatus[ID];
      Paint cellPaint = paint2;			// Normal colour.
      if (status == ERROR) {
        cellPaint = paintError;			// ERROR colour.
      }
      else if (paintingSpecs.cellBackG[ID] == SPECIAL) {
        cellPaint = paintSpecial;		// Enhanced visibility colour.
      }
      else if (status == GIVEN) {
        cellPaint = paint3;			// Colour for GIVEN cells.
      }

      Rect r = Rect.fromCenter(center: centre, width: diam, height: diam);
      // List<Color> shaderColors = [paintError.color, Colors.white];
      List<Color> shaderColors = [cellPaint.color, Colors.white];
      RadialGradient rg = RadialGradient(radius: 1.1, colors: shaderColors);
      Shader shader = rg.createShader(r);
      Paint circleGradient = Paint();
      circleGradient.shader = shader;
      // TODO - Rethink this. Use Canvas.drawCircle(centre, radius, paint).
      canvas.drawOval(r, circleGradient);
      canvas.drawOval(r, thickLinePaint);

      // Scale and paint the symbols on this sphere, if any.
      int ns = puzzle.stateOfPlay[ID];
      // Offset cellPos = centre - Offset(diam/2.0, diam/2.0);
      Offset cellPos = centre - Offset(diam * 0.4, diam * 0.4);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                diam * 0.8, isNote: (ns > 1024), isCell: true);
    }

    // DEBUGGING - Mark the origin of the 3D co-ordinates.
    // Rect r = Rect.fromCenter(center: origin, width: 10.0, height: 10.0);
    // canvas.drawRect(r, thickLinePaint);
    
  } // End void paint(Canvas canvas, Size size)

  @override
  bool shouldRepaint(PuzzlePainter3D oldDelegate) {
    // print('ENTERED PuzzlePainter3D shouldRepaint()');
    return true;
  }

  @override
  // Can do everything required in _possibleHit2D().
  bool? hitTest(Offset position)
  {
    return null;
  }

} // End class PuzzlePainter3D
