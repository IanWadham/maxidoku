import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';	// TODO - Add symbol-text proportions (0.7 etc)i
import '../settings/game_theme.dart';

// import 'cell_view.dart';

// import '../models/puzzle_map.dart';

class PuzzleControlBar extends StatefulWidget
{
  final double controlSide;
  final int    nSymbols;
  final bool   horizontal;

  // TODO - Need text-height ratio(s) (0.7, etc.) in globals.dart.
  //        Need to get colours (3) and notesEnabled (from Puzzle) providers.
  const PuzzleControlBar(this.controlSide, this.nSymbols,
                         {required this.horizontal, Key? key})
        : super(key: key);

  @override
  State<PuzzleControlBar> createState() => _ControlBarState();
  
} // End class PuzzleControlBar.

class _ControlBarState extends State<PuzzleControlBar>
{
  @override
  Widget build(BuildContext context)
  {
    int    nCells   = widget.nSymbols + 2; // TODO - Dep. on Play/Enter/more(?).
    double cellSide = widget.controlSide;
    String symbols  = '.123456789ABCDEFGHIJKLMNOP';

    GameTheme gameTheme = context.read<GameTheme>();
    Color cellBackground = gameTheme.emptyCellColor;
    Color cellDivider = gameTheme.thinLineColor;
    Color controlsFrame = gameTheme.boldLineColor;

    List<Positioned> controls = [];
    Offset topLeft = Offset.zero;
    Offset bottomRight = Offset(cellSide, cellSide);
    double fontHeight = 0.6 * cellSide;
    Gradient? cellGradient = null;

    for (int n = 0; n < nCells; n++) {
      Rect r = Rect.fromPoints(topLeft, bottomRight);
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
                  n < 2 ? '' : symbols[n - 1],
                  style: TextStyle(
                    fontSize: fontHeight, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ), // End DecoratedBox().
          ), // End GestureDetector().
        ), // End Positioned().
      );
      topLeft = widget.horizontal ? topLeft = topLeft + Offset(cellSide, 0.0)
                                  : topLeft = topLeft + Offset(0.0, cellSide); 
      bottomRight = topLeft + Offset(cellSide, cellSide);
    }
/*
    // Add a frame to go around all the controls.
    // TODO - If added to Stack, this seems to disable Gestures and onTap().
    Rect allControls = Rect.fromPoints(Offset.zero, bottomRight);
    controls.add(
      Positioned.fromRect(
        rect: allControls,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(width: 4.0, color: controlsFrame),
          ),
        ),
      ),
    );
*/
    return SizedBox(
      width:  widget.horizontal ? nCells * cellSide : cellSide,
      height: widget.horizontal ? cellSide          : nCells * cellSide,
      child: Stack(
        // TODO - Draw nCells coloured boxes, draw border rect, add symbols.
        //        Add cursor, Positioned but able to change its position to
        //        go to whatever cell is tapped (and update the model). 
        children: controls,
      ),
    );
  } // End Widget build().

  void handleTap(int n)
  {
    // TODO - Link up with the Puzzle model.
    print('Handle tap on control cell $n');
  }

} // End class _BoardState2D.
