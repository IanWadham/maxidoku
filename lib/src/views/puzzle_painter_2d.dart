import 'package:flutter/material.dart';

import '../globals.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import 'painting_specs_2d.dart';


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

    bool hideNotes     = (puzzle.puzzlePlay == Play.NotStarted) ||
                         (puzzle.puzzlePlay == Play.BeingEntered);
    int  nControls     = hideNotes ? nSymbols + 1 : nSymbols + 2;
    // print('2D: nSymbols $nSymbols, hideNotes $hideNotes, nControls $nControls');

    paintingSpecs.calculatePuzzleLayout(size, hideNotes);

    topLeftX   = paintingSpecs.puzzleRect.left;
    topLeftY   = paintingSpecs.puzzleRect.top;
    topLeft    = paintingSpecs.puzzleRect.topLeft;
    cellSide   = paintingSpecs.cellSide;

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
    var cageLinePaint = Paint()		// Style for lines around cages.
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    // TODO - Paint Notes a little higher: bottom row clear of cage-lines.
    //        Make circles a bit smaller on Givens and Error cells (gradient?).
    //        Paint Symbols a little higher within the circles.

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSide / 30.0;
    cageLinePaint.strokeWidth  = cellSide / 20.0;
    thickLinePaint.strokeWidth = cellSide / 15.0;
    paintingSpecs.highlight.strokeWidth =
                                 cellSide * paintingSpecs.highlightInset;

    // Now paint the background of the canvas.
    canvas.drawRect(Offset(0, 0) & size, paint1);

    // Paint the backgrounds of puzzle-cells, as required by the puzzle-type.
    int nCells   = sizeX * sizeY;
    double gap = 0.0;
    double o1, o2;
    // TODO - Think about using a gradient in cell-painting, as opposed to gaps.
    for (int i = 0; i < nCells; i++) {
      o1 = topLeftX + gap/2.0 + (i~/sizeY) * cellSide;
      o2 = topLeftY + gap/2.0 + (i %sizeY) * cellSide;
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
        canvas.drawRect(Offset(o1,o2) & Size(cellSide - gap, cellSide - gap),
                        cellPaint);
      }
    }

    // Draw light and dark edges of puzzle-area, as required by the puzzle type.
    int nEdges   = sizeY * (sizeX + 1);
    for (int i = 0; i < nEdges; i++) {
      double o1 = topLeftX + (i~/(sizeY + 1)) * cellSide;
      double o2 = topLeftY + (i%(sizeY + 1))  * cellSide;
      int paintType = paintingSpecs.edgesEW[i];
      if (paintType > 0) {
        Paint p = (paintType == 1) ? thinLinePaint : thickLinePaint;
        canvas.drawLine(Offset(o1, o2), Offset(o1 + cellSide, o2), p);
      }
      o1 = topLeftX + (i~/sizeY) * cellSide;
      o2 = topLeftY + (i%sizeY)  * cellSide;
      paintType = paintingSpecs.edgesNS[i];
      if (paintType > 0) {
        Paint p = (paintType == 1) ? thinLinePaint : thickLinePaint;
        canvas.drawLine(Offset(o1, o2), Offset(o1, o2 + cellSide), p);
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
        gap = cellSide / 8.0;		// TODO - Set this in a better place.
        o1 = topLeftX + gap/2.0 + (pos~/sizeY) * cellSide;
        o2 = topLeftY + gap/2.0 + (pos %sizeY) * cellSide;
        List<Color> shaderColors = [cellPaint.color, Color(0x00FFFFFF)];
        RadialGradient rg = RadialGradient(radius: 1.1, colors: shaderColors);
        Rect r = Offset(o1, o2) & Size(cellSide - gap, cellSide - gap);
        Shader shader = rg.createShader(r);
        Paint p = Paint();
        p.shader = shader;
        // TODO - Rethink this. Use Canvas.drawCircle(centre, radius, paint).
        canvas.drawOval(r, p);
      }
      int i = puzzle.puzzleMap.cellPosX(pos);
      int j = puzzle.puzzleMap.cellPosY(pos);
      cellPos = Offset(topLeftX, topLeftY) + Offset(i * cellSide, j * cellSide);
      paintingSpecs.paintSymbol(canvas, ns, cellPos,
                cellSide, isNote: (ns > 1024), isCell: true);
      if (pos == puzzle.selectedCell) {
        hilitePos = cellPos;		// Paint hilite last, on top of cages.
      }
    }

    // In Mathdoku or Killer Sudoku, paint the outlines and labels of the cages.
    if (puzzle.puzzleMap.cageCount() > 0) {
      paintCages(canvas, puzzle.puzzleMap.cageCount(),
                paint3, paint2, cageLinePaint);
    }

    // Paint the highlight of the last puzzle-cell hit.
    double shrinkBy = cellSide / 10.0;
    double inset = shrinkBy / 2.0;
    canvas.drawRect(hilitePos + Offset(inset, inset) &
                    Size(cellSide - shrinkBy, cellSide - shrinkBy),
                    paintingSpecs.highlight);

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

// TODO - Phase these OUT.
double cellSide    = 10.0;
double controlSize = 10.0;
double topLeftX    = 10.0;
double topLeftY    = 10.0;
