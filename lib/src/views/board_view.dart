import 'package:flutter/material.dart';

import 'board_grid_view.dart';
import 'cell_view.dart';

import '../models/puzzle_map.dart';

// TODO - This only going to work on a 2D board.

class BoardView2D extends StatefulWidget
{
  const BoardView2D(this.n, this.f, {Key? key})
        : super(key: key);

  final int n;
  final double f;

  @override
  State<BoardView2D> createState() => _BoardState2D();
  
} // End class BoardView

class _BoardState2D extends State<BoardView2D>
{
  @override
  Widget build(BuildContext context)
  {
    return AspectRatio(
      aspectRatio: 1.0,
      // A Stack widget arranges its children to fit the space available.
      child: Stack(
        fit: StackFit.expand,
        children: [
          // BoardGridView(puzzleMap: widget.puzzleMap),
          Column(
            children: [
              for (int y = 0; y < widget.n; y++)
                Expanded(
                  child: Row(
                    children: [
                      for (int x = 0; x < widget.n; x++)
                        Expanded(
                          child: CellView(x, y, widget.f),
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
