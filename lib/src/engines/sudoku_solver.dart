import '../globals.dart';
import '../models/puzzle_map.dart';

/****************************************************************************
 *    Copyright 2011  Ian Wadham <iandw.au@gmail.com>                       *
 *    Copyright 2006  David Bau <david bau @ gmail com> Original algorithms *
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

/* This class is an adaptation of algorithms in a Python program, Copyright (c)
 * David Bau 2006, which appears at http://davidbau.com/downloads/sudoku.py and
 * is discussed at http://davidbau.com/archives/2006/09/04/sudoku_generator.html
 */

// Major entry-points:
//
//   deduceValues()          Add values deduced by two simple logical methods.
//   solveBoard()            Return a full solution, not necessarily unique.
//   createFilledBoard()     Fill board with values that obey Puzzle rules.
//   checkSolutionIsValid()  Check if solution exists and agrees with previous.
//   checkSolutionIsUnique() Check if there are any further solutions.
//
// Private methods:
//
//   _solve_1()              Use deduceValues() then _tryGuesses() if needed.
//   _solve_2()              Continue using tryGuesses() until a second solution
//                           is found or there are no more (States stack empty).
//   _tryGuesses()           Iterate over a stack of States to try all possible
//                           values of cells that resist deduceValues() logic.

typedef Guess        = Move;
typedef GuessesList  = MoveList;

class SudokuSolver
{
  final int _unusable         = UNUSABLE;
  final int _vacant           = VACANT;

  MoveList       _moves       = [];
  MoveTypeList   _moveTypes   = [];

  BoardContents _currentBoard = [];
  List<State>   _states       = [];

  // Getters needed by SudokuGenerator to analyse moves and extract hint-moves.
  MoveList       get   moves       => _moves;
  MoveTypeList   get   moveTypes   => _moveTypes;

  late PuzzleMap _puzzleMap;

  List<int> _requiredGroupValues = [];
  List<int> _validCellValues = [];

  // Methods for packing two small integers into one and unpacking them.  Used
  // for speed and efficiency in the solver and other places.
  Pair setPair (int pos, int val ) => (pos << lowWidth) + val;
  int  pairPos (Pair x)  => x >> lowWidth;
  int  pairVal (Pair x)  => x & lowMask;

  final int dbgLevel = 0;

  int _nSymbols  = 9;
  int _nGroups   = 0;
  int _groupSize = 9;
  int _boardArea = 81;

  SudokuSolver({required PuzzleMap puzzleMap})
      :
    _puzzleMap = puzzleMap,
    _nSymbols  = puzzleMap.nSymbols,
    _nGroups   = puzzleMap.groupCount(),
    _boardArea = puzzleMap.size
  {
    // Now that _nGroups is known, set the list of group values to fixed-size.
    _requiredGroupValues = List.filled(_nGroups, 0, growable: false);
    _groupSize = _nSymbols;
    // print('CREATE SudokuSolver(): _nGroups $_nGroups, '
          // '_boardArea $_boardArea');
  }

  BoardContents createFilledBoard()
  {
    // Solve the empty board, thus filling it at random with values that satisfy
    // Sudoku/Roxdoku rules (or constraints).  These values can be the starting
    // point for generating a puzzle and also the final solution of that puzzle.

    // Clear the SudokuSolver's work-area (_currentBoard).
    _currentBoard = [..._puzzleMap.emptyBoard];		// Deep copy.

    // Fill a central block with values 1 to nSymbols in random sequence.  This
    // reduces the solveBoard() time considerably, esp. for 16 or 25 symbols.

    List<int> sequence = _puzzleMap.randomSequence(_nSymbols);
    List<int> cellList = _puzzleMap.group (_nGroups ~/ 2);
    for (int n = 0; n < _nSymbols; n++) {
        _currentBoard [cellList[n]] = sequence[n] + 1;
    }

    BoardContents b = solveBoard (_currentBoard, GuessingMode.Random);
    // print(b.isEmpty ? 'CREATE FILLED BOARD FAILED\n' : 'BOARD FILLED\n');
    // _puzzleMap.printBoard(_currentBoard);
    cleanUp();
    return _currentBoard;
  }

