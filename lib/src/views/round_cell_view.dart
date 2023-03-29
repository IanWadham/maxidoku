import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/game_theme.dart';
import '../models/puzzle.dart';
import '../models/puzzle_map.dart';

import 'symbol_view.dart';

// Paint a "sphere" widget, for use in 3D MultiDoku puzzles.
//
// When painted, it is enclosed in a Positioned widget of the same size and
// a list of positioned RoundCellViews is then painted as children of a Stack
// widget. The result is seen as a loose 3D array of tap-sensitive spheres.

class RoundCellView extends StatelessWidget
{
  // const RoundCellView(this.index, this.centre, this.diameter);
  const RoundCellView(this.index, this.diameter);

  // Keep the PuzzleMap index: the cell-list gets re-ordered after 3D rotations.
  final int    index;
  final double diameter;

  @override
  build(BuildContext context) {
    GameTheme gameTheme = context.read<GameTheme>();
    Puzzle puzzle = context.read<Puzzle>();
    PuzzleMap map = puzzle.puzzleMap;
    Color outerCellColor = map.specialCells.contains(index) ?
                           gameTheme.specialCellColor :
                           gameTheme.outerSphereColor;

    return GestureDetector(
// TODO - Don't need onTap() here: SymbolView does it. DO NEED A TRUE CIRCULAR
//        TARGET... This one does NOT fire anyway. The one in SymbolView DOES.
// TODO - Taps on circles (spheres) are clipped PROPERLY here, but not in
//        SymbolView, where each circle is treated as a SQUARE for tapping...
      onTap: () {
        // TODO - Need to handle taps... Need to display symbols... ????
        debugPrint('Tapped sphere $index.');
      },
      child: DecoratedBox(
        decoration: ShapeDecoration(	// Decorate a box of ANY shape.
          shape: CircleBorder(		// Show outline of circular box.
            side: BorderSide(
              width: 1,			// TODO - Fixed or dep. on sphere size?
              color: gameTheme.thinLineColor,
              // width: 2,		// TODO - How to do the circular cursor?
              // color: Colors.red,
            ), 
          ),
          // Flutter's Gradient parameters are fractions of the Box/Circle size.
          gradient: RadialGradient(	// Shade a circle to look like a sphere.
            center: Alignment.center,
            radius: 0.5,		// Diameter = width or height of box.
            colors: <Color>[
              gameTheme.innerSphereColor,
              // ?????? gameTheme.outerSphereColor,
              outerCellColor,
            ],
            stops: <double>[0.2, 1.0],	// Shades circle, bright spot in centre.
            tileMode: TileMode.decal,	// Use transparency after circle-edge.
            // Default TileMode.clamp fills rest of rect box with second color.
          ),
        ), // End ShapeDecoration.
        child: SymbolView('3D', map, index, diameter),
      ), // End DecoratedBox.

    ); // End GestureDetector.
  }
} // End RoundCellView class.
