      // Draw a "sphere" widget, for use in 3D MultiDoku puzzles.
      // TODO - How to paint a 3x3x3  array of these widgets on a board widgwt.
      //        ***** Use a Stack for the whole board, have Positioned widgets
      //              of any size at any position. Give the Positioned widget
      //              all this stuff as contents, defined as a StatelessWidget.
      //              Get the Sizes and Centres from Puzzle3D model.

import 'package:flutter/material.dart';

class RoundCellView extends StatelessWidget
{
  // const RoundCellView(this.id, this.centre, this.diameter);
  const RoundCellView(this.id);

  final int    id;	// Keep PuzzleMap index: cell list gets shuffled.
  // final Offset centre;
  // final double diameter;

  @override
  build(BuildContext context) {
    // return Positioned.fromRect(
      // rect: Rect.fromCenter(
        // center: centre,
        // width:  diameter,
        // height: diameter,
      // ),
      // child: DecoratedBox(
      return DecoratedBox(
        decoration: ShapeDecoration(	// Decorate a box of ANY shape.
          shape: CircleBorder(	// Shows outline of circular box.
            side: BorderSide(
              width: 1,
              color: Colors.brown.shade400,
            ), 
          ),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,		// Diameter = width or height of box.
            colors: <Color>[
              // background		// Multidoku puzzle background colour.
              Colors.amber.shade100,	// Multidoku puzzle background colour.
              Colors.amber.shade300,	// MultiDoku 3D puzzle cell colour.
            ],
            stops: <double>[0.2, 1.0],// Shades circle, bright spot in centre.
            tileMode: TileMode.decal,	// Leaves transparency after stop 1.0.
            // Default TileMode.clamp fills rest of rect box with 2nd color.
          ),
        ),
      ); 
    // );
  }
}