  int checkSolutionIsValid (BoardContents puzzle, BoardContents solution)
  {
    // Classic 4x4 Sudoku - test cases.
    // puzzle   = [1,0,0,0, 0,2,0,0, 0,0,1,0, 0,0,0,2];	// More than 1 solution.
    // puzzle   = [1,0,0,0, 0,2,0,0, 0,0,1,3, 0,0,0,2];	// Has only 1 solution.
    // answer   = [1,3,2,4, 4,2,3,1, 2,4,1,3, 3,1,4,2];	// The solver's answer.
    // solution = [];					// OK if empty solution.
    // solution = [1,3,2,4, 4,2,3,1, 2,4,1,3, 3,1,4,2];	// == solution on file.
    // solution = [1,3,2,4, 4,3,2,1, 2,4,1,3, 3,1,4,2];	// Diffs at cells 5 & 6.
    // solution = [1,3,2,4, 4,2,3,1, 2,4,1,3, 3,1,4,2,0]; // Too long.
    // solution = [1,3,2,4, 4,2,3,1, 2,4,1,3, 3,1,4];	// Too short.

    // Calculate a solution from scratch: return it as "answer".
    BoardContents answer = solveBoard (puzzle, GuessingMode.Random);

    if (answer.isEmpty) {
      return -1;		// There is no solution.
    }

    if (solution.isEmpty) {	// No need to compare answer and prior solution.
      return 0;			// Answer IS a solution, but maybe not unique.
    }

    // Check that "answer" agrees with a "solution" that is already available.
    //
    // Can be used to validate a saved puzzle and its solution. It can also be
    // fired if there is more than one solution and an alternative solution is
    // found first, which can avoid time spent in calling checkSolutionIsUnique.

    int result = 0;
    if (answer.length != solution.length) {
      // print('Wrong length: ans ${answer.length}, sol ${solution.length}'); 
      result = -2;		// The solution differs from the one supplied.
    }
    else {
      for (int n = 0; n < answer.length; n++) {
        if (answer[n] != solution[n]) {
          // print('Clash at cell $n: ans ${answer[n]}, sol ${solution[n]}');
          // print('ANS $answer');
          // print('SOL $solution');
          result = -2;		// The solution differs from the one supplied.
          break;
        }
      }
    }
    return result;
  }

  int checkSolutionIsUnique (BoardContents puzzle, BoardContents solution)
  {
    BoardContents answer = [];
    answer = _solve_2();
    if (! answer.isEmpty) {
      // print('Solver.checkSolutionIsUnique: There is MORE THAN ONE SOLUTION.\n');
      return -3;		// There is more than one solution.
    }
    return 0;			// The solution is unique.
  }

  /**
   * Solve a puzzle and return the first solution found, if any solution exists.
   *
   * The solution may or may not yet be known to be unique or it may not matter.
   *
   * The solveBoard method is used to fill the board initially with valid Sudoku
   * values, which will be the solution of the new Puzzle. Uniqueness does not
   * matter at this stage. A Puzzle is generated by inserting and removing clues
   * (selected values from the solution) on an initially empty board. For each
   * inserted/removed clue, the Puzzle is checked for solvability and correct
   * solution (uniqueness not yet known) and then checked for uniqueness of
   * its solution. If it is unique, it is solved again and assessed for
   * difficulty. This method (solveBoard) is used in all cases.
   *
   * @param boardValues   The board-contents of the puzzle to be solved.
   *
   * @return              The board-contents of a solution OR an empty list.
   */
  BoardContents solveBoard (BoardContents boardValues, GuessingMode gMode)
  {
    if (dbgLevel >= 2) {
        print('ENTER "solveBoard()\n');
        print(boardValues);
    }
    _currentBoard = [...boardValues];		// Deep copy.
    return _solve_1 (gMode);
  }

  void cleanUp()
  {
    // Release the storage for stack contents and moves lists. This is not
    // always possible: sometimes they need to be kept for more calculations.
    _states.clear();
    _moves.clear();
    _moveTypes.clear();
  }

