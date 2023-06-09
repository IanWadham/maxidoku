/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';

import '../models/puzzle.dart';
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

class BoardGridView2D extends StatelessWidget
{
  // Provides the lines on a Sudoku-type 2D Puzzle grid.
  final PuzzleMap puzzleMap;
  final double    boardSide;

  BoardGridView2D(this.boardSide, {Key? key, required this.puzzleMap})
      : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    final gameTheme = context.watch<GameTheme>();
    final puzzle    = context.read<Puzzle>();
    final _hasCages = puzzle.cagePerimeters.isNotEmpty;

    debugPrint('BUILD BoardGridView2D, hasCages $_hasCages,'
               ' hasNewCages ${puzzle.hasNewCages}');

    // RepaintBoundary seems to be essential to stop GridPainter re-painting
    // continually whenever a cell or icon is tapped and the grid is unchanged.
    // It also stops GridPainter re-painting whenever the pointer moves out of
    // the Puzzle's desktop window (as observed on an Apple MacOS machine).

    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: GridPainter(puzzleMap, boardSide, puzzle.cellColorCodes,
                       puzzle.edgesEW, puzzle.edgesNS,
                       gameTheme.thinLineColor, gameTheme.boldLineColor,
                       gameTheme.emptyCellColor, gameTheme.specialCellColor,
            ),
          ),
        ),

        // Paint cages if there are any (for Mathdoku and Killer Sudoku only).
        Visibility(
          visible: _hasCages,
          child: RepaintBoundary(
            child: CageOverlay(puzzle, boardSide, gameTheme),
          ),
        ),
      ],
    );

  } // End Widget build

} // End class BoardGridView2D

class GridPainter extends CustomPainter
{

  GridPainter(this.puzzleMap, this.boardSide, this.cellColorCodes,
              this.edgesEW, this.edgesNS,
              this.thinLineColor, this.boldLineColor,
              this.emptyCellColor, this.specialCellColor);

  final PuzzleMap puzzleMap;
  final double    boardSide;
  final List<int> cellColorCodes;
  final List<int> edgesEW;
  final List<int> edgesNS;
  final Color     thinLineColor;
  final Color     boldLineColor;
  final Color     emptyCellColor;
  final Color     specialCellColor;

  @override
  void paint(Canvas canvas, Size size)
  {
    debugPrint('GridPainter.paint() called...');
    int sizeX       = puzzleMap.sizeX;
    int sizeY       = puzzleMap.sizeY;
    double cellSide = boardSide / sizeX;

    debugPrint('Cell side $cellSide, board side $boardSide.');

    Paint thinLinePaint = Paint()	// Style for lines between cells.
      ..color = thinLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint boldLinePaint = Paint()	// Style for symbols and group outlines.
      ..color = boldLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSide / thinGridFactor;
    boldLinePaint.strokeWidth  = cellSide / boldGridFactor;

    double oX     = 0.0;
    double oY     = 0.0;

    int boardArea = puzzleMap.size;
    for (int index = 0; index < boardArea; index++) {
      // bool isSpecial = puzzleMap.specialCells.contains(index);
      int colorCode = cellColorCodes[index];
      if (colorCode == UNUSABLE) continue;	// Don't paint.
      Color cellBackground = (colorCode == SPECIAL) ? specialCellColor
                                                    : emptyCellColor;
      Paint cellBgPaint = Paint()
      ..color = cellBackground
      ..style = PaintingStyle.fill;

      oX = (index~/sizeY) * cellSide;
      oY = (index% sizeY)  * cellSide;
      canvas.drawRect(Rect.fromLTWH(oX, oY, cellSide, cellSide), cellBgPaint);

/*    // Debugging aid for unwanted overlaps of symbols, gradients, cage
      // perimeters and grid-lines. Paints a faint 10x10 grid over each cell.
      Paint debugGrid = Paint()	// Style for lines between cells.
      ..color = thinLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0;
      double gap = cellSide / 10.0;
      for (int n = 1; n <= 9; n++)
      {
        canvas.drawLine(Offset(oX, oY + gap), Offset(oX + cellSide, oY + gap),
                        debugGrid);
        canvas.drawLine(Offset(oX + gap, oY), Offset(oX + gap, oY + cellSide),
                        debugGrid);
        gap = gap + cellSide / 10.0;
      }
// */
    }

    // Draw light and dark edges of puzzle-area, as required by the puzzle type.
    // Paint all the light edges first (edgeType 1) then all the dark edges on
    // top of them (edgeType 2), avoiding some tiny glitches where the dark and
    // light lines cross, also skipping both calculation and painting for cells
    // that are designated UNUSABLE (e.g. in Samurai-style puzzles);

    int    nEdges = sizeY * (sizeX + 1);

    for (int edgeType in [1, 2]) {	// Light first, then dark.
      Paint p = (edgeType == 1) ? thinLinePaint : boldLinePaint;
      for (int i = 0; i < nEdges; i++) {
        if (edgesEW[i] == edgeType) {
          oX = (i~/(sizeY + 1)) * cellSide;
          oY = (i%(sizeY + 1))  * cellSide;
          canvas.drawLine(Offset(oX, oY), Offset(oX + cellSide, oY), p);
        }
        if (edgesNS[i] == edgeType) {
          oX = (i~/sizeY) * cellSide;
          oY = (i%sizeY)  * cellSide;
          canvas.drawLine(Offset(oX, oY), Offset(oX, oY + cellSide), p);
        }
      }
    }
  } // End paint().

