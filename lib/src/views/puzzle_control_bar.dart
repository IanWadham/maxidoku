import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';	// TODO - Add symbol-text proportions (0.7 etc)i
import '../settings/game_theme.dart';
import '../models/puzzle.dart';

import 'symbol_view.dart';

// import '../models/puzzle_map.dart';

class PuzzleControlBar extends StatelessWidget
{
  final double controlSide;
  final int    nSymbols;
  final bool   horizontal;

  // TODO - Need text-height ratio(s) (0.7, etc.) in globals.dart.
  //        Need to get colours (3) and notesEnabled (from Puzzle) providers.
  PuzzleControlBar(this.controlSide, this.nSymbols,
                   {required this.horizontal, Key? key})
        : super(key: key);

  late PuzzlePlayer _puzzlePlayer;

  @override
  Widget build(BuildContext context)
  {
    int    nCells   = nSymbols + 2; // TODO - Dep. on Play/Enter/more(?).
    double cellSide = controlSide;
    String symbols  = (nSymbols < 10) ? digits : letters;

    _puzzlePlayer = context.read<PuzzlePlayer>();
    GameTheme gameTheme  = context.read<GameTheme>();

    Color cellBackground = gameTheme.emptyCellColor;
    Color textColour     = gameTheme.boldLineColor;
    Color cellDivider    = gameTheme.thinLineColor;
    Color controlsFrame  = gameTheme.boldLineColor;

    List<Positioned> controls = [];
    Offset topLeft = Offset.zero;
    Offset bottomRight = Offset(cellSide, cellSide);
    double fontHeight = 0.6 * cellSide;
    Gradient? cellGradient = null;
/*
    // Add a frame to go around all the controls.
    // TODO - If added to Stack, this seems to disable Gestures and onTap().
    Rect allControls = Rect.fromPoints(Offset.zero, bottomRight);
    controls.add(
      Positioned.fromRect(
        rect: allControls,
        child: ControlGridView(cellSide, nCells, horizontal),
      ),
    );
*/
    Offset inset = Offset(4.0, 4.0);
    print('NCELLS = $nCells');
    int firstSymbol = nCells <= 11 ? 0 : 9;	// Start at A for bigger boards.
    for (int n = 0; n < nCells; n++) {
      Rect r = Rect.fromPoints(topLeft + inset, bottomRight - inset);
      controls.add(
        Positioned.fromRect(
          rect:  r,
          child: GestureDetector(
            onTap: () { handleTap(n); },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:    cellBackground,
                gradient: cellGradient,	// None, GIVEN or ERROR.
/* TODO - Probably better to use a CustomPainter for this and the frame below.
                border: Border(
                  bottom: BorderSide(width: 1.0, color: cellDivider),
                ),
*/
              ),
              position: DecorationPosition.background,
              child: Align (alignment: Alignment.center,
                child: Text(
                  n < 2 ? '' : symbols[firstSymbol + n - 1],
                  style: TextStyle(
                    fontSize:   fontHeight,
                    fontWeight: FontWeight.bold,
                    color:      textColour,
                  ),
                ),
              ),
            ), // End DecoratedBox().
          ), // End GestureDetector().
        ), // End Positioned().
      );
      topLeft = horizontal ? topLeft = topLeft + Offset(cellSide, 0.0)
                                  : topLeft = topLeft + Offset(0.0, cellSide); 
      bottomRight = topLeft + Offset(cellSide, cellSide);
    }
/*
    // Add a frame to go around all the controls.
    // TODO - If added to Stack, this seems to disable Gestures and onTap().
    // TODO - Put all the controls in their own Stack. Enclose that Stack
    //        with another Stack to which the frame and dividers are added.
    Rect allControls = Rect.fromPoints(Offset.zero, bottomRight);
    controls.add( // BAD
      Positioned.fromRect(
        rect: allControls,
        child: ControlGridView(cellSide, nCells, horizontal),
      ),
    );
*/
    Rect allControls = Rect.fromPoints(Offset.zero, bottomRight);
    return SizedBox(
      width:  horizontal ? nCells * cellSide : cellSide,
      height: horizontal ? cellSide          : nCells * cellSide,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect:  allControls,
            child: ControlGridView(cellSide, nCells, horizontal),
          ),
          // Positioned.fromRect(
          /* rect:  allControls,
          child: */ Stack(
            children:
              controls,
          ),
          // ),
        ],
      ),
    );
  } // End Widget build().

  // TODO - Note cells can be hard to tap if you go and work on another cell.
  //        When you come back to the Note cell, it will not respond to a tap
  //        unless you hit one of the tiny Note widgets.

  void handleTap(int n)
  {
    // TODO - Link up with the Puzzle model.
    print('Handle tap on control cell $n');
    _puzzlePlayer.hitControlArea(n);
  }

} // End class PuzzleControlBar.

class ControlGridView extends StatelessWidget
{
  // Provides the frame and dividers in a Multidoku control bar.
  final double cellSide;
  final int    nCells;
  final bool   horizontal;

  ControlGridView(this.cellSide, this.nCells, this.horizontal);

  @override
  Widget build(BuildContext context)
  {
    final gameTheme = context.watch<GameTheme>();
    return RepaintBoundary(
      child: CustomPaint(
        painter: ControlGridPainter(cellSide, nCells, horizontal,
                                    gameTheme.thinLineColor,
                                    gameTheme.boldLineColor),
      ),
    );
  }

}

class ControlGridPainter extends CustomPainter
{
  final double cellSide;
  final int    nCells;
  final bool   horizontal;
  final Color  thinLineColor;
  final Color  boldLineColor;

  ControlGridPainter(this.cellSide, this.nCells, this.horizontal,
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

    // Calculated widths of lines, depending on canvas size and puzzle size.
    thinLinePaint.strokeWidth  = cellSide / 30.0;
    boldLinePaint.strokeWidth  = cellSide / 15.0;
    print('Canvas size $size, thin ${thinLinePaint.strokeWidth} thick ${boldLinePaint.strokeWidth}');

    // WILL BE NEEDED LATER...
    // highlight.strokeWidth      = cellSide * paintingSpecs.highlightInset;

    // Paint dividers between cells.
    for (int n = 1; n < nCells; n++) {
      double pos = cellSide * n;
      Offset start = horizontal ? Offset(pos, 0.0) : Offset(0.0, pos);
      Offset end   = horizontal ? Offset(pos, cellSide) : Offset(cellSide, pos);
      canvas.drawLine(start, end, thinLinePaint);
    }

    // Paint surrounding frame.
    Rect r = Offset.zero & size;
    print('Rect $r');
    // r = r.deflate(cellSide / 30.0);
    r = r.inflate(cellSide / 10.0);
    print('Inflated Rect $r');
    canvas.drawRect(r, boldLinePaint);
  }

  @override
  bool shouldRepaint(ControlGridPainter oldDelegate)
  {
    return false;
  }
}
