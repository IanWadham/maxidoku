import 'package:flutter/material.dart';
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
import '../settings/settings_controller.dart';
import 'painting_specs.dart';

// This is the interface between the 3D view and the Multidoku models, control
// and engines, which are written in Dart, with no Flutter objects or graphics.
//
// The models are the definitions, layouts and progress of the various types of
// puzzle available. The control handles the moves and gameplay (rules, etc.).
// The engines are the solvers and generators for the various types of puzzle.
// The same models, control and engines are used for 2D types of puzzle, but the
// views and interfaces are necessarily different.

typedef Matrix = Matrix4;
typedef Coords = Vector3;

class Sphere
{
  Sphere(this.id, this.used, this.xyz);

  final int id;
  final bool used;
  Coords xyz = Coords(0.0, 0.0, 0.0);
}

class PaintingSpecs3D extends PaintingSpecs
{
  final PuzzleMap _map;

  PaintingSpecs3D(this._map, SettingsController settings)
    :
    super(_map, settings);

  final int spacing = 6;
  final int radius  = 1;
  final double deg  = pi / 180.0;

  // final Matrix identityM = Matrix.identity();

  Offset       _origin      = const Offset(0, 0);	// Centre of 3D puzzle-area.
  double       _scale       = 1.0;		// Current scale of puzzle.
  double       _diameter    = 2.0;		// Relative size of spheres.
  double       _rotateX     = 0.0;		// Deg to rotate view around X.
  double       _rotateY     = 0.0;		// Deg to rotate view around Y.

  Offset    get origin      => _origin;		// Centre of 3D puzzle-area.
  double    get scale       => _scale;		// Current scale of puzzle.
  double    get diameter    => _diameter;	// Relative size of spheres.

  var homeRotM  = Matrix.identity();
  var rotationM = Matrix.identity();
  // var scalingM  = Matrix.identity();
  // var perspectM = Matrix.identity();

  Coords newOrigin = Coords(0.0, 0.0, 0.0);
  List<Sphere> spheres = [];
  List<Sphere> rotated = [];

  @override
  void calculatePainting()
  {
    // Pre-calculate puzzle background details (fixed when puzzle-play starts).
    // NOTE: This class gets size* values from PuzzleMap via the _map variable.

    nSymbols = _map.nSymbols;
    sizeX    = _map.sizeX;
    sizeY    = _map.sizeY;
    sizeZ    = _map.sizeZ;

    calculatePaintAreas();

    calculateTextProperties();

    _diameter = _map.diameter/100.0;
    _rotateX  = _map.rotateX + 0.0;
    _rotateY  = _map.rotateY + 0.0;

    newOrigin[0] = ((_map.sizeX - 1) * spacing) / 2;
    newOrigin[1] = ((_map.sizeY - 1) * spacing) / 2;
    newOrigin[2] = ((_map.sizeZ - 1) * spacing) / 2;

    // Create a set of circles and assign 3D co-ordinates to their centres, as
    // required by the puzzle type and map. They are later coloured so as to
    // represent spheres in 3D arrays.

    int nPoints = _map.size;
    BoardContents board = _map.emptyBoard;
    for (int n = 0; n < nPoints; n++) {
      bool used = (board[n] == UNUSABLE) ? false : true;
      Coords sphereN = Coords(0.0, 0.0, 0.0);
      sphereN[0] =  _map.cellPosX(n) * spacing - newOrigin[0];
      sphereN[1] = -_map.cellPosY(n) * spacing + newOrigin[1];
      sphereN[2] = -_map.cellPosZ(n) * spacing + newOrigin[2];
      spheres.add(Sphere(n, used, sphereN));
    }

    // Rotate all the pseudo-spheres so as to give the user a better view.
    debugPrint('\nROTATIONS: _rotateX $_rotateX _rotateY $_rotateY\n');
    rotationM = Matrix.rotationX(_rotateX*deg).
                multiplied(Matrix.rotationY(_rotateY*deg));
    homeRotM  = rotationM.clone();
    rotateCentresOfSpheres();
  }

  void rotateCentresOfSpheres()
  {
    rotated.clear();

    // Apply the matrix-rotation to the centre of each pseudo-sphere.
    for (int n = 0; n < spheres.length; n++) {
      Coords sphereN = rotationM.rotated3(spheres[n].xyz);
      // Coords XYZ = sphereN.clone();
      // String s = '[';
      // s = s + XYZ[0].toStringAsFixed(2) + ', ';
      // s = s + XYZ[1].toStringAsFixed(2) + ', ';
      // s = s + XYZ[2].toStringAsFixed(2) + ']';
      // debugPrint('Sphere $n: from ${spheres[n].xyz} to $s');
      rotated.add(Sphere(n, spheres[n].used, sphereN));
    }

    // Sort the centres of the spheres into Z order, so that, when painting the
    // Canvas, the furthest-away spheres are painted first and the nearest last.
    rotated.sort((s1, s2) => s1.xyz[2].compareTo(s2.xyz[2]));
  }

