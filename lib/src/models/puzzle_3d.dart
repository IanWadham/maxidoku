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
  Sphere(this.id, this.used, this.xyz, this.diameter);

  final int    id;
  final bool   used;
  Coords       xyz = Coords(0.0, 0.0, 0.0);
  double       diameter = 2.0;
}

class RoundCell
{
  const RoundCell(this.id, this.used, this.centre, this.diameter);

  final int    id;
  final bool   used;
  final Offset centre;
  final double diameter;
}

class Puzzle3D
{
  final PuzzleMap _map;

  Puzzle3D(this._map);

  final int    spacing   = 6;
  final int    radius    = 1;
  final double deg       = pi / 180.0;

  Offset    _origin      = const Offset(0, 0);	// Centre of 3D puzzle-area.
  double    _scale       = 1.0;			// Current scale of puzzle.
  double    _rawDiameter = 2.0;			// Relative size of spheres.
  double    _rotateX     = 0.0;			// Deg to rotate view around X.
  double    _rotateY     = 0.0;			// Deg to rotate view around Y.

  double    _rangeX      = 0.0;			// Unscaled width of layout.
  double    _rangeY      = 0.0;			// Unscaled height of layout.
  double    _maxRange    = 0.0;

  var homeRotM           = Matrix.identity();
  var rotationM          = Matrix.identity();

  Coords newOrigin = Coords(0.0, 0.0, 0.0);
  List<Sphere> spheres = [];
  List<Sphere> rotated = [];

  @override
  void calculate3dLayout()
  {
    // Pre-calculate puzzle background details (fixed when puzzle-play starts).
    // NOTE: This class gets size* values from PuzzleMap via the _map variable.

    int sizeX    = _map.sizeX;
    int sizeY    = _map.sizeY;
    int sizeZ    = _map.sizeZ;

    _rawDiameter = _map.diameter/100.0;	// Usually set to about 3.5.
    _rotateX     = _map.rotateX + 0.0;
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

    for (int n = 0; n < nPoints; n++) {
      bool used = (board[n] == UNUSABLE) ? false : true;
      Coords sphereN = Coords(0.0, 0.0, 0.0);
      sphereN[0] =  _map.cellPosX(n) * spacing - newOrigin[0];
      sphereN[1] = -_map.cellPosY(n) * spacing + newOrigin[1];
      sphereN[2] = -_map.cellPosZ(n) * spacing + newOrigin[2];
      spheres.add(Sphere(n, used, sphereN, _rawDiameter));
    }

    // Rotate all the pseudo-spheres so as to give the user a better view.
    debugPrint('\nROTATIONS: _rotateX $_rotateX _rotateY $_rotateY\n');
    rotationM = Matrix.rotationX(_rotateX * deg).
                multiplied(Matrix.rotationY(_rotateY * deg));
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
      if (centre.dx < minX) {minX = centre.dx; minXn = rotated[n].id; }
      if (centre.dy < minY) {minY = centre.dy; minYn = rotated[n].id; }
      if (centre.dx > maxX) {maxX = centre.dx; maxXn = rotated[n].id; }
      if (centre.dy > maxY) {maxY = centre.dy; maxYn = rotated[n].id; }
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
  }

  List<RoundCell> calculateProjection(Rect puzzleRect)
  {
    List<RoundCell> result = [];

    // Calculate the scale required to fit all circles within the puzzle-area.
    int nCircles = rotated.length;

    // Spheres started with diameter 2: now inflated as per PuzzleMap specs.
    double scale  = 0.95 * puzzleRect.height / (_maxRange + _rawDiameter);
    debugPrint('Scaled ranges ${scale * _rangeX} ${scale * _rangeY} puzzleRect ${puzzleRect.size}');
    Offset origin = puzzleRect.center;
    Offset centering = Offset((puzzleRect.width  - scale * _rangeX)/2.0,
                              (puzzleRect.height - scale * _rangeY)/2.0);
    debugPrint('Centering $centering');
    centering = Offset(0.0, 0.0);
    debugPrint('Centering $centering');
    for (int n = 0; n < rotated.length; n++) {
      Sphere s = rotated[n];
      Offset proj = Offset(
                      s.used ?  scale * s.xyz[0] + centering.dx : 0.0,	// X.
                      s.used ? -scale * s.xyz[1] + centering.dy : 0.0);	// Y.
if ((s.id == 6) || (s.id == 20)) {
      print('Sphere ${s.id}: ${s.xyz[0]} ${s.xyz[1]} ${s.xyz[2]}');
      print('Projection $proj');
}
      result.add(RoundCell(
                   s.id,
                   s.used,
                   proj,
                   scale * s.diameter));			// Diameter.
    }
    return result;
  }

  Offset rotatedXY(int n)
  {
    return Offset(rotated[n].xyz[0], rotated[n].xyz[1]);
  }

  int whichSphere(Offset hitPos)
  {
    // debugPrint('whichSphere: hitPos = $hitPos');
    // Scale back and translate to "List<Sphere> rotated" co-ordinates.
    Offset hitXY = hitPos - _origin;
    // debugPrint('hitXY = $hitXY relative to origin $_origin');
    hitXY = Offset(hitXY.dx / _scale, -hitXY.dy / _scale);
    // debugPrint('hitXY scaled back by factor $_scale = $hitXY');

    double d = _rawDiameter;
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

/* This belongs in a View class...
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
  ******************************************** */

} // End class Puzzle3D.