  BoardContents _solve_1 ([GuessingMode gMode = GuessingMode.Random])
  {
    // First attempt to solve a board. Eliminate any previous solver work. If
    // there is no solution, return an empty board.
    cleanUp();

    // Attempt to deduce the solution in one hit.
    GuessesList g = deduceValues (_currentBoard, gMode);
    // _puzzleMap.printBoard(_currentBoard);
    if (g.isEmpty) {
        // The entire solution can be deduced by applying the Sudoku rules.
        // print('NO GUESSES NEEDED, the solution can be entirely deduced.\n');
        return _currentBoard;
    }

    int n = g.length;
    // print('\n\nSTART GUESSING... ADD FIRST STATE TO STACK $n guesses');
    // _puzzleMap.printBoard(_currentBoard);

    // From now on we need to use a mix of guessing, deducing and backtracking.
    _states.add (new State (g, 0, _currentBoard, _moves, _moveTypes));
    return _tryGuesses (gMode);

    // NOTE: At this point the States, Moves and MoveTypes lists will remain, in
    //       case _solve_2 or the generator's analyseMoves need to be called.
  }

  BoardContents _solve_2 ([GuessingMode gMode = GuessingMode.Random])
  {
    // Second attempt to solve a board. Continue previous solver work where it
    // left off, to check if there are two or more solutions to the board. If
    // there are no more solutions, return an empty board.
    return _tryGuesses (gMode);
  }

  BoardContents _tryGuesses ([GuessingMode gMode = GuessingMode.Random])
  {
    while (_states.length > 0) {
        int nStates = _states.length;
        GuessesList guesses = _states.last.guesses;
        int n = _states.last.guessNumber;
        // print('NStates $nStates top guesses $guesses guess number $n');
        if ((n >= guesses.length) || ((guesses[0]) == -1)) {
            // print('POP: Out of guesses at level $nStates\n');
            // print('\n\nREMOVE A STATE FROM THE STACK...');
            _states.removeLast();
            if (_states.length > 0) {
                _moves.clear();
                _moveTypes.clear();
                _moves = _states.last.moves;
                _moveTypes = _states.last.moveTypes;
            }
            continue;
        }
        _states.last.guessNumber = n + 1;
        _currentBoard = List.from(_states.last.values);
        // BoardContents b = _states.last.values;
        // print('Test value b = $b');
        // print('Current board $_currentBoard');
        _moves.add (guesses[n]);
        _moveTypes.add (MoveType.Guess);
        _currentBoard [pairPos (guesses[n])] = pairVal (guesses[n]);
        int depth = _states.length;
        int guess = guesses[n];
        int pos   = pairPos(guesses[n]);
        int val   = pairVal(guesses[n]);
        // dbo2
        // print('\nNEXT GUESS: depth $depth, guess number $n move $guess');
        // print('  Pick pos $pos value $val');
                // pairVal (guesses[n]), pairPos (guesses[n]),
                // pairPos (guesses[n])/_boardSize + 1,
                // pairPos (guesses[n])%_boardSize + 1);
        // _puzzleMap.printBoard(_currentBoard);

        guesses = deduceValues (_currentBoard, gMode);

        if (guesses.isEmpty) {
            // NOTE: We keep the stack of states.  It is needed by checkPuzzle()
	    //       for the multiple-solutions test and deleted when its parent
	    //       SudokuSolver object (i.e. this) is deleted.
            return _currentBoard;
        }
        int ng = guesses.length;
        // print('\n\nADD ANOTHER STATE TO THE STACK... $ng guesses');
        _states.add (new State (guesses, 0, _currentBoard, _moves, _moveTypes));
    }

    // No solution.
    _currentBoard.clear();
    return _currentBoard;
  }

