/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'dart:ui';
import 'package:flutter/foundation.dart' show debugPrint;

import 'dart:math';		// For matrices and vectors in 3D calculations.
import 'package:vector_math/vector_math_64.dart' hide Colors;
// import 'package:vector_math/vector_math.dart' hide Colors;

// NOTE: Flutter Material and vector_math both define Colors. Also Flutter
//       itself uses vector_math of some kind: had to use vector_math_64 or
//       we would get Matrix4 doubly-defined.
//
//       PORTABILITY ISSUE??? What happens if you are building for a device
//       that does not have 64-bit? And what is the meaning of "double" type
//       arithmetic in a 32-bit hardware environment?

import '../globals.dart';
import '../models/puzzle_map.dart';

// This code models the layout of a 3D Roxdoku puzzle as a list of Sphere
// objects in a 3D space. A sphere always projects into a circle when drawn
// on a 2D surface. So methods are provided to show the view where to place the
// required circles and how big to draw them to fit the available space.

typedef Matrix = Matrix4;
typedef Coords = Vector3;

class Sphere
{
  // A Sphere in 3D space.
  Sphere(this.index, this.used, this.xyz, this.diameter);

  final int    index;
  final bool   used;
  Coords       xyz = Coords(0.0, 0.0, 0.0);
  double       diameter = 2.0;
}

class RoundCell
{
  // A Sphere's projection into a Circle on a 2D surface.
  const RoundCell(this.index, this.used, this.centre, this.diameter);

  final int    index;
  final bool   used;
  final Offset centre;
  final double diameter;
}

class BoardLayout3D
{
  // A Roxdoku (3D) Puzzle layout is a List of projected RoundCell objects.
  final PuzzleMap _map;

  BoardLayout3D(this._map);

  final int    spacing   = 6;
  final int    radius    = 1;
  final double deg       = pi / 180.0;		// Converts degrees to radians.

  Offset    _origin      = const Offset(0, 0);	// Centre of 3D puzzle-area.

  double    _baseScale3D = 1.0;			// Current scale of puzzle.
  double get baseScale3D => _baseScale3D;

  double    _rawDiameter = 2.0;			// Relative size of spheres.
  double    _rotateX     = 0.0;			// Deg to rotate view around X.
  double    _rotateY     = 0.0;			// Deg to rotate view around Y.

  double    _rangeX      = 0.0;			// Unscaled width of layout.
  double    _rangeY      = 0.0;			// Unscaled height of layout.
  double    _maxRange    = 0.0;

  var homeRotM           = Matrix.identity();
  var rotationM          = Matrix.identity();

  Coords newOrigin = Coords(0.0, 0.0, 0.0);
  List<Sphere> spheres    = [];
  List<Sphere> rotated    = [];
  // ?????? List<int>    cellLookup = [];	// NOT NEEDED...

  @override
  void calculate3DLayout()
  {
    // Pre-calculate puzzle background details (fixed when puzzle-play starts).
    // NOTE: This class gets size* values from PuzzleMap via the _map variable.

    int sizeX    = _map.sizeX;
    int sizeY    = _map.sizeY;
    int sizeZ    = _map.sizeZ;

    // These rotations tilt and turn the spheres so that all become visible.
    _rawDiameter = _map.diameter/100.0;	// Usually set to about 3.5.
    _rotateX     = _map.rotateX + 0.0;	// The 0.0 forces int degrees to double.
    _rotateY     = _map.rotateY + 0.0;
    // debugPrint('X range $minX $maxX, Y range $minY $maxY');
    // debugPrint('rangeX $rangeX rangeY $rangeY maxRange $maxRange');
    // debugPrint('Sphere IDs: minX $minXn maxX $maxXn minY $minYn maxY $maxYn');


    // Place the origin in the centre of the puzzle - used as rotation centre.
    newOrigin[0] = ((sizeX - 1) * spacing) / 2;
    newOrigin[1] = ((sizeY - 1) * spacing) / 2;
    newOrigin[2] = ((sizeZ - 1) * spacing) / 2;

    // Create a list of spheres and assign 3D co-ordinates to their centres, as
    // required by the puzzle type and map.

    int nPoints = _map.size;
    BoardContents board = _map.emptyBoard;

    for (int index = 0; index < nPoints; index++) {
      bool used = (board[index] == UNUSABLE) ? false : true;
      Coords sphereN = Coords(0.0, 0.0, 0.0);
      sphereN[0] =  _map.cellPosX(index) * spacing - newOrigin[0];
      sphereN[1] = -_map.cellPosY(index) * spacing + newOrigin[1];
      sphereN[2] = -_map.cellPosZ(index) * spacing + newOrigin[2];
      spheres.add(Sphere(index, used, sphereN, _rawDiameter));
    }

    // Rotate all the pseudo-spheres so as to give the user a better view.
    debugPrint('\nROTATIONS: _rotateX $_rotateX _rotateY $_rotateY\n');
    rotationM = Matrix.rotationX(_rotateX * deg).		// Tilt.
                multiplied(Matrix.rotationY(_rotateY * deg));	// Turn.
    homeRotM  = rotationM.clone();
    rotateCentresOfSpheres();
  }

