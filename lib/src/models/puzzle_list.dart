import 'package:flutter/foundation.dart' show debugPrint;

import '../globals.dart';
import 'puzzle_types.dart';

class PuzzleList
// A list of extracts from the PuzzleType list: to appear in the startup sreen.
{
  const PuzzleList();

  final int tagLength = 1;	// Allow for tags on sub-lists of puzzles list.

  int listLength(int listNumber) => puzzles[listNumber].length - tagLength;

  final PuzzleTypesText puzzleList = const PuzzleTypesText();

  List<String> getItem(int listNumber, int selection)
  {
    int puzzleIndex = puzzles[listNumber][selection + tagLength];
    List<String> puzzleTypeData = puzzleList.puzzleTypeText(puzzleIndex);
    String name        = getDataByKey(puzzleTypeData, 'Name');
    String description = getDataByKey(puzzleTypeData, 'Description');
    String iconName    = getDataByKey(puzzleTypeData, 'Icon');
    List<String> item  = [puzzleIndex.toString(), name, description, iconName];
    return item;
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
    [forPlay, 0, 18, 8, 3, 10, 13, 1, 26],			// Beginners'.
    [forPlay, 2, 5, 11, 9, 20, 7, 4, 15, 14, 6, 12, 17, 19, 27, 25], // Main.
    [forPlay, 21, 22, 23, 24, 16],				// Additional.

    // Tap In A Puzzle, using any of the above, except for puzzles with cages.
    [forTapIn, 0, 18, /*8,*/ 3, /*10,*/ 13, 1, /*26,*/ 2, 5, /*11, 9,*/ 20,
               7, 4, 15, 14, 6, 12, 17, 19, /*27,*/ 25, 21, 22, 23, 24, 16]
  ];

} // End class PuzzleList.