  GuessesList deduceValues (BoardContents boardValues,
                            [GuessingMode gMode = GuessingMode.Random])
  {
    int iteration = 0;
    GuessesList guesses    = [];
    GuessesList newGuesses = [];

    _setUpValueRequirements (boardValues);
    while (true) {
        iteration++;
        _moves.add (iteration);
        _moveTypes.add (MoveType.Deduce);
        bool stuck = true;
        int  guessCounter = 0;
        guesses.clear();

        // Search through cells that are not yet filled.
        for (int cell = 0; cell < _boardArea; cell++) {
            if (boardValues[cell] == _vacant) {
                newGuesses.clear();
                int numbers = _validCellValues[cell];
                // print('Cell $cell possible values $numbers');	// dbg 3
                // 1-bits in "numbers" show which values are possible.
                // dbo3 "Cell %d, valid numbers %03o\n", cell, numbers);
                if (numbers == 0) {
                    // dbo2 "SOLUTION FAILED: RETURN at cell %d\n", cell);
                    // print('SOLUTION FAILED: RETURN at cell $cell');
                    // print('Guesses $guesses\n');
                    // _puzzleMap.printBoard(_currentBoard);
                    return solutionFailed (guesses);
                }
                int validNumber = 1;
                while (numbers != 0) {
                    // dbo3 "Numbers = %03o, validNumber = %d\n",
                            // numbers, validNumber);
                    if (numbers.isOdd) {	// Found a 1-bit.
                        newGuesses.add (setPair (cell, validNumber));
                    }
                    numbers = numbers >> 1;
                    validNumber++;
                }
                if (newGuesses.length == 1) {
                    _moves.add (newGuesses.first);
                    _moveTypes.add (MoveType.Single);
                    boardValues [cell] = pairVal (newGuesses.removeAt(0));
                    int value = boardValues[cell];
                    // print('Single Pick cell $cell value $value');
                    // dbo3 "  Single Pick %d %d row %d col %d\n",
                            // boardValues[cell], cell,
                            // cell/_boardSize + 1, cell%_boardSize + 1);
                    _updateValueRequirements (boardValues, cell);
                    stuck = false;
                }
                else if (stuck) {
                    // Select a list of guesses.
                    // print('A: Guesses ${guesses.length}, new ${newGuesses.length}');
                    if (guesses.isEmpty ||
                        (newGuesses.length < guesses.length)) {
                        // Take newGuesses if guesses list is empty or longer.
                        // print('A: Take newGuesses $newGuesses not $guesses');
                        guessCounter = 1;
                        guesses.clear();
                        guesses = [...newGuesses];
                        // print('Guess count $guessCounter guesses $guesses');
                    }
                    else if (newGuesses.length > guesses.length) {
                        // Ignore newGuesses list if it is longer than guesses.
                        ;
                    }
                    else if (gMode == GuessingMode.Random) {
                        // Equal length, so make a randomised choice.
                        int gl = guesses.length;
                        int ngl = newGuesses.length;
                        guessCounter++;
                        if (_puzzleMap.randomInt(guessCounter) == 0) {
                          //print('B: Take newGuesses $newGuesses not $guesses');
                          guesses.clear();
                          guesses = [...newGuesses];
                          // print('Guess count $guessCounter guesses $guesses');
                        }
                    }
                }
            } // End if
        } // Next cell

        // print('Board values after Single Pick pass'); 
        // _puzzleMap.printBoard(boardValues);
        // Search through groups that still have at least one unfilled cell.
        for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
            int numbers = _requiredGroupValues[groupNumber];
            // 1-bits in "numbers" show which values are currently required. 
            // dbo3 "Group %d, valid numbers %03o\n", groupNumber, numbers);
            if (numbers == 0) {
                continue;	// The group contains all the required values.
            }

            // print('Group $groupNumber required-value bits $numbers'); 
	    List<int> cellList = _puzzleMap.group (groupNumber);
            int validNumber = 1;
            int bit         = 1;
            int cell        = 0;
            while (numbers != 0) {
                if (numbers.isOdd) {	// Found a 1-bit.
                    newGuesses.clear();
                    for (int n = 0; n < _groupSize; n++) {
			cell = cellList[n];
                        if ((_validCellValues[cell] & bit) != 0) {
                            newGuesses.add (setPair (cell, validNumber));
                        }
                    }
                    if (newGuesses.isEmpty) {
                        // dbo2 "SOLUTION FAILED: RETURN at group %d\n", groupNumber);
                        // print('SOLUTION FAILED: RETURN at group $groupNumber');
                        // print('Guesses $guesses\n');
                        return solutionFailed (guesses);
                    }
                    else if (newGuesses.length == 1) {
                        _moves.add (newGuesses.first);
                        _moveTypes.add (MoveType.Spot);
                        cell = pairPos (newGuesses.removeAt(0));
                        boardValues [cell] = validNumber;
                        // print('Single Spot group $groupNumber value $validNumber');
                        // print('Cell $cell in list $cellList');
                        // dbo3 "  Single Spot in Group %d value %d %d "
                                // "row %d col %d\n",
                                // groupNumber, validNumber, cell,
                                // cell/_boardSize + 1, cell%_boardSize + 1);
                        _updateValueRequirements (boardValues, cell);
                        stuck = false;
                    }
                    else if (stuck) {
                        // Select a list of guesses.
                    // print('C: Guesses ${guesses.length}, new ${newGuesses.length}');
                        if (guesses.isEmpty ||
                            (newGuesses.length < guesses.length)) {
                        // print('C: Take newGuesses $newGuesses not $guesses');
                            guessCounter = 1;
                            guesses.clear();
                            guesses = [...newGuesses];
                        // print('Guess count $guessCounter guesses $guesses');
                        }
                        else if (newGuesses.length > guesses.length) {
                            ;
                        }
                        else if (gMode == GuessingMode.Random){
                          guessCounter++;
                          if (_puzzleMap.randomInt(guessCounter) == 0) {
                        // print('D: Take newGuesses $newGuesses not $guesses');
                                guesses.clear();
                                guesses = [...newGuesses];
                        // print('Guess count $guessCounter guesses $guesses');
                            }
                        }
                    }
                } // End if (numbers & 1)
                numbers = numbers >> 1;
                bit     = bit << 1;
                validNumber++;
            } // Next number
        } // Next groupNumber

        if (stuck) {
            // print('\nGuesses $guesses');
            if (gMode == GuessingMode.Random) {
              // Put the list of guesses into random order.
              GuessesList original = [...guesses];
              guesses.clear();

              List<int> sequence = _puzzleMap.randomSequence(original.length);
              for (int i = 0; i < original.length; i++) {
                guesses.add(original[sequence[i]]);
              }
              original.clear();
              // print('Shuffled guesses $guesses');
            }
            return guesses;
        }
    } // End while (true)
  }

  GuessesList solutionFailed (GuessesList guesses)
  {
    guesses.clear();
    guesses.add (-1);
    // print('Guesses set by solutionFailed() $guesses\n');
    return guesses;
  }

  void _setUpValueRequirements (BoardContents boardValues)
  {
    // Set a 1-bit for each possible cell-value in this order of Sudoku,
    // for example 9 bits for a 9x9 grid with 3x3 blocks.
    int allValues = (1 << _nSymbols) - 1;
    // print(allValues);

    if (dbgLevel >= 2) {
        print('ENTER _setUpValueRequirements()\n');
        _puzzleMap.printBoard(boardValues);
    }

    // Set bit-patterns to show what values each row, col or block needs.
    // The starting pattern is allValues, but bits are set to zero as the
    // corresponding values are supplied during puzzle generation and solving.

    _requiredGroupValues.fillRange(0, _nGroups, 0);

    int bitPattern = 0;
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
	// dbo3 "Group %3d ", groupNumber);
	List<int> cellList = _puzzleMap.group (groupNumber);
        bitPattern = 0;
        for (int n = 0; n < _groupSize; n++) {
            int value = boardValues[cellList[n]] - 1;
            if ((value >= 0) && (value < MaxValue)) {
                bitPattern |= (1 << value);	// Add bit for each value found.
            }
	    // dbo3 "%3d=%2d ", cellList[n], value + 1);
        }
        // Reverse all the bits, giving values currently not found in the group.
        _requiredGroupValues [groupNumber] = bitPattern ^ allValues;
	// dbo3 "bits %03o\n", _requiredGroupValues[groupNumber]);
    }
    // print('Required Group Values (bit patterns)');
    // print(_requiredGroupValues);
    // _puzzleMap.printGroups();
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
      List<int> cellList = _puzzleMap.group (groupNumber);
      List<int> values = [];
      for (int n = 0; n < _groupSize; n++) {
        values.add(boardValues[cellList[n]]); 
      }
      int bitMap = _requiredGroupValues[groupNumber];
      // print('Bit map: $bitMap groupNumber $groupNumber cells $cellList values $values');
    }

    // Set bit-patterns to show that each cell can accept any value.  Bits are
    // set to zero as possibilities for each cell are eliminated when solving.

    _validCellValues = List.filled(_boardArea, allValues, growable: false);
    for (int i = 0; i < _boardArea; i++) {
        if (boardValues[i] == _unusable) {
            // No values are allowed in unusable cells (e.g. in Samurai type).
            _validCellValues [i] = 0;
        }
        if (boardValues[i] != _vacant) {
            // Cell is already filled in.
            _validCellValues [i] = 0;
        }
    }

    // Now, for each cell, retain bits for values that are required by every
    // group to which that cell belongs.  For example, if the row already has 1,
    // 2, 3, the column has 3, 4, 5, 6 and the block has 6, 9, then the cell
    // can only have 7 or 8, with bit value 192.
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
	List<int> cellList = _puzzleMap.group (groupNumber);
        for (int n = 0; n < _nSymbols; n++) {
	    int cell = cellList[n];
            _validCellValues [cell] &= _requiredGroupValues[groupNumber];
        }   
    }
    // print('Bit maps for the currently valid cell values');
    // print(_validCellValues);
    // dbo2 "Finished _setUpValueRequirements()\n");

    // dbo3 "allowed:\n");
    for (int i = 0; i < _boardArea; i++) {
        // dbo3 "'%03o', ", _validCellValues[i]);
        // if ((i + 1) % _boardSize == 0) dbo3 "\n");
    }
    // dbo3 "needed:\n");
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
        // dbo3 "'%03o', ", _requiredGroupValues[groupNumber]);
        // if ((groupNumber + 1) % _nSymbols == 0) dbo3 "\n");
    }
    // dbo3 "\n");
  }

  void _updateValueRequirements (BoardContents boardValues, int cell)
  {
    // int val = boardValues[cell];	// Debugging.
    // print('_updateValueRequirements for cell $cell new value $val');
    // Set a 1-bit for each possible cell-value in this order of Sudoku.
    int allValues  = (1 << _nSymbols) - 1;
    // Set a complement-mask for this cell's new value.
    int bitPattern = (1 << (boardValues[cell] - 1)) ^ allValues;
    // Show that this cell no longer requires values: it has been filled.
    _validCellValues [cell] = 0;
    // print('bitPattern = $bitPattern');

    // Update the requirements for each group to which this cell belongs.
    List<int> groupList = _puzzleMap.groupList(cell);
    for (int groupNumber in groupList) {
        int before = _requiredGroupValues [groupNumber];
        _requiredGroupValues [groupNumber] &= bitPattern;
        int after = _requiredGroupValues [groupNumber];
        // print('Group $groupNumber required values: before $before after $after');

	List<int> cellList = _puzzleMap.group (groupNumber);
        for (int n = 0; n < _nSymbols; n++) {
	    int cell = cellList[n];
            before = _validCellValues[cell];
            _validCellValues[cell] &= bitPattern;
            after = _validCellValues[cell];
            // print('Group $groupNumber cell $cell bits: before $before after $after');
        }   
    }
  }
}

