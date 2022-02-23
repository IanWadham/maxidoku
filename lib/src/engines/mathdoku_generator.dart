import '../globals.dart';
import '../models/puzzle_map.dart';
import 'cage_generator.dart';

/****************************************************************************
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

/**
 * @class MathdokuGenerator
 * @short Generator for Killer Sudoku and Mathdoku puzzles.
 *
 * Generates a Killer Sudoku or Mathdoku puzzle from a Latin Square that
 * satisfies Sudoku-type constraints. It acts as a controller for makeCages().
 */

class MathdokuGenerator
{
  final PuzzleMap _puzzleMap;	// The layout, rules and geometry of the puzzle.

  const MathdokuGenerator (PuzzleMap this._puzzleMap);

  /**
   * Generate a Mathdoku or Killer Sudoku puzzle.
   *
   * puzzle             The generated puzzle.
   * solution           The values that must go into the solution.
   * solutionMoves      An ordered list of "move" cells found by the solver
   *                    when it reached a solution: used to provide Hints.
   * difficultyRequired The requested level of difficulty.
   *
   * return             True  if puzzle-generation succeeded.
   *                    False if too many tries were required.
   */
  bool generateMathdokuKillerTypes (BoardContents puzzle,
                                    BoardContents solution,
                                    List<int>     solutionMoves,
                                    Difficulty    difficultyRequired)
  {
    // Cage sizes must be no more than the number of cells in a column or row.
    int  maxSize   = 2 + difficultyRequired.index;
    if (maxSize > _puzzleMap.nSymbols) maxSize = _puzzleMap.nSymbols;
    int  maxVal    = 1000;
    bool hideOps   = false;
    // int  maxCombos = 120;
    int  maxCombos = 2000;

    int  maxTries  = 20;

    CageGenerator cageGen = CageGenerator(_puzzleMap, solution);

    int  numTries = 0;
    int  numMultis = 0;
    int  n = 0;
    while ((n <= 0) && (numTries < maxTries)) {
	numTries++;
	n = cageGen.makeCages (solutionMoves,
                               maxSize, maxVal, hideOps, maxCombos);
        print('CageGen return = $n, numTries $numTries, numMultis $numMultis');
        return true;	// TODO - DROP this FORCED EXIT.....................
	if (n < 0) {
	    numMultis++;
	}
    }
    if (numTries >= maxTries) {
	// qDebug() << "makeCages() FAILED after" << numTries << "tries"
	         // << numMultis << "multi-solutions";
        return false;		// Try another set of Sudoku cell-values.
    }

    // qDebug() << "makeCages() required" << numTries << "tries"
             // << numMultis << "multi-solutions";;
    puzzle = [..._puzzleMap.emptyBoard];	// Deep copy: modifiable later.
    for (int n = 0; n < _puzzleMap.cageCount(); n++) {
         if (_puzzleMap.cage(n).length == 1) {	// Single-cell cage => GIVEN.
             int index = _puzzleMap.cage(n)[0];
             puzzle[index] = solution[index];
         }
    }
    return true;
  }


  /**
   * Solve a Mathdoku or Killer Sudoku and check how many solutions there are.
   * The solver requires only the PuzzleMap, which contains all the cages.
   *
   * solution           The values returned as the solution.
   * solutionMoves      An ordered list of "move" cells found by the solver
   *                    when it reached a solution: used to provide Hints.
   *
   * return             0  = there is no solution,
   *                    1  = there is a unique solution,
   *                    >1 = there is more than one solution.
   */
  int solveMathdokuTypes (BoardContents solution,
                          List<int>     solutionMoves)
  {
    bool hideOps = false;
    int result   = 0;
    CageGenerator cageGen = CageGenerator(_puzzleMap, solution);
    result = cageGen.checkPuzzle (solution, solutionMoves, hideOps);
    return result;
  }
}

/*
// TODO - Will be in the cage_generator.dart file.
class CageGenerator
{
  const CageGenerator(BoardContents solution);

  int checkPuzzle(PuzzleMap m, BoardContents solution, List<int> solutionMoves,
                  bool hideOps)
  {
    return 0;	// Found no set of cages to fit the solution.
  }

  int makeCages(PuzzleMap puzzleMap, BoardContents solution,
                int maxSize, int maxValue, bool hideOperators, int maxCombos)
  {
    return 0;
  }
}
*/
