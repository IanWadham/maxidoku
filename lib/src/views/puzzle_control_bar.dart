/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../settings/game_theme.dart';
import '../models/puzzle_map.dart';		// IS needed ??????

import 'symbol_view.dart';

class PuzzleControlBar extends StatelessWidget
{
  final double    boardSide;
  final double    controlSide;
  final PuzzleMap map;
  final bool      horizontal;
  final bool      hideNotes;

  PuzzleControlBar(this.boardSide, this.controlSide, this.map,
                   {required this.horizontal,
                    required this.hideNotes,
                    Key? key})
        : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    int    nSymbols = map.nSymbols;
    int    nCells   = hideNotes ? nSymbols + 1 : nSymbols + 2;
    double cellSide = controlSide;

    GameTheme gameTheme   = context.read<GameTheme>();

    Color backgroundColor = gameTheme.emptyCellColor;
    Color thinLineColor   = gameTheme.thinLineColor;
    Color boldLineColor   = gameTheme.boldLineColor;

    List<Positioned> controls = [];
    Offset topLeft = Offset.zero;
    Offset bottomRight = Offset.zero;
    double fontHeight = symbolFraction * cellSide;
    Gradient? cellGradient = null;

    debugPrint('BUILD PuzzleControlBar: nCells $nCells hideNotes $hideNotes');

    // Controls are: Notes 1 2 3 (optional), 0 (delete), symbols 1 to nSymbols.
    List<int> controlValues = hideNotes ? [] : [NotesBit + 0xE];
    for (int n = 0; n <= nSymbols; n++) {
      controlValues.add(n);
    }

    // Make a list of Positioned SymbolView widgets from the controlValues list.
    int index = 0;
    for (int controlValue in controlValues) {
      bottomRight = topLeft + Offset(cellSide, cellSide);
      Rect r = Rect.fromPoints(topLeft, bottomRight);
      controls.add(
        Positioned.fromRect(
          rect:  r,
          child: SymbolView('Control', map, index, cellSide,
            value: controlValue,
          ),
        ),
      );
      topLeft = horizontal ? topLeft + Offset(cellSide, 0.0)
                           : topLeft + Offset(0.0, cellSide); 
      index++;
    }

    return SizedBox(
      width:  bottomRight.dx,
      height: bottomRight.dy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: ControlGridPainter(cellSide, nCells, horizontal,
                                          hideNotes, backgroundColor,
                                          thinLineColor, boldLineColor),
            ),
          ),
          Stack(
            children:
              controls,
          ),
        ],
      ),
    );
  } // End Widget build().

} // End class PuzzleControlBar.

class ControlGridPainter extends CustomPainter
{
  final double cellSide;
  final int    nCells;
  final bool   horizontal;
  final bool   hideNotes;
  final Color  backgroundColor;
  final Color  thinLineColor;
  final Color  boldLineColor;

  ControlGridPainter(this.cellSide, this.nCells, this.horizontal,
                     this.hideNotes, this.backgroundColor,
                     this.thinLineColor, this.boldLineColor);

  @override
  void paint(Canvas canvas, Size size)
  {
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
    Paint backgroundPaint = Paint()	// Background paint of control bar.
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Calculated widths of lines (must be same as in puzzle board).
    int nonSymbols = hideNotes ? 1 : 2;	// (nCells - nonSymbols) == nSymbols.
    double puzzleCellSide      = size.longestSide / (nCells - nonSymbols);
    thinLinePaint.strokeWidth  = puzzleCellSide / thinGridFactor;
    boldLinePaint.strokeWidth  = puzzleCellSide / boldGridFactor;

    Rect r = Offset.zero & size;

    // Paint background of control bar.
    canvas.drawRect(r, backgroundPaint);

    // Paint dividers between cells.
    for (int n = 1; n < nCells; n++) {
      double pos = cellSide * n;
      Offset start = horizontal ? Offset(pos, 0.0) : Offset(0.0, pos);
      Offset end   = horizontal ? Offset(pos, cellSide) : Offset(cellSide, pos);
      canvas.drawLine(start, end, thinLinePaint);
    }

    // Paint surrounding frame.
    canvas.drawRect(r, boldLinePaint);
  }

  @override
  bool shouldRepaint(ControlGridPainter oldDelegate)
  {
    return false;
  }
}  // End class ControlGridPainter.