  @override
  bool shouldRepaint(GridPainter oldDelegate)
  {
    return false;
  }

} // End class GridPainter.

class CageOverlay extends StatefulWidget
{
  const CageOverlay(this.puzzle, this.boardSide, this.gameTheme);

  final Puzzle    puzzle;
  final double    boardSide;
  final GameTheme gameTheme;

  @override
  CageOverlayState createState() => CageOverlayState();
}

class CageOverlayState extends State<CageOverlay>
{
  final hasNewCages = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    final puzzle    = widget.puzzle;
    final gameTheme = widget.gameTheme;
    if (puzzle.hasNewCages) {
      this.hasNewCages.value++;
      puzzle.hasNewCages = false;
    }
    return CustomPaint(
      painter: CagePainter(puzzle, widget.boardSide, gameTheme.cageLineColor,
                 gameTheme.boldLineColor, gameTheme.emptyCellColor,
                 hasNewCages,
      ),
    );
  }
}

class CagePainter extends CustomPainter
{
  CagePainter(this.puzzle, this.boardSide, this.cageLineColor,
              this.boldLineColor, this.emptyCellColor, this.hasNewCages)
              : super(repaint: hasNewCages);

  final Puzzle              puzzle;
  final double              boardSide;
  final Color               cageLineColor;
  final Color               boldLineColor;
  final Color               emptyCellColor;
  final ValueNotifier<int>  hasNewCages;

