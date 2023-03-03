import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../globals.dart';
import '../models/puzzle.dart';		// TODO - Testing ONLY?...
import '../models/puzzle_map.dart';
import '../settings/game_theme.dart';

class CellView extends StatefulWidget
// class CellView extends StatelessWidget
{
  final int x;			// X-coordinate.
  final int y;			// Y-coordinate.
  final int index;              // Index in lists of Puzzle board contents.
  final int cellBg;		// Cell's appearance when empty.
  final double f;		// Font height.

  // int _cellValue = 0;
  // int _cellStatus = VACANT;

  const CellView(this.x, this.y, this.index, this.cellBg, this.f, {Key? key})
      : super(key: key);

  @override
  State<CellView> createState() => _CellViewState();

} // End class CellView

class _CellViewState extends State<CellView>
{
  int _cellValue = 0;
  int _cellStatus = VACANT;

  @override
  // TODO - How to to turn on highlight and turn off OLD Cell highlight.
  // TODO - How to draw various types of Cell, including unusable, Given, normal
  //        symbol and Notes symbols.
  // TODO - 0.7 factor in fontHeight should be a symbolic constant.
  // TODO - Might be easier to pass TextStyle as a pre-computed parameter.

  Widget build(BuildContext context)
  {
    debugPrint('Building CELL ${widget.x},${widget.y}');
    // Puzzle puzzle = context.read<Puzzle>();

        GameTheme gameTheme = context.read<GameTheme>();

// TODO - There could probably be a SymbolWidget that takes care of much of
//        this, as well as displaying Notes values, control-bar cells and
//        the content of spheres in 3D puzzles. Control-bar cells would have to
//        have NULL Gradients. Control-cell zero could be passes Notes 1 2 3...

        if (widget.cellBg == UNUSABLE) {
          // Hold an empty spot in the grid with no onPressed (e.g. in Samurai).
          return FittedBox(
            fit: BoxFit.fill,
          );
        }
        else {
          // Add a live, tappable spot to the 2D Sudoku grid.
          Color  cellBackground = widget.cellBg == SPECIAL ?
                                  gameTheme.specialCellColor :
                                  gameTheme.emptyCellColor;
          Color  textColour     = gameTheme.boldLineColor;
          double fontHeight     = widget.f;

          Gradient? cellGradient = null;

          switch(_cellStatus) {
            case GIVEN:
            case ERROR:
              Color cellEmphasis = (_cellStatus == GIVEN) ?
                                   gameTheme.givenCellColor :
                                   gameTheme.errorCellColor;
              cellGradient =
                RadialGradient(
                center: Alignment.center,
                radius: 0.5,			// Half width or height of box.
                colors: <Color>[
                  cellEmphasis,
                  cellBackground,
                ],
                stops: <double>[0.0, 1.0],	// Colour centre of cell.
                tileMode: TileMode.clamp,	// Fill rest with cellBg colour.
              );
              break;
            default:		// UNUSABLE, VACANT or CORRECT.
              break;		// No gradient.
          }

          return AspectRatio(
            aspectRatio: 1.0,
            child: GestureDetector(
              onTap: () {
                // TODO - The Puzzle context is OK for now, but should use
                //        something more limited in scope and lower in the tree.
                debugPrint('Tapped cell ${widget.x}, ${widget.y}');
                Puzzle puzzle = context.read<Puzzle>();
                setState(() {
                _cellValue = puzzle.solution[widget.index];
                _cellStatus = puzzle.cellStatus[widget.index];
                print('_cellValue $_cellValue _cellStatus $_cellStatus'); });
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:    cellBackground,
                  gradient: cellGradient,	// None, GIVEN or ERROR.
                ),
                position: DecorationPosition.background,
                child: Align (alignment: Alignment.center,
                  child: Text(
                  _cellValue == 0 ? '' : _cellValue.toString(),
                  // textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   fontHeight,
                    fontWeight: FontWeight.bold,
                    color:      textColour,
                  ),
                  ),
                ), // ),
              ),
            ),
          );
        }
      // }
    // );
  } // End Widget build

} // End class _CellViewState
