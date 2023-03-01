import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/game_theme.dart';

// Paint a "sphere" widget, for use in 3D MultiDoku puzzles.
//
// When painted, it is enclosed in a Positioned widget of the same size and
// a list of positioned RoundCellViews is then painted as children of a Stack
// widget. The result is seen as a loose 3D array of tap-sensitive spheres.

class RoundCellView extends StatelessWidget
{
  // const RoundCellView(this.id, this.centre, this.diameter);
  const RoundCellView(this.id);

  // Keep the PuzzleMap index: the cell-list gets re-ordered after 3D rotations.
  final int id;

  @override
  build(BuildContext context) {
    GameTheme gameTheme = context.read<GameTheme>();

    return GestureDetector(
      onTap: () {
        // TODO - Need to handle taps... Need to display symbols...
        debugPrint('Tapped sphere $id.');
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
              gameTheme.outerSphereColor,
            ],
            stops: <double>[0.2, 1.0],	// Shades circle, bright spot in centre.
            tileMode: TileMode.decal,	// Use transparency after circle-edge.
            // Default TileMode.clamp fills rest of rect box with second color.
          ),
        ), // End ShapeDecoration.
      ), // End DecoratedBox.
    ); // End GestureDetector.
  }
} // End RoundCellView class.