  // A text-painter for painting Sudoku symbols on a Canvas.
  final TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center,
        maxLines: 1,
        textDirection: TextDirection.ltr);
  final double baseSize = 60.0;

  @override
  void paint(Canvas canvas, Size size)
  {
    debugPrint('CagePainter.paint() called... hasNewCages ${hasNewCages.value}');

    PuzzleMap puzzleMap = puzzle.puzzleMap;
    int sizeX           = puzzleMap.sizeX;
    double cellSide     = boardSide / sizeX;

    Paint cageLinePaint = Paint()		// Style for cage outlines.
      ..color = cageLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    Paint boldLinePaint = Paint()		// Style for cage-label text.
      ..color = boldLineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint emptyCellPaint = Paint()		// Backg. colour for cage label.
      ..color = emptyCellColor
      ..style = PaintingStyle.fill;

    cageLinePaint.strokeWidth  = cellSide / cageGridFactor;

    // In Mathdoku or Killer Sudoku, paint the outlines and labels of the cages.
    if (puzzleMap.cageCount() > 0) {
      paintCages(canvas, puzzleMap.cageCount(), cellSide,
                 boldLinePaint, cageLinePaint, emptyCellPaint);
    }
  } // End paint().

  @override
  bool shouldRepaint(CagePainter oldDelegate)
  {
    return false;
  }


  ///////////////////////////////////////////////////////////
  // Painting methods for cage boundaries and labels-text. //
  ///////////////////////////////////////////////////////////

  void paintCages(Canvas canvas, int cageCount, double cellSide,
                  Paint labelPaintFg, Paint cageLinePaint, Paint labelPaintBg)
  {
    PuzzleMap       map  = puzzle.puzzleMap;

    double inset = cellSide/cageInsetFactor;
    List<Offset> corners = [Offset(inset, inset),			// NW
                            Offset(cellSide - inset, inset),		// NE
                            Offset(cellSide - inset, cellSide - inset),	// SE
                            Offset(inset, cellSide - inset)];		// SW

    // Paint lines to connect lists of right-turn and left-turn points in cage
    // perimeters. Lines are inset within cage edges and have a special colour.
    for (List<int> perimeter in puzzle.cagePerimeters) {
      Offset? startLine;	// Initially null.
      for (Pair point in perimeter) {
        int cell          = point >> lowWidth;
        int corner        = point & lowMask;
        int i             = map.cellPosX(cell);
        int j             = map.cellPosY(cell);
        Offset cellOrigin = Offset(i * cellSide, j * cellSide);
        Offset endLine    = cellOrigin + corners[corner];
        if (startLine != null) {
          canvas.drawLine(startLine, endLine, cageLinePaint);
        }
        startLine = endLine;		// Get ready for the next line.
      }
    }

    double labelSize      = cellSide / labelTextFactor;
    TextStyle stringStyle = TextStyle(
      color:      boldLineColor,
      height:     1.0,
      fontSize:   labelSize,
      fontWeight: FontWeight.bold);

    // Paint the cage labels.
    for (int cageNum = 0; cageNum < cageCount; cageNum++) {
      if (map.cage(cageNum).length == 1) {
        // debugPrint('Single-cell cage at index ${map.cageTopLeft(cageNum)}');
        continue;	// Don't paint labels on size 1 cages (Givens/clues).
      }

      String cageLabel  = getCageLabel(map, cageNum);
      int labelCell     = map.cageTopLeft(cageNum);
      int cellX         = map.cellPosX(labelCell);
      int cellY         = map.cellPosY(labelCell);
      Offset cellOrigin = Offset(cellX * cellSide, cellY * cellSide);
      Offset labelInset = Offset(cellSide/labelInsetFactor,
                                 cellSide/labelInsetFactor);
      // debugPrint('Paint cage $cageNum label $cageLabel at $labelCell');
      paintTextString(canvas, cageLabel, stringStyle, labelSize,
                              cellOrigin + labelInset, labelPaintBg);
    }
  }

  String getCageLabel (PuzzleMap map, int cageNum)
  {
    bool killerStyle = (map.specificType == SudokuType.KillerSudoku);

    // TODO - Operators or cell-values should be randomly revealed in Hints.
    // TODO - Operators should all be revealed when a solution is reached.

    // No operator is shown in KillerSudoku, nor in Blindfold Mathdoku.
    String cLabel = map.cageValue(cageNum).toString();
    if ((! killerStyle) && (! map.hideOperators)) {
      int opNum = map.cageOperator(cageNum).index;
      cLabel = cLabel + " /-x+".substring(opNum, opNum + 1);
    }
    return cLabel;
  }

  void paintTextString(Canvas canvas, String textString, TextStyle stringStyle,
                       double labelSize, Offset offset, Paint background)
  {
    double padding = 0.25 * labelSize;

    textPainter.text = TextSpan(style: stringStyle, text: textString);
    textPainter.layout();

    Rect textRect  = Rect.fromPoints(offset, offset +
                     Offset(padding + textPainter.width, labelSize));
    canvas.drawRect(textRect, background);

    // Need padding at both ends of string, so inset by padding / 2.0;
    textPainter.paint(canvas, offset + Offset(padding / 2.0, 0.0));
  }

} // End class CagePainter.
