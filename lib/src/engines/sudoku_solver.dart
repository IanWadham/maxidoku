/*
    SPDX-FileCopyrightText: 2011      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2006      David Bau  <david bau @ gmail.com>
    SPDX-FileCopyrightText: 2015      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/foundation.dart' show debugPrint;

import '../globals.dart';
import '../models/puzzle_map.dart';

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
  final List<State> _states   = [];

  // Getters needed by SudokuGenerator to analyse moves and extract hint-moves.
  MoveList       get   moves       => _moves;
  MoveTypeList   get   moveTypes   => _moveTypes;

  final PuzzleMap _puzzleMap;

  List<int> _requiredGroupValues = [];
  List<int> _validCellValues = [];

  // Methods for packing two small integers into one and unpacking them.  Used
  // for speed and efficiency in the solver and other places.
  Pair setPair (int pos, int val ) => (pos << lowWidth) + val;
  int  pairPos (Pair x)  => x >> lowWidth;
  int  pairVal (Pair x)  => x & lowMask;

  final int dbgLevel = 0;

  final int _nSymbols;
  final int _nGroups;
  final int _groupSize;
  final int _boardArea;

  SudokuSolver({required PuzzleMap puzzleMap})
      :
    _puzzleMap = puzzleMap,
    _nSymbols  = puzzleMap.nSymbols,
    _nGroups   = puzzleMap.groupCount(),
    _groupSize = puzzleMap.nSymbols,
    _boardArea = puzzleMap.size
  {
    // Now that _nGroups is known, set the list of group values to fixed-size.
    _requiredGroupValues = List.filled(_nGroups, 0, growable: false);
    // debugPrint('CREATE SudokuSolver(): _nGroups $_nGroups, '
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
    // debugPrint(b.isEmpty ? 'CREATE FILLED BOARD FAILED\n' : 'BOARD FILLED\n');
    // _puzzleMap.printBoard(b);
    cleanUp();
    return b;
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
      // debugPrint('Wrong length: ans ${answer.length}, sol ${solution.length}'); 
      result = -2;		// The solution differs from the one supplied.
    }
    else {
      for (int n = 0; n < answer.length; n++) {
        if (answer[n] != solution[n]) {
          // debugPrint('Clash at cell $n: ans ${answer[n]}, sol ${solution[n]}');
          // debugPrint('ANS $answer');
          // debugPrint('SOL $solution');
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
    if (answer.isNotEmpty) {
      // debugPrint('Solver.checkSolutionIsUnique: There is MORE THAN ONE SOLUTION.\n');
      return -3;		// There is more than one solution.
    }
    return 0;			// The solution is unique.
  }

  /*
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
        debugPrint('ENTER "solveBoard()\n');
        debugPrint('$boardValues');
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
        // debugPrint('NO GUESSES NEEDED, the solution can be entirely deduced.\n');
        return _currentBoard;
    }

    // int n = g.length;
    // debugPrint('\n\nSTART GUESSING... ADD FIRST STATE TO STACK $n guesses');
    // _puzzleMap.printBoard(_currentBoard);

    // From now on we need to use a mix of guessing, deducing and backtracking.
    _states.add (State (g, 0, _currentBoard, _moves, _moveTypes));
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
    while (_states.isNotEmpty) {
        GuessesList guesses = _states.last.guesses;
        int n = _states.last.guessNumber;
        // debugPrint('NStates $nStates top guesses $guesses guess number $n');
        if ((n >= guesses.length) || ((guesses[0]) == -1)) {
            // Take a solution-state and a set of guesses from the stack.
            // debugPrint('POP: Out of guesses at level ${_states.length}\n');
            // debugPrint('\n\nREMOVE A STATE FROM THE STACK...');
            _states.removeLast();
            if (_states.isNotEmpty) {
                _moves.clear();
                _moveTypes.clear();
                _moves = _states.last.moves;
                _moveTypes = _states.last.moveTypes;
            }
            continue;
        }
        _states.last.guessNumber = n + 1;
        _currentBoard = List.from(_states.last.values);
        _moves.add (guesses[n]);
        _moveTypes.add (MoveType.Guess);
        _currentBoard [pairPos (guesses[n])] = pairVal (guesses[n]);

        // int depth = _states.length;
        // int guess = guesses[n];
        // int pos   = pairPos(guesses[n]);
        // int val   = pairVal(guesses[n]);
        // debugPrint('\nNEXT GUESS: depth $depth, guess num $n move $guess');
        // debugPrint('  Pick pos $pos value $val');
                // pairVal (guesses[n]), pairPos (guesses[n]),
                // pairPos (guesses[n])/_boardSize + 1,
                // pairPos (guesses[n])%_boardSize + 1);
        // _puzzleMap.printBoard(_currentBoard);

        // Having applied a guess to one cell, try to deduce more cell-values.
        guesses = deduceValues (_currentBoard, gMode);

        if (guesses.isEmpty) {
            // A solution has been reached... not necessarily unique.
            // NOTE: We keep the stack of states.  It is needed for the
            //       multiple-solutions test and deleted when its parent
	    //       SudokuSolver object (i.e. this) is deleted.
            // debugPrint('SOLUTION FOUND');
            return _currentBoard;
        }

        // More guesses: add a solution-state and a set of guesses to the stack.
        _states.add (State (guesses, 0, _currentBoard, _moves, _moveTypes));
        // debugPrint('\n\nADD ANOTHER STATE TO THE STACK... '
                      // '${guesses.length}  guesses');
    }

    // No solution.
    _currentBoard.clear();
    return _currentBoard;
  }

  int _guessCounter = 0;

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
        _guessCounter = 0;
        guesses.clear();

        // Search through cells that are still unsolved (i.e. vacant).
        for (int cell = 0; cell < _boardArea; cell++) {
            if (boardValues[cell] == _vacant) {
                newGuesses.clear();
                int numbers = _validCellValues[cell];
                // 1-bits in "numbers" show which values are possible.
                if (numbers == 0) {
                    return solutionFailed (guesses, 'cell $cell');
                }
                int validNumber = 1;
                while (numbers != 0) {
                    if (numbers.isOdd) {	// Found a 1-bit.
                        newGuesses.add (setPair (cell, validNumber));
                    }
                    numbers = numbers >> 1;
                    validNumber++;
                }
                if (newGuesses.length == 1) {
                    // Cell has only one possible value: add it to the solution.
                    _moves.add (newGuesses.first);
                    _moveTypes.add (MoveType.Single);
                    boardValues [cell] = pairVal (newGuesses.removeAt(0));
                    // debugPrint('Single Pick cell $cell value ${boardValues[cell]}');
                    _updateValueRequirements (boardValues, cell);
                    stuck = false;
                }
                else if (stuck) {
                    // Select best list of guesses so far.
                    if (foundBetterGuesses(guesses, newGuesses, gMode)) {
                        guesses.clear();
                        guesses = [...newGuesses];
                    }
                }
            } // End if cell is vacant
        } // Next cell

        // debugPrint('Board values after Single Pick pass'); 
        // _puzzleMap.printBoard(boardValues);

        // Search through groups that still have at least one unfilled cell.
        for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
            int numbers = _requiredGroupValues[groupNumber];
            // 1-bits in "numbers" show which values are currently required. 
            if (numbers == 0) {
                continue;	// The group contains all the required values.
            }

            // debugPrint('Group $groupNumber required-value bits $numbers'); 
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
                        return solutionFailed (guesses, 'group $groupNumber');
                    }
                    else if (newGuesses.length == 1) {
                        // Group has just one unsolved cell: add it to solution.
                        _moves.add (newGuesses.first);
                        _moveTypes.add (MoveType.Spot);
                        cell = pairPos (newGuesses.removeAt(0));
                        boardValues [cell] = validNumber;
                        // debugPrint('Single Spot group $groupNumber '
                                   // 'value $validNumber');
                        // debugPrint('Cell $cell in list $cellList');
                        _updateValueRequirements (boardValues, cell);
                        stuck = false;
                    }
                    else if (stuck) {
                        // Select best list of guesses so far.
                        if (foundBetterGuesses(guesses, newGuesses, gMode)) {
                            guesses.clear();
                            guesses = [...newGuesses];
                        }
                    }
                } // End if (numbers & 1)
                numbers = numbers >> 1;
                bit     = bit << 1;
                validNumber++;
            } // Next number
        } // Next groupNumber

        if (stuck) {
            // debugPrint('\nGuesses $guesses');
            if (gMode == GuessingMode.Random) {
              // Put the list of guesses into random order.
              GuessesList original = [...guesses];
              guesses.clear();

              List<int> sequence = _puzzleMap.randomSequence(original.length);
              for (int i = 0; i < original.length; i++) {
                guesses.add(original[sequence[i]]);
              }
              original.clear();
              // debugPrint('Shuffled guesses $guesses');
            }
            return guesses;
        }
    } // End while (true)
  }

  bool foundBetterGuesses(GuessesList current, GuessesList possible,
                          GuessingMode gMode) {

    // If "possible" is the first list of guesses or has fewer guesses in its
    // list than previously, use it.
    bool result = false;
    if (current.isEmpty || (possible.length < current.length)) {
      result = true;
    }

    // If "possible" has the same length as the previous list and guessing-mode
    // is random, make a random choice between the two lists.
    else if ((gMode == GuessingMode.Random) &&
             (possible.length == current.length)) {
      _guessCounter++;		// Keep reducing the chances: 1/2, 1/3, 1/4 ...
      if (_puzzleMap.randomInt(_guessCounter) == 0) {
        result = true;
      }
    }

    return result; 
  }

  GuessesList solutionFailed (GuessesList guesses, String failurePoint)
  {
    guesses.clear();
    guesses.add (-1);
    // debugPrint('NO SOLUTION AVAILABLE: RETURN at $failurePoint');
    // debugPrint('Guesses $guesses\n');
    // debugPrint('Guesses set by solutionFailed() $guesses\n');
    // _puzzleMap.printBoard(_currentBoard);
    return guesses;
  }

  void _setUpValueRequirements (BoardContents boardValues)
  {
    // Set a 1-bit for each possible cell-value in this order of Sudoku,
    // for example 9 bits for a 9x9 grid with 3x3 blocks.
    int allValues = (1 << _nSymbols) - 1;
    // debugPrint(allValues);

    if (dbgLevel >= 2) {
        debugPrint('ENTER _setUpValueRequirements()\n');
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
    // debugPrint('Required Group Values (bit patterns)');
    // debugPrint(_requiredGroupValues);
    // _puzzleMap.printGroups();
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
      List<int> cellList = _puzzleMap.group (groupNumber);
      List<int> values = [];
      for (int n = 0; n < _groupSize; n++) {
        values.add(boardValues[cellList[n]]); 
      }
      // debugPrint('Bit map: ${_requiredGroupValues[groupNumber]} '
                    // 'groupNumber $groupNumber '
                    // 'cells $cellList values $values');
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
    // debugPrint('Bit maps for the currently valid cell values');
    // debugPrint(_validCellValues);
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
    // debugPrint('_updateValueRequirements for cell $cell new value $val');
    // Set a 1-bit for each possible cell-value in this order of Sudoku.
    int allValues  = (1 << _nSymbols) - 1;
    // Set a complement-mask for this cell's new value.
    int bitPattern = (1 << (boardValues[cell] - 1)) ^ allValues;
    // Show that this cell no longer requires values: it has been filled.
    _validCellValues [cell] = 0;
    // debugPrint('bitPattern = $bitPattern');

    // Update the requirements for each group to which this cell belongs.
    List<int> groupList = _puzzleMap.groupList(cell);
    for (int groupNumber in groupList) {
        _requiredGroupValues [groupNumber] &= bitPattern;

	List<int> cellList = _puzzleMap.group (groupNumber);
        for (int n = 0; n < _nSymbols; n++) {
	    int cell = cellList[n];
            _validCellValues[cell] &= bitPattern;
        }   
    }
  }
}

class State
{
/*
 * Saves a deep copy (or snapshot) of the current state of the solver. The
 * ... operator delivers the current CONTENTS of the collections (e.g. Lists)
 * rather than REFERENCES to the collections back in the caller.
 *
 * The caller (the Solver) is likely to add to the moves, guesses and board
 * contents, but may get stuck and then have to revert to an earlier state
 * and try another guess from the guesses list.
 */

  // CONSTRUCTOR.
  State (GuessesList   pGuesses,
                       this.guessNumber,
         BoardContents pBoardValues,
         MoveList      pMoves,
         MoveTypeList  pMoveTypes)
    :
    _guesses         = [...pGuesses],
    _values          = [...pBoardValues],
    _moves           = [...pMoves],
    _moveTypes       = [...pMoveTypes]
  ;
  // Getters and setters of properties.
  GuessesList    get   guesses     => _guesses;
  BoardContents  get   values      => _values;
  MoveList       get   moves       => _moves;
  MoveTypeList   get   moveTypes   => _moveTypes;

  int                  guessNumber;	// Read/write property.

  // The underlying data (private and read-only).
  final GuessesList    _guesses;
  final BoardContents  _values;
  final MoveList       _moves;
  final MoveTypeList   _moveTypes;
}
