import 'package:flutter/material.dart';

import '../models/puzzle_map.dart';

class BoardGridView extends StatefulWidget
{
  // Provides the lines on a Sudoku-type Puzzle grid.
  final PuzzleMap puzzleMap;

  const BoardGridView({Key? key, required this.puzzleMap})
      : super(key: key);

  @override
  State<BoardGridView> createState() => _BoardGridState();
}

class _BoardGridState extends State<BoardGridView>
{
  @override
  Widget build(BuildContext context)
  {
    // TODO - Construct a widget and return it.
    return Text(' ');
  } // End Widget build
} // End class _BoardGridState
