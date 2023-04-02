import 'package:flutter/foundation.dart' show debugPrint;

import '../globals.dart';
import '../models/puzzle_map.dart';
import 'cage_generator.dart';

/* **************************************************************************
 *    Copyright 2015  Ian Wadham <iandw.au@gmail.com>                       *
 *                                                                          *
 *    This program is free software; you can redistribute it and/or         *
 *    modify it under the terms of the GNU General Public License as        *
 *    published by the Free Software Foundation; either version 2 of        *
 *    the License, or (at your option) any later version.                   *
 *                                                                          *
 *    This program is distributed in the hope that it will be useful,       *
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *    GNU General Public License for more details.                          *
 *                                                                          *
 *    You should have received a copy of the GNU General Public License     *
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ****************************************************************************/

/*
 * @class MathdokuKillerGenerator
 * @short Generator for Killer Sudoku and Mathdoku puzzles.
 *
 * Generates a Killer Sudoku or Mathdoku puzzle from a Latin Square that
 * satisfies Sudoku-type constraints. It acts as a controller for makeCages().
 */

class MathdokuKillerGenerator
{
  final PuzzleMap _puzzleMap;	// The layout, rules and geometry of the puzzle.

  const MathdokuKillerGenerator (this._puzzleMap);

  /*
   * Generate a Mathdoku or Killer Sudoku puzzle.
   *
   * puzzle             The generated puzzle.
   * solution           The values that must go into the solution.
   * solutionMoves      An ordered list of "move" cells found by the solver
   *                    when it reached a solution: used to provide Hints.
   * difficultyRequired The requested level of difficulty.
   *
   * return             A message about the outcome to be shown to the user.
   *                    Message type F = generation failed internally, Q = it
   *                    did not reach the level of difficulty required, I = it
   *                    reached the required level and the message provides
   *                    some information about the puzzle.
   */
  Message generateMathdokuKillerTypes (BoardContents puzzle,
                                       BoardContents solution,
                                       List<int>     solutionMoves,
                                       Difficulty    difficultyRequired)
  {
    // Try up to 10 solution boards + 20 attempts to generate cages for each
    // solution that satisfy the user's requirements: total 10x20 = 200 tries.
    int  maxTries      = 20;

    Message response = Message('', '');

    // Cage sizes must be no more than the number of cells in a column or row.
    CageGenerator cageGen = CageGenerator(_puzzleMap, solution);

    int  numTries = 0;
    int  numMultis = 0;
    int  n = 0;

    while ((n <= 0) && (numTries < maxTries)) {
      // Generate random cages covering the existing solution. Return n > 0 if
      // those cages provide a puzzle with a single solution. Return n = 0 if
      // they provide no solution or n < 0 if multiple solutions.
      n = cageGen.makeCages(solutionMoves, difficultyRequired);
      if (n < 0) {
        numMultis++;
      }
      numTries++;
      debugPrint('CageGen return = $n, numTries $numTries, '
                 'numMultis $numMultis\n\n');
    }

    if ((n <= 0) && (numTries >= maxTries)) {
      debugPrint('makeCages() FAILED after $numTries tries $numMultis multis');
      // Return empty Message (maybe to try another set of solution values).
      return response;
    }

    debugPrint('makeCages() took $numTries tries $numMultis multi-solutions');
    debugPrint('MathdokuGen: Solution moves $solutionMoves');

    // Insert the values of the single-cell cages as clues in the empty Puzzle.
    int nClues = 0;
    for (int n = 0; n < _puzzleMap.cageCount(); n++) {
      if (_puzzleMap.cage(n).length == 1) {	// Single-cell cage => GIVEN.
        nClues++;
        int index = _puzzleMap.cage(n)[0];
        puzzle[index] = solution[index];
      }
    }

    int movesToGo = solution.length - nClues;
    response.messageType = 'I';
    response.messageText = 'The difficulty level of this puzzle is'
                           ' ${difficultyTexts[difficultyRequired.index]}. It'
                           ' has $nClues clues and $movesToGo moves to go.';
    // Success.
    return response;
  }

} // End MathdokuKillerGenerator class
