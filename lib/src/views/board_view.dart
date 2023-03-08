import 'package:flutter/material.dart';

// import '../globals.dart';
import 'board_grid_view.dart';
import 'cell_view.dart';

import '../models/puzzle_map.dart';

class BoardView2D extends StatefulWidget
{
  const BoardView2D(this._map, this.cellBackground, this.f, {Key? key})
        : super(key: key);

  final PuzzleMap _map;
  final double f;
  final List<int> cellBackground;

  @override
  State<BoardView2D> createState() => _BoardState2D();
  
} // End class BoardView

class _BoardState2D extends State<BoardView2D>
{
  @override
  Widget build(BuildContext context)
  {
    PuzzleMap map = widget._map;
    int n = map.sizeY;
    return AspectRatio(
      aspectRatio: 1.0,
      // A Stack widget arranges its children to fit the space available.
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              for (int y = 0; y < n; y++)
                Expanded(
                  child: Row(
                    children: [
                      for (int x = 0; x < n; x++)
                        Expanded(
                          child: CellView(
                                   x, y,
                                   map.cellIndex(x, y),
                                   widget.cellBackground[map.cellIndex(x, y)],
                                   widget.f),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  } // End Widget build
} // End class _BoardState2D
