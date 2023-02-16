import 'package:flutter/material.dart';

import '../models/puzzle_map.dart';

class CellView extends StatefulWidget
{
  final int x;			// X-coordinate.
  final int y;			// Y-coordinate.
  final double f;		// Font height.

  CellView(this.x, this.y, this.f, {Key? key})
      : super(key: key);

  @override
  State<CellView> createState() => _CellViewState();

} // End class CellView

class _CellViewState extends State<CellView>
{
  int _cellValue = 1;

  @override
  // TODO - How to to turn on highlight and turn off OLD Cell highlight.
  // TODO - How to draw various types of Cell, including unusable, Given, normal
  //        symbol and Notes symbols.

  Widget build(BuildContext context)
  {
    debugPrint('Building CELL ${widget.x},${widget.y}');

    // TODO - Might be easier to pass TextStyle as a pre-computed parameter.

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints)
      {
        debugPrint('Max height: ${constraints.maxHeight}');
        debugPrint('Max width:  ${constraints.maxWidth}');
        // NOTE: Don't need to multiply by a pixelRatio - not painting images.
      
        // TODO: 0.7 should be a symbolic constant.
        double fontHeight = widget.f;

        return AspectRatio(
          aspectRatio: 1.0,
          child: TextButton(
            child: Text(
              _cellValue.toString(),
              style: TextStyle(
                fontSize: fontHeight, fontWeight: FontWeight.bold
              )
            ),
            onPressed: () async {
              debugPrint('PRESSED CELL ${widget.x},${widget.y}');
              setState(() { _cellValue++; });
            },
          ),
        );
      }
    );
  } // End Widget build

} // End class _CellViewState