class State
{
/**
 * Saves a deep copy (or snapshot) of the current state of the solver. The
 * ... operator delivers the current CONTENTS of the collections (e.g. Lists)
 * rather than REFERENCES to the collections back in the caller.
 *
 * The caller (the Solver) is likely to add to the moves, guesses and board
 * contents, but may get stuck and then have to revert to an earlier state
 * and try another guess from the guesses list.
 */

  // CONSTRUCTOR.
  State (GuessesList   guesses,
         int           guessNumber,
         BoardContents inputValues,
         MoveList      moves,
         MoveTypeList  moveTypes)
    :
    _guesses         = [...guesses],
    _guessNumber     = guessNumber,
    _values          = [...inputValues],
    _moves           = [...moves],
    _moveTypes       = [...moveTypes]
  {
  }

  // Getters and setters of properties.
  GuessesList    get   guesses     => _guesses;
  int            get   guessNumber => _guessNumber;
  BoardContents  get   values      => _values;
  MoveList       get   moves       => _moves;
  MoveTypeList   get   moveTypes   => _moveTypes;

  void           set   guessNumber(int n) => _guessNumber = n;

  // The underlying properties (private).
  GuessesList    _guesses;
  int            _guessNumber;
  BoardContents  _values = [];
  MoveList       _moves;
  MoveTypeList   _moveTypes;
}
