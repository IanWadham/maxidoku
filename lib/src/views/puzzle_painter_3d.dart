import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import 'painting_specs_3d.dart';


class PuzzlePainter3D extends CustomPainter
{
  final Puzzle puzzle;
  final bool   isDarkMode;

  PuzzlePainter3D(this.puzzle, this.isDarkMode);

  // NOTE: PuzzlePainter3D does not use the Listenable? repaint parameter of
  //       CustomerPainter, nor does it re-implement CustomPainter with
  //       ChangeNotifier (which has been tried). Instead PuzzlePainter3D and
  //       the Puzzle class rely on Provider to trigger repaints on ANY change
  //       in the Puzzle model, whether the user taps on icon-buttons or Canvas.

  Offset topLeft  = const Offset (0.0, 0.0);
  double cellSide = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint or re-paint the puzzle-area, the puzzle-controls (symbols),
    // the given-values (clues) for the puzzle and the symbols and notes
    // that the user has entered as their solution so far.

    // If anything goes wrong, don't paint outside the Canvas.
    canvas.clipRect((const Offset(0.0, 0.0) & size));

    // ******** DEBUG ********
    // int w = size.width.floor();
    // int h = size.height.floor();
    // debugPrint('ENTERED PuzzlePainter3D.paint() W $w, H $h');
    // ***********************

    PaintingSpecs3D paintingSpecs = puzzle.paintingSpecs3D;

    int  nSymbols      = paintingSpecs.nSymbols;

    bool hideNotes     = (puzzle.puzzlePlay == Play.NotStarted) ||
                         (puzzle.puzzlePlay == Play.BeingEntered);
    int  nControls     = hideNotes ? nSymbols + 1 : nSymbols + 2;
    // debugPrint('3D: nSymbols $nSymbols, hideNotes $hideNotes, nControls $nControls');

    paintingSpecs.calculatePuzzleLayout(size, hideNotes);
    paintingSpecs.setPuzzleThemeMode(isDarkMode);

    // Paints (and brushes/pens) for areas and lines.
    Paint backgroundPaint  = paintingSpecs.backgroundPaint;
    Paint innerSpherePaint = paintingSpecs.innerSpherePaint;
    Paint outerSpherePaint = paintingSpecs.outerSpherePaint;
    Paint givenCellPaint   = paintingSpecs.givenCellPaint;
    Paint specialCellPaint = paintingSpecs.specialCellPaint;
    Paint errorCellPaint   = paintingSpecs.errorCellPaint;
    Paint thinLinePaint    = paintingSpecs.thinLinePaint;
    Paint boldLinePaint    = paintingSpecs.boldLinePaint;
    Paint highlight        = paintingSpecs.highlight;

    // Paint the background of the canvas.
    ////////// canvas.drawRect(const Offset(0, 0) & size, backgroundPaint);

    paintingSpecs.calculateScale();

    double sc     = paintingSpecs.scale;
    double diam   = paintingSpecs.diameter * sc;
    Offset origin = paintingSpecs.origin;

    paintingSpecs.add3DViewControls(canvas);

    paintingSpecs.paintPuzzleControls(canvas, nControls, thinLinePaint,
                  boldLinePaint, puzzle.notesMode, puzzle.selectedControl);

    highlight.strokeWidth = diam * paintingSpecs.highlightInset;

    int nCircles  = paintingSpecs.rotated.length;
// TODO - Bug. If whole puzzle is rotated, highlight reappears on WRONG CELL.
//             Need to find the sphere that has the correct id.
    int highlightedCell = puzzle.selectedCell ?? -1;
    for (int n = 0; n < nCircles; n++) {
      if (! paintingSpecs.rotated[n].used) {
        continue;			// Don't paint UNUSED cells.
      }

      // Scale the XY co-ordinates and reverse the Y-axis for 2D display.
      Offset centre = paintingSpecs.rotatedXY(n).scale(sc, -sc) + origin;

      // Set the main colour for this sphere. The order of priority
      // is ERROR, SPECIAL, GIVEN and then Normal.
      int id = paintingSpecs.rotated[n].id;
      int status = puzzle.cellStatus[id];

      Paint cellPaint = innerSpherePaint;	// Normal colour.
      if (status == ERROR) {
        cellPaint = errorCellPaint;		// ERROR colour.
      }
      else if (paintingSpecs.cellBackG[id] == SPECIAL) {
        cellPaint = specialCellPaint;		// Enhanced visibility colour.
      }
      else if (status == GIVEN) {
        cellPaint = givenCellPaint;		// Colour for GIVEN cells.
      }

      Rect r = Rect.fromCenter(center: centre, width: diam, height: diam);
      List<Color> shaderColors = [cellPaint.color, outerSpherePaint.color];
      RadialGradient rg = RadialGradient(radius: 0.6, colors: shaderColors);
      Shader shader = rg.createShader(r);
      Paint circleGradient = Paint();
      circleGradient.shader = shader;
      // TODO - Rethink this. Use Canvas.drawCircle(centre, radius, paint).
      canvas.drawOval(r, circleGradient);
      canvas.drawOval(r, boldLinePaint);
      // Highlight the selected sphere.
      if (id == highlightedCell) {
        canvas.drawOval(r, highlight);
      }

      // Scale and paint the symbols on this sphere, if any.
      int ns = puzzle.stateOfPlay[id];
      // Offset cellPos = centre - Offset(diam/2.0, diam/2.0);
      Offset cellPos = centre - Offset(diam * 0.4, diam * 0.4);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                diam * 0.8, isNote: (ns > 1024), isCell: true);
    } // End list of circles.
  
    // Display the time taken so far for solving the puzzle.
    // double topLeftX = paintingSpecs.puzzleRect.left;
    // double topLeftY = paintingSpecs.puzzleRect.top;
    // double tSize = topLeftX < topLeftY ? topLeftX : topLeftY;
    // paintingSpecs.paintTextString(canvas, puzzle.userTimeDisplay,
                  // 0.75 * tSize, Offset(0, 0), boldLinePaint, backgroundPaint);

    return;

  } // End void paint(Canvas canvas, Size size)

  @override
  bool shouldRepaint(PuzzlePainter3D oldDelegate) {
    // print('ENTERED PuzzlePainter3D shouldRepaint()');
    return true;
  }

  @override
  // Can do everything required in _possibleHit3D().
  bool? hitTest(Offset position)
  {
    return null;
  }

} // End class PuzzlePainter3D
