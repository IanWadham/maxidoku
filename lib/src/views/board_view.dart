import 'package:flutter/material.dart';

import 'board_grid_view.dart';
import 'symbol_view.dart';

import '../models/puzzle_map.dart';

class BoardView2D extends StatelessWidget
{
  const BoardView2D(this._map, this._cellSide, {Key? key})
        : super(key: key);

  final PuzzleMap _map;
  final double    _cellSide;	// Height and width of each cell.

  @override
  Widget build(BuildContext context)
  {
    // PuzzleMap map = _map;
    int sizeY = _map.sizeY;
    int sizeX = _map.sizeX;
    int index = 0;

    debugPrint('BoardView2D: Paint $sizeX x $sizeY cells, cellSide $_cellSide.');
    return AspectRatio(
      aspectRatio: 1.0,
      // This Stack arranges its children to fit a grid in the space available.
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              for (int x = 0; x < sizeX; x++)
                Expanded(
                  child: Column(
                    // In Maxidoku cells go into the grid a column at a time.
                    children: [
                      // So Y varies faster than X in this convention.
                      for (int y = 0; y < sizeY; y++)
                        Expanded(
                          child: SymbolView('2D', _map, index++, _cellSide),
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
