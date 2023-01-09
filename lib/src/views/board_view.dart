import 'package:flutter/material.dart';

import 'board_grid_view.dart';
import 'cell_view.dart';

import '../models/puzzle_map.dart';

class BoardView extends StatefulWidget
{
  const BoardView({Key? key, required this.puzzleMap})
        : super(key: key);

  final PuzzleMap puzzleMap;

  @override
  State<BoardView> createState() => _BoardState();
  
} // End class BoardView

class _BoardState extends State<BoardView>
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
          BoardGridView(puzzleMap: widget.puzzleMap),
          Column(
            children: [
              for (int y = 0; y < widget.puzzleMap.sizeY; y++)
                Expanded(
                  child: Row(
                    children: [
                      for (int x = 0; x < widget.puzzleMap.sizeX; x++)
                        Expanded(
                          child: CellView(x, y),
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
} // End class _BoardState
