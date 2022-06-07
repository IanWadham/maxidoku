import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import 'painting_specs_3d.dart';


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
    print('3D: nSymbols $nSymbols, hideNotes $hideNotes, nControls $nControls');

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
    var highlight      = Paint()	// Style for highlights.
      ..color = Colors.red.shade400
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // Now paint the background of the canvas.
    canvas.drawRect(Offset(0, 0) & size, paint1);

    paintingSpecs.add3DViewControls(canvas);

    paintingSpecs.paintPuzzleControls(canvas, nControls, thinLinePaint,
                  thickLinePaint, puzzle.notesMode, puzzle.selectedControl);

    paintingSpecs.calculateScale();

    double sc     = paintingSpecs.scale;
    double diam   = paintingSpecs.diameter * sc;
    Offset origin = paintingSpecs.origin;

    // highlight.strokeWidth = cellSide * paintingSpecs.highlightInset;
    // TODO - Use Shrinkage ... as in 2D cell-highlights.
    highlight.strokeWidth = 3.0;

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
      // Highlight the selected sphere.
      if (ID == puzzle.selectedCell) {
        canvas.drawOval(r, highlight);
      }

      // Scale and paint the symbols on this sphere, if any.
      int ns = puzzle.stateOfPlay[ID];
      // Offset cellPos = centre - Offset(diam/2.0, diam/2.0);
      Offset cellPos = centre - Offset(diam * 0.4, diam * 0.4);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                diam * 0.8, isNote: (ns > 1024), isCell: true);
    } // End list of circles.

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