  void rotateCentresOfSpheres()
  {
    double minX = 0.0; double minY = 0.0;
    double maxX = 0.0; double maxY = 0.0;
int minXn = -1;
int maxXn = -1;
int minYn = -1;
int maxYn = -1;

    rotated.clear();

    // Apply the matrix-rotation to the centre of each pseudo-sphere.
    for (int n = 0; n < spheres.length; n++) {
      // TODO - How can we avoid calculating unused spheres? They all have to
      //        go into the "rotated" list in order of "n".
      Coords sphereN = rotationM.rotated3(spheres[n].xyz);

      // Coords XYZ = sphereN.clone();		// For debug-message.
      // String s = '[';
      // s = s + XYZ[0].toStringAsFixed(2) + ', ';
      // s = s + XYZ[1].toStringAsFixed(2) + ', ';
      // s = s + XYZ[2].toStringAsFixed(2) + ']';
      // debugPrint('Sphere $n: from ${spheres[n].xyz} to $s');

      rotated.add(Sphere(n, spheres[n].used, sphereN, _rawDiameter));

      Offset centre = Offset(rotated[n].xyz[0], -rotated[n].xyz[1]);
      if (centre.dx < minX) {minX = centre.dx; minXn = rotated[n].index; }
      if (centre.dy < minY) {minY = centre.dy; minYn = rotated[n].index; }
      if (centre.dx > maxX) {maxX = centre.dx; maxXn = rotated[n].index; }
      if (centre.dy > maxY) {maxY = centre.dy; maxYn = rotated[n].index; }
    }

    _rangeX = maxX - minX + _rawDiameter;
    _rangeY = maxY - minY + _rawDiameter;
    _maxRange = (_rangeX > _rangeY) ? _rangeX : _rangeY;
    debugPrint('X range $minX $maxX, Y range $minY $maxY');
    debugPrint('rangeX $_rangeX rangeY $_rangeY maxRange $_maxRange');
    debugPrint('Sphere IDs: minX $minXn maxX $maxXn minY $minYn maxY $maxYn');

    // Sort the centres of the spheres into Z order, so that, when painting the
    // Canvas, the furthest-away spheres are painted first and the nearest last.
    rotated.sort((s1, s2) => s1.xyz[2].compareTo(s2.xyz[2]));

    // ?????? cellLookup.clear();	// NOT NEEDED...
    // ?????? cellLookup = List.filled(rotated.length, 0, growable: false);
    // ?????? for (int n = 0; n < rotated.length; n++) {
      // ?????? print(rotated[n].index);
      // ?????? cellLookup[rotated[n].index] = n;
    // ?????? }
    // ?????? print(cellLookup);
  }

  List<RoundCell> calculate2DProjection()
  {
    List<RoundCell> result = [];

    // Calculate the scale required to fit all circles within the puzzle-area.

    // Spheres started with diameter 2: now inflated as per PuzzleMap specs.
    _baseScale3D  = 1.0 / (_maxRange + _rawDiameter);
    debugPrint('Scaled ranges ${_baseScale3D * _rangeX} ${_baseScale3D * _rangeY}');
/* ??????
    Offset origin = puzzleRect.center;
    Offset centering = Offset((puzzleRect.width  - scale * _rangeX)/2.0,
                              (puzzleRect.height - scale * _rangeY)/2.0);
    debugPrint('Centering $centering');
*/
    Offset centering = Offset(0.0, 0.0);
    debugPrint('Centering $centering');
    for (int n = 0; n < rotated.length; n++) {
      Sphere s = rotated[n];
      Offset proj = Offset(
              s.used ?  _baseScale3D * s.xyz[0] + centering.dx : 0.0,	// X.
              s.used ? -_baseScale3D * s.xyz[1] + centering.dy : 0.0);	// Y.
      result.add(RoundCell(
                   s.index,
                   s.used,
                   proj,
                   _baseScale3D * s.diameter));			// Diameter.
    }
    return result;
  }

  Offset rotatedXY(int n)
  {
    return Offset(rotated[n].xyz[0], rotated[n].xyz[1]);
  }

  void hit3DViewControl(int buttonID)
  {
    // The user has hit one of the outward-pointing arrows. So rotate the 3D
    // puzzle by +90 or -90 deg in the corresponding direction.

    debugPrint('ENTERED BoardLayout.hit3DViewControl(): buttonID $buttonID.');
    switch(buttonID) {
      case 0:			// Rotate Left around Y axis.
        debugPrint('ROTATE CENTRES rotationM.rotateY(-pi/2.0)');
        rotationM.rotateY(-pi/2.0);
        break;
      case 1:			// Rotate Right around Y axis.
        debugPrint('ROTATE CENTRES rotationM.rotateY(pi/2.0)');
        rotationM.rotateY(pi/2.0);
        break;
      case 2:			// Rotate Upward around X axis.
        debugPrint('ROTATE CENTRES rotationM.rotateX(-pi/2.0)');
        rotationM.rotateX(-pi/2.0);
        break;
      case 3:			// Rotate Downward around X axis.
        debugPrint('ROTATE CENTRES rotationM.rotateX(pi/2.0)');
        rotationM.rotateX(pi/2.0);
        break;
    }
    rotateCentresOfSpheres();
    return;
  }

} // End class Puzzle3D.
