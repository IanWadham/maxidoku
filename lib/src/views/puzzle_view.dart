import 'package:flutter/material.dart';
import 'package:community_material_icon/community_material_icon.dart';

import '../settings/settings_view.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import '../models/puzzle_types.dart';
import 'painting_specs_2d.dart';
import 'messages.dart';

/* ************************************************************************** **
   ICON BUTTONS - Enter a puzzle (no button: let a user enter something and
   then check that they wish to continue). Mark and go back to Mark???

   Set symmetry, set difficulty in Settings. Message to user about this???
** ************************************************************************** */

/* ************************************************************************** **
  // Can get device/OS/platform at https://pub.dev/packages/device_info_plus
  // See also the "Dependencies" list in the column at RHS of that page re
  // info on MacOS, Linux, Windows, etc.
** ************************************************************************** */

const double eraseDepth = 0.67;

/// Displays a Sudoku puzzle of a selected type and size.
class PuzzleView extends StatelessWidget
{
  final int       index;	// Position in puzzle-specifications list.

  PuzzleView(this.index, {Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // Create the selected Puzzle object.
    final Puzzle puzzle = new Puzzle(index);

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
          print('PRESSED CHECK **********************************************');
          await infoMessage(context, 'Check Puzzle',
                  'OK, check the puzzle now.',
                  okText: 'Done');
          print('AFTER Info Message');
          // puzzle.testPuzzle();
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

    if (! paintingSpecs.portrait) {	// Landscape orientation.
      // Paint the puzzle with the action icons in a column on the RHS.
      return Scaffold( /* appBar: AppBar( title: const Text('Puzzle'),), */
        body: Row(
          children: <Widget>[
            Expanded(
              child: _PuzzleView(puzzle),
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
              child: _PuzzleView(puzzle),
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
      // TODO - Ensure that a repaint is done, to show the new puzzle.
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
  const _PuzzleView(this.puzzle, {Key? key}) : super(key: key);

  @override
  _PuzzleViewState createState() => _PuzzleViewState();

} // End class _PuzzleView extends StatefulWidget

// TODO - Resolve what is to be passed here, if anything, and whether to create Puzzle() at the App level first. Surely the 2D View and the puzzle contents (current solution state) should not just disappear if we go back to PuzzleListView, for example...

// TODO - I think we should have a stateless part of View, which is the puzzle layout and controls, plus any solution and clues. Then there should be a variable part of the view that supports symbol-entry by the user and undo/redo - perhaps a transparent overlay containing (opaque) symbols - notes and parts of the user's solution so far. The underlying data for the latter must persist for as long as the app does and maybe longer (e.g. if the device switches to another app or is put to sleep).

// TODO - 1. Calculate the allocation of space. 2. Calculate and draw an empty area and set of symbols from the PuzzleMap. 3. Generate a puzzle, if required. 4. Display the puzzle contents. 5. Accept clicks and update the user's solution.


class _PuzzleViewState extends State<_PuzzleView>
{
  Offset hitPos = Offset(-1.0, -1.0);
  late PuzzlePainter puzzlePainter;

  // Handle the user's PointerDown actions on the puzzle-area and controls.
  void _possibleHit(PointerEvent details)
  {
    setState(() {hitPos = details.localPosition;} );
    print('HIT ${hitPos.dx.toStringAsFixed(2)}, ${hitPos.dy.toStringAsFixed(2)}');
    // Tell the PuzzlePainter where the hit is and trigger a repaint.
    puzzlePainter.hitPosition = hitPos;
    puzzlePainter.notifyListeners();
  }

  @override
  // Make the Puzzle and PaintingSpecs objects accessible in the canvas() proc.
  // Together, they specify the background to paint and symbols (moves) to show.
  void initState() {
    super.initState();
    print('In _PuzzleViewState.initState()');
    // PaintingSpecs paintingSpecs = Puzzle().paintingSpecs;
    Puzzle puzzle = widget.puzzle;
    PaintingSpecs paintingSpecs = puzzle.paintingSpecs;
    puzzlePainter = new PuzzlePainter(puzzle, paintingSpecs);
  }

  @override
  // This widget contains the puzzle-area and puzzle-controls (symbols).
  Widget build(BuildContext context) {
    return Container(
      // We wish to fill the parent, in either Portrait or Landscape layout.
      height: (MediaQuery.of(context).size.height),
      width:  (MediaQuery.of(context).size.width),
      child:  Listener(
        onPointerDown: _possibleHit,
        child: CustomPaint(
          painter: puzzlePainter,
        ),
      ),
    );
  } // End Widget build()

} // End class _PuzzleViewState extends State<PuzzleView>


  // TODO - Find out for sure how to use Listenable and repaint param properly.
  //
  //        For now, adding 2nd param and super() seems to get repaints OK.
  //        Oh, and adding "repaint: repaint" to the super's parameters is
  //        harmless and might help us get re-painting on value-change later. 

class PuzzlePainter extends ChangeNotifier implements CustomPainter
{
  final Puzzle puzzle;
  final PaintingSpecs paintingSpecs;

  PuzzlePainter(this.puzzle, this.paintingSpecs);

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
    // print('W $w, H $h');
    // ***********************

    int  nSymbols      = paintingSpecs.nSymbols;
    int  sizeX         = paintingSpecs.sizeX;
    int  sizeY         = paintingSpecs.sizeY;

    bool portrait      = paintingSpecs.portrait;
    List<double> xy    = calculatePuzzleLayout (portrait, size, paintingSpecs);

    // Co-ordinates of top-left corner of puzzle-area.
    double topLeftX    = xy[0];
    double topLeftY    = xy[1];

    // Co-ordinates of top-left corner of puzzle-controls (symbols).
    double topLeftXc   = xy[2];
    double topLeftYc   = xy[3];

    // Cell sizes for puzzle-area and controls (symbols).
    double cellSize    = xy[4];
    double controlSize = xy[5];

    // Save the resulting rectangles for use in hit tests.
    paintingSpecs.canvasSize = size;
    paintingSpecs.puzzleRect = Rect.fromLTWH(
          topLeftX, topLeftY, sizeX * cellSize, sizeY * cellSize);
    Size controlRectSize = paintingSpecs.portrait ?
          Size(controlSize * (nSymbols + 2), controlSize) : // Horizontal.
          Size(controlSize, controlSize * (nSymbols + 2));  // Vertical.
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
      ..color = Colors.red.shade400
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
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSize / 30.0;
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
    for (int i = 0; i < (nSymbols + 2); i++) {
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

    // Paint framework of control-area, thick lines last, to cover thin ends.
    // Draw the lines between cells, horizontal or vertical, as required.
    if (portrait) {
      // Horizontal - at the bottom of the screen or window.
      for (int n = 0; n < nSymbols + 1; n++) {
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
      for (int n = 0; n < nSymbols + 1; n++) {
        double o1 = topLeftXc + controlSize;
        double o2 = topLeftYc + (n + 1) * controlSize;
        canvas.drawLine(Offset(topLeftXc, o2), Offset(o1, o2), thinLinePaint);
      }
      canvas.drawRect(Offset(topLeftXc, topLeftYc) &
                      Size(controlSize, (nSymbols + 2) * controlSize),
                      thickLinePaint);
    }

    // Add the graphics for the control symbols.
    Offset cellPos;
    for (int n = 1; n <= nSymbols; n++) {
      if (portrait) {
        // Step over Erase and Notes at the left, then add the symbols.
        cellPos = Offset(topLeftXc + (n + 1) * controlSize, topLeftYc);
      }
      else {
        // Step over Erase and Notes at the top, then add the symbols.
        cellPos = Offset(topLeftXc, topLeftYc + (n + 1) * controlSize);
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
        CellState m = puzzle.hitPuzzleArea(n);
        if (m.status == UNUSABLE) {
          print('Invalid move. Cell $n cannot be played.');
        }
        else {
          print('Change cell $n to status ${m.status}, value ${m.cellValue}');
          if (puzzle.puzzlePlay == Play.NotStarted) {
            // xxxx TODO - What goes here?
          }
        }
      }
    }

    // Check for a hit in the control-area.
    else if (paintingSpecs.controlRect.contains(hitPosition)) {
      print('Hit the Control Area');
      Rect r = paintingSpecs.controlRect;
      int nCells = paintingSpecs.nSymbols + 2;
      bool portrait = paintingSpecs.portrait;
      double cellSize = portrait ? r.width / nCells : r.height / nCells;
      Offset point = hitPosition - Offset(topLeftXc, topLeftYc);
      int x = (point.dx / cellSize).floor();
      int y = (point.dy / cellSize).floor();
      print('Hit is at cell ($x, $y)');
      int selection = portrait ? x : y;		// Get the selected symbol.
      if (selection == 0) {
        if ((puzzle.puzzlePlay == Play.NotStarted) ||
            (puzzle.puzzlePlay == Play.BeingEntered)) {
          puzzle.notesMode = false;		// Entered Puzzle has no Notes.
        }
        else {
          puzzle.notesMode = !puzzle.notesMode;	// Switch Notes when solving.
        }
      }
      else {
        // The value selected is treated as a cell-value, a note or an erase.
        puzzle.selectedControl = selection - 1; // + 1;
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
    int    n  = puzzle.selectedControl + 1;
    double d  = n * controlSize;
    cellPos  = cellPos + (paintingSpecs.portrait ? Offset(d, 0) : Offset(0, d));
    canvas.drawRect(cellPos & Size(controlSize, controlSize), highlight);

    // Add the label for the Notes button and highlight it, if required.
    cellPos = Offset(topLeftXc, topLeftYc);
    for (int n = 1; n <= 3; n++) {
      paintingSpecs.paintSymbol(canvas, n, cellPos,
                controlSize, isNote: true, isCell: false);
    }
    if (puzzle.notesMode) {
      canvas.drawRect(cellPos & Size(controlSize, controlSize), highlight);
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
    return true;
  }

  // Dummy methods: needed because we are re-implementing CustomPainter (above).
  get semanticsBuilder => null;

  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;

} // End class PuzzlePainter extends ChangeNotifier implements CustomPainter


// ************************************************************************** //
//   This function is outside any class... It is used by class PuzzlePainter.
// ************************************************************************** //
List<double> calculatePuzzleLayout (bool portrait, Size size,
                                    PaintingSpecs paintingSpecs)
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
  // int    nControls       = paintingSpecs.nSymbols + 1;	// Add 1 for "erase" op.
  int    nControls       = paintingSpecs.nSymbols + 2;	// Add Erase and Notes.
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