  void calculateScale()
  {
    // Calculate the scale required to fit all circles within the puzzle-area.
    int nCircles = rotated.length;
    double minX = 0.0; double minY = 0.0;
    double maxX = 0.0; double maxY = 0.0;
    for (int n = 0; n < nCircles; n++) {
      if (! rotated[n].used) {
        continue;		// Ignore UNUSED cells.
      }
      Offset centre = rotatedXY(n);
      if (centre.dx < minX) minX = centre.dx;
      if (centre.dy < minY) minY = centre.dy;
      if (centre.dx > maxX) maxX = centre.dx;
      if (centre.dy > maxY) maxY = centre.dy;
    }

    double rangeX = maxX - minX;
    double rangeY = maxY - minY;
    double maxRange = (rangeX > rangeY) ? rangeX : rangeY;

    // Spheres started with diameter 2: now inflated by ~1.75.
    _scale  = 0.95 * puzzleRect.height / (maxRange + _diameter);
    _origin = puzzleRect.center;
  }

  Offset rotatedXY(int n)
  {
    return Offset(rotated[n].xyz[0], rotated[n].xyz[1]);
  }

  int whichSphere(Offset hitPos)
  {
    // debugPrint('whichSphere: hitPos = $hitPos');
    // Scale back and translate to "List<Sphere> rotated" co-ordinates.
    Offset hitXY = hitPos - origin;
    // debugPrint('hitXY = $hitXY relative to origin $origin');
    hitXY = Offset(hitXY.dx / scale, -hitXY.dy / scale);
    // debugPrint('hitXY scaled back by factor $scale = $hitXY');

    double d = diameter;
    Rect r = Rect.fromCenter(center: hitXY, width: d, height: d);
    List<Sphere> possibles = [];
    for (Sphere s in rotated) {
      if (! s.used) {
        continue;
      }
      // if (r.contains(Offset(s.xyz[0], s.xyz[1]))) return s.id;
      if (r.contains(Offset(s.xyz[0], s.xyz[1]))) possibles.add(s);
    }
    if (possibles.isEmpty) {
      return -1;
    }
    else if (possibles.length == 1) {
      debugPrint('whichSphere: SINGLE POSSIBILITY ${possibles[0].id}');
      return possibles[0].id;
    }
    Sphere closestZ  = possibles[0];
    Sphere closestXY = possibles[0];
    double bestZ     = closestZ.xyz[2];
    Point p          = Point(hitXY.dx, hitXY.dy);
    double bestXY    = 10000.0;

    for (Sphere s in possibles) {
      if (s.xyz[2] > bestZ) {
        bestZ = s.xyz[2];
        closestZ = s;
      }
      Point xy = Point(s.xyz[0], s.xyz[1]);
      double d = p.distanceTo(xy);
      if (d < bestXY) {
        bestXY = d;
        closestXY = s;
      }
    }
    debugPrint('POSSIBLES $possibles');
    debugPrint('Closest Z $bestZ: sphere ${closestZ.id}');
    debugPrint('Closest XY $bestXY: sphere ${closestXY.id}');
    return closestZ.id;
  }

  final List<Path> _arrowList = [];

  void add3DViewControls(Canvas canvas)
  {
    // Add an outward-pointing arrow at each midpoint of the puzzleRect edges.
    double aS = puzzleRect.width / 40.0;	// Arrow size.
    _arrowList.clear();
    Offset p = puzzleRect.topCenter;
    drawAnArrow(canvas,
                [Offset(-aS,0.0) + p, Offset(0.0,-aS) + p, Offset(aS,0.0) + p]);
    p = puzzleRect.centerRight;
    drawAnArrow(canvas,
                [Offset(0.0,-aS) + p, Offset(aS,0.0) + p, Offset(0.0,aS) + p]);
    p = puzzleRect.bottomCenter;
    drawAnArrow(canvas,
                [Offset(aS,0.0) + p, Offset(0.0,aS) + p, Offset(-aS,0.0) + p]);
    p = puzzleRect.centerLeft;
    drawAnArrow(canvas,
                [Offset(0.0,aS) + p, Offset(-aS,0.0) + p, Offset(0.0,-aS) + p]);
  }

  void drawAnArrow(Canvas canvas, List<Offset> points)
  {
    Path arrow = Path();
    bool close = true;
    arrow.addPolygon(points, close);
    canvas.drawPath(arrow, boldLinePaint);
    _arrowList.add(arrow);
  }

  bool hit3DViewControl(Offset hitPos)
  {
    // Find out if the user has hit one of the outward-pointing arrows and, if
    // so, rotate the puzzle by +90 or -90 deg in the corresponding direction
    // and signal the Puzzle model to trigger a repaint (via Provider).

    for (int n = 0; n < _arrowList.length; n++) {
      if (_arrowList[n].contains(hitPos)) {
        switch(n) {
          case 0:
            rotationM.rotateX(-pi/2.0);
            break;
          case 1:
            rotationM.rotateY(pi/2.0);
            break;
          case 2:
            rotationM.rotateX(pi/2.0);
            break;
          case 3:
            rotationM.rotateY(-pi/2.0);
            break;
        }
        rotateCentresOfSpheres();
        return true;
      }
    }
    return false;
  }

} // End class PaintingSpecs3D
