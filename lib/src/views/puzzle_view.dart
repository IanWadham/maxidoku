import 'package:flutter/material.dart';
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

class PuzzleAncestor extends InheritedWidget
{
  // The object that contains all of the current internal state of the puzzle.
  final Puzzle puzzle;

  PuzzleAncestor({
    Key?     key,
    required PuzzleView child,
    required this.puzzle,	// From app.dart, selected in PuzzleListView.
  }) : super(key: key, child: child);

  static PuzzleAncestor of(BuildContext context) {
    final PuzzleAncestor? result =
            context.dependOnInheritedWidgetOfExactType<PuzzleAncestor>();
    assert(result != null, 'No PuzzleAncestor Widget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(PuzzleAncestor old) => false;
}

/// Displays a Sudoku puzzle of a selected type and size.
class PuzzleView extends StatelessWidget
{
  // TODO - DROP final int       index;	// Position in puzzle-specifications list.

  const PuzzleView({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Find the selected Puzzle object.
    // final Puzzle puzzle = new Puzzle(index);
    final Puzzle puzzle = PuzzleAncestor.of(context).puzzle;


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

    final _PuzzleView puzzleView = _PuzzleView(puzzle);
    // final _PuzzleView puzzleView = _PuzzleView();
    if (! paintingSpecs.portrait) {	// Landscape orientation.
      // Paint the puzzle with the action icons in a column on the RHS.
      return Scaffold( /* appBar: AppBar( title: const Text('Puzzle'),), */
        body: Row(
          children: <Widget>[
            Expanded(
              child: puzzleView, //// _PuzzleView(puzzle), ///// , context),
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
    else {				// Portrait orientation.
      // Paint the puzzle with the action icons in a row at the top.
      return Scaffold( /* appBar: AppBar( title: const Text('Puzzle'),), */
        body: Column(
          children: <Widget> [
            Ink( // Give puzzle-background colour to row of IconButtons.
              color: Colors.amber.shade100,
              child: Row(
                children: actionIcons,
              ),
            ),
            Expanded(
              child: puzzleView, //// _PuzzleView(puzzle), ///// , context),
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
      // TODO - Ensure that a repaint is done, to show the new puzzle.
    }
  }

  void checkPuzzle(Puzzle puzzle, BuildContext context)
  async
  {
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


class _PuzzleView extends StatefulWidget
{
  final Puzzle puzzle;
  // final Puzzle puzzle = PuzzleAncestor.of(context).puzzle;
  /////// final BuildContext context;
  const _PuzzleView(this.puzzle, /* this.context, */ {Key? key}) : super(key: key);

  @override
  _PuzzleViewState createState() => _PuzzleViewState();

} // End class _PuzzleView extends StatefulWidget

// TODO - Resolve what is to be passed here, if anything, and whether to create Puzzle() at the App level first. Surely the 2D View and the puzzle contents (current solution state) should not just disappear if we go back to PuzzleListView, for example...

// TODO - I think we should have a stateless part of View, which is the puzzle layout and controls, plus any solution and clues. Then there should be a variable part of the view that supports symbol-entry by the user and undo/redo - perhaps a transparent overlay containing (opaque) symbols - notes and parts of the user's solution so far. The underlying data for the latter must persist for as long as the app does and maybe longer (e.g. if the device switches to another app or is put to sleep).

// TODO - 1. Calculate the allocation of space. 2. Calculate and draw an empty area and set of symbols from the PuzzleMap. 3. Generate a puzzle, if required. 4. Display the puzzle contents. 5. Accept clicks and update the user's solution.


class _PuzzleViewState extends State<_PuzzleView>
{
  Offset hitPos    = Offset(-1.0, -1.0);
  String dummyValue = ' ';
  late PuzzlePainter puzzlePainter;

  // Handle the user's PointerDown actions on the puzzle-area and controls.
  void _possibleHit(PointerEvent details)
  {
    hitPos = details.localPosition;
    dummyValue = dummyValue == ' ' ? '  ' : ' ';	// TODO - KLUDGE.
    print ('_possibleHit at $hitPos');
    puzzlePainter.hitPosition = hitPos;
    setState(() {} );
  }

  @override
  // Make the Puzzle and PaintingSpecs objects accessible in the canvas() proc.
  // Together, they specify the background to paint and symbols (moves) to show.
  void initState() {
    super.initState();
    print('In _PuzzleViewState.initState()');
    Puzzle puzzle = widget.puzzle;
    PaintingSpecs paintingSpecs = puzzle.paintingSpecs;
    puzzlePainter = new PuzzlePainter(puzzle, paintingSpecs);
  }

  @override
  // This widget contains the puzzle-area and puzzle-controls (symbols).
  Widget build(context) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {executeAfterBuild();});
    return Container(
      // We wish to fill the parent, in either Portrait or Landscape layout.
      height: (MediaQuery.of(context).size.height),
      width:  (MediaQuery.of(context).size.width),
      child:  Listener(
        onPointerDown: _possibleHit,
        child: CustomPaint(
          painter: puzzlePainter,
            child: Text('$dummyValue'
          ),
        ),
      ),
    );
  } // End Widget build()

  Future<void> executeAfterBuild() async
  {
    // TODO - Not seeing the HasError message. Seems to happen when last move
    //        is an error, but seems OK if an earlier move is incorrect.
    // Check to see if there was any major change during the last repaint of
    // the Puzzle. If so, issue appropriate messages. Flutter does not allow
    // them to be issued or automatically queued during a repaint.
    Play playNow = widget.puzzle.puzzlePlay;
    if (widget.puzzle.isPlayUnchanged()) {
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
} // End class _PuzzleViewState extends State<PuzzleView>


  // TODO - Find out for sure how to use Listenable and repaint param properly.
  //
  //        For now, adding 2nd param and super() seems to get repaints OK.
  //        Oh, and adding "repaint: repaint" to the super's parameters is
  //        harmless and might help us get re-painting on value-change later. 

class PuzzlePainter extends CustomPainter
{
  final Puzzle puzzle;
  final PaintingSpecs paintingSpecs;

  PuzzlePainter(this.puzzle, this.paintingSpecs);

  Offset topLeft  = Offset (0.0, 0.0);
  double cellSide = 1.0;

  Offset hitPosition = Offset(-1.0, -1.0);
  Size prevSize = Size(10.0, 10.0);

  /* Paint or re-paint the puzzle-area, the puzzle-controls (symbols), *
   * the given-values (clues) for the puzzle and the symbols and notes *
   * that the user has entered as their solution.                      */
  @override
  void paint(Canvas canvas, Size size) {
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
    double topLeftX    = xy[0];
    double topLeftY    = xy[1];
    topLeft            = Offset(xy[0], xy[1]);
    cellSide           = xy[4];

    // Co-ordinates of top-left corner of puzzle-controls (symbols).
    double topLeftXc   = xy[2];
    double topLeftYc   = xy[3];

    // Cell sizes for puzzle-area and controls (symbols).
    double cellSize    = xy[4];
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
                      Size((nSymbols + 2) * controlSize, controlSize),
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

    // ******** DEBUG ********
    Offset old = paintingSpecs.lastHit;
    Offset fake = Offset(1.0, 1.0);
    if (hitPosition.dx > 0.0 && hitPosition.dy > 0.0) {
      if (hitPosition != fake) print('HIT SEEN at $hitPosition, last hit $old');
      Offset diff = hitPosition - old;
      double tol = 5.0;
      if (diff.dx > -tol && diff.dy > -tol && diff.dx < tol && diff.dy < tol) {
        // print('DUPLICATE HIT... tolerance $tol');
        hitPosition = fake;	// In Canvas, but not in an active area.
      }
      else {
        paintingSpecs.lastHit = hitPosition;
        // print('NEW HIT....');
      }
    }
    else {
      // print('NO HIT this time');
    }
    // ***********************

    // Check for a hit in the puzzle-area (i.e. a user-move).
    Rect r = paintingSpecs.puzzleRect;
    // print('In Canvas.paint()');
    // Puzzle puzzle = Puzzle(); // paintingSpecs.puzzle;
    if (r.contains(hitPosition)) {
      print('Hit the Puzzle Area');
      Offset point = hitPosition - Offset(topLeftX, topLeftY);
      double cellSize = r.width / paintingSpecs.sizeX;
      int x = (point.dx / cellSize).floor();
      int y = (point.dy / cellSize).floor();
      print('Hit is at cell ($x, $y)');
      int n = puzzle.puzzleMap.cellIndex(x, y);
      print('Cell index = $n');
      if ((paintingSpecs.cellBackG[n] == UNUSABLE) ||
          (paintingSpecs.cellBackG[n] == GIVEN)) {
        print('Cell $n cannot be played.');
      }
      else {
        // Record the user's move, if it is valid.
        PuzzleState p = puzzle.hitPuzzleArea(n);
        if (p.cellState.status == INVALID) {
          print('Invalid move. Cell $n cannot be played.');
        }
        else {
          print('Change cell $n to status ${p.cellState.status},'
                ' value ${p.cellState.cellValue}');
        }
      }
    }

    // Check for a hit in the control-area.
    else if (paintingSpecs.controlRect.contains(hitPosition)) {
      print('Hit the Control Area');
      Rect r = paintingSpecs.controlRect;
      int nCells = nControls;
      bool portrait = paintingSpecs.portrait;
      double cellSize = portrait ? r.width / nCells : r.height / nCells;
      Offset point = hitPosition - Offset(topLeftXc, topLeftYc);
      int x = (point.dx / cellSize).floor();
      int y = (point.dy / cellSize).floor();
      print('Hit is at cell ($x, $y)');
      int selection = portrait ? x : y;		// Get the selected symbol.
      if (! hideNotes && (selection == 0)) {
        puzzle.notesMode = !puzzle.notesMode;	// Switch Notes when solving.
      }
      else {
        // The value selected is treated as a cell-value, a note or an erase.
        puzzle.selectedControl = selection - (hideNotes ? 0 : 1);
      }
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

    // print('REACHED END of PuzzlePainter.paint()...');
  } // End void paint(Canvas canvas, Size size)

  @override
  bool shouldRepaint(PuzzlePainter oldDelegate) {
    print('ENTERED PuzzlePainter shouldRepaint()');
    return true;
  }

  @override
  // Don't need hitTest function? Can do everything required in _possibleHit().
  // bool? hitTest(Offset position) => false; // null;
  bool? hitTest(Offset position)
  {
    // print('ENTERED PuzzlePainter hitTest: hitPosition = $position');
    // hitPosition = position;
    return null;
  }
/* TODO - Not needed now?
  // Dummy methods: needed because we are re-implementing CustomPainter (above).
  get semanticsBuilder => null;

  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
*/

  void paintCages(Canvas canvas, int cageCount, 
                 Paint labelPaint_fg, Paint labelPaint_bg, Paint cageLinePaint)
  {
    List<int> cageBoundaryBits = paintingSpecs.cageBoundaries;
    double inset = cellSide/12.0;

    for (int n = 0; n < puzzle.puzzleMap.size; n++) {
      // paintingSpecs.drawOneCage(n, cageLinePaint);
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
List<double> calculatePuzzleLayout (bool portrait, Size size,
                                    PaintingSpecs paintingSpecs,
                                    bool hideNotes)
{
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
  // print('MARGIN: $margin');

  // Calculate the space allocations. Initially assume that the puzzle-area
  // will fill the short side, except for the two margins.
  double cellSize        = shortSide / puzzleCells;	// Calculate cell size.
  int    x               = hideNotes ? 1 : 2;
  int    nControls       = paintingSpecs.nSymbols + x;	// Add Erase and Notes.
  double controlSize     = shortSide / nControls;
  double padding         = longSide - shortSide - controlSize;
  bool   longSidePadding = (padding >= 1.0);	// Enough space for padding?
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
    // shortSide   = /* margin + i??? */ padding / 2.0;
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
