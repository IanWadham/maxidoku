import 'package:flutter/foundation.dart' show debugPrint;
import 'puzzle_types.dart';

/// A list of extracts from the PuzzleType list, to appear in the startup sreen.
class PuzzleList
{
  const PuzzleList();

  int listLength(int listNumber) => puzzles[listNumber].length;

  final PuzzleTypesText puzzleList = const PuzzleTypesText();

  List<String> getItem(int listNumber, int selection)
  {
    int index = puzzles[listNumber][selection];
    List<String> puzzleTypeData = puzzleList.puzzleTypeText(index);
    String name        = getDataByKey(puzzleTypeData, 'Name');
    String description = getDataByKey(puzzleTypeData, 'Description');
    String iconName    = getDataByKey(puzzleTypeData, 'Icon');
    List<String> item = [index.toString(), name, description, iconName];
    return [index.toString(), name, description, iconName];
  }

  String getDataByKey(List<String> puzzleTypeData, String key)
  {
    RegExp whitespace = RegExp(r'\s');
    int    keyLength  = key.length;

    for (String data in puzzleTypeData) {
      int endKey = data.indexOf(whitespace);
      // print('Extracted key ${data.substring(0, endKey)}');
      if (endKey != keyLength) continue;
      if (data.substring(0, endKey) == key) {
        // print('Found $key, value = |${data.substring(endKey + 1)}|');
        return data.substring(endKey + 1);
      }
    } 
    debugPrint('getDataByKey(): Failed to find $key');
    return ' ';;
  }

  // Puzzle-number liats for the user-selections in the PuzzleListView class.

  static const List<List<int>> puzzles = [
    [0, 18, 8, 3, 10, 13, 1, 26],				// Beginners'.
    [2, 5, 11, 9, 20, 7, 4, 15, 14, 6, 12, 17, 19, 27, 25],	// Main.
    [21, 22, 23, 24, 16],					// Additional.

    // Tap In A Puzzle, using any of the above, except for puzzles with cages.
    [0, 18, /*8,*/ 3, /*10,*/ 13, 1, /*26,*/ 2, 5, /*11, 9,*/ 20, 7, 4, 15,
     14, 6, 12, 17, 19, /*27,*/ 25, 21, 22, 23, 24, 16]
  ];

} // End class PuzzleList.
