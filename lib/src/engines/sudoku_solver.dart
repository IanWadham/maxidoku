import 'dart:math';

import '../globals.dart';
import '../models/puzzle_map.dart';

typedef Guess        = Move;
typedef GuessesList  = MoveList;

class SudokuSolver
{
  Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  // Random _random = Random(266133);	// Fixed seed: no sophistication needed.

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
    _nGroups   = puzzleMap.nGroups,
    _boardArea = puzzleMap.size
  {
    _groupSize = _nSymbols;
    print('CREATE SudokuSolver(): _nGroups $_nGroups, _boardArea $_boardArea');
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
    List<int> sequence = [];
    for (int n = 1; n <= _nSymbols; n++) {
      sequence.add(n);
    }
    sequence.shuffle();
    // print('Sequence $sequence');
    List<int> cellList = _puzzleMap.group (_nGroups ~/ 2);
    // print('GROUP ${_nGroups ~/ 2}: cellList $cellList');
    // TODO - NEEDED?? randomSequence (sequence);
    for (int n = 0; n < _nSymbols; n++) {
        _currentBoard [cellList[n]] = sequence[n];
    }

    // _puzzleMap.printBoard(_currentBoard);
    BoardContents b = solveBoard (_currentBoard, GuessingMode.Random);
    // print(b.isEmpty ? 'SOLVE BOARD FAILED\n' : 'BOARD FILLED\n');
    // _puzzleMap.printBoard(_currentBoard);
    return _currentBoard;
  }

/* void randomSequence (List<int> sequence)
{
    if (sequence.isEmpty()) return;

    // Fill the vector with consecutive integers.
    int size = sequence.size();
    for (int i = 0; i < size; i++) {
        sequence [i] = i;
    }

    if (size == 1) return;

    // Shuffle the integers.
    int last = size;
    int z    = 0;
    int temp = 0;
    for (int i = 0; i < size; i++) {
        z = qrand() % last;
        last--;
        temp            = sequence.at (z);
        sequence [z]    = sequence.at (last);
        sequence [last] = temp;
    }
} */

  // TODO - This should be part of the SudokuSolver????
  int checkSolutionIsValid (BoardContents puzzle, BoardContents solution)
  {
    BoardContents answer = solveBoard (puzzle, GuessingMode.Random);
    if (answer.isEmpty) {
        // dbo1 "checkPuzzle: There is NO SOLUTION.\n");
        return -1;		// There is no solution.
    }
    if ((! solution.isEmpty) && (answer != solution)) {
        // dbo1 "checkPuzzle: The SOLUTION DIFFERS from the one supplied.\n");
        return -2;		// The solution differs from the one supplied.
    }
    return 0;			// OK so far.
  }

  int checkSolutionIsUnique (BoardContents puzzle, BoardContents solution)
  {
    BoardContents answer = [];
    answer = _solve_2();
    if (! answer.isEmpty) {
        // dbo1 "checkPuzzle: There is MORE THAN ONE SOLUTION.\n");
        return -3;		// There is more than one solution.
    }
    return 0;			// Solution is unique.
  }

  BoardContents solveBoard (BoardContents boardValues, GuessingMode gMode)
  {
    if (dbgLevel >= 2) {
        // dbo "solveBoard()\n");
        // print (boardValues);
    }
    _currentBoard = [...boardValues];		// Deep copy.
    return _solve_1 (gMode);
  }

  BoardContents _solve_1 ([GuessingMode gMode = GuessingMode.Random])
  {
    // First attempt to solve a board. Eliminate any previous solver work.
    // qDeleteAll (_states);
    _states.clear();
    _moves.clear();
    _moveTypes.clear();

    // Attempt to deduce the solution in one hit.
    GuessesList g = deduceValues (_currentBoard, gMode);
    // _puzzleMap.printBoard(_currentBoard);
    if (g.isEmpty) {
        // The entire solution can be deduced by applying the Sudoku rules.
        // dbo1 "NO GUESSES NEEDED, the solution can be entirely deduced.\n");
        // print('NO GUESSES NEEDED, the solution can be entirely deduced.\n');
        return _currentBoard;
    }

    int n = g.length;
    // print('\n\nTIME TO START GUESSING... ADD FIRST STATE TO STACK $n guesses');
    // _puzzleMap.printBoard(_currentBoard);
    // We need to use a mix of guessing, deducing and backtracking.
    _states.add (new State (g, 0, _currentBoard, _moves, _moveTypes));
        // TODO - DELETE BoardContents a = _states.last.values;
        // int len = _states.length;
        // print('Test number of states $len value a = $a');
    return _tryGuesses (gMode);
  }

  BoardContents _solve_2 ([GuessingMode gMode = GuessingMode.Random])
  {
    // Second attempt to solve a board. Continue previous solver work where it
    // left off, to check if there are two or more solutions to the board.
    return _tryGuesses (gMode);
  }

  BoardContents _tryGuesses ([GuessingMode gMode = GuessingMode.Random])
  {
    int limit = 0;
    while (_states.length > 0 && limit < 60) {
        /* XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX DEBUG */
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
	    //       SudokuBoard object (i.e. this->) is deleted.
            return _currentBoard;
        }
        int ng = guesses.length;
        // print('\n\nADD ANOTHER STATE TO THE STACK... $ng guesses');
        _states.add (new State (guesses, 0, _currentBoard, _moves, _moveTypes));
        // TODO - limit++;
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
                        if (_random.nextInt(guessCounter) == 0) {
                        // print('B: Take newGuesses $newGuesses not $guesses');
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
                    // TODO - Uses of "index" not required: still in C++ code.
                    // int index = groupNumber * _groupSize;
                    for (int n = 0; n < _groupSize; n++) {
			cell = cellList[n];
                        if ((_validCellValues[cell] & bit) != 0) {
                            newGuesses.add (setPair (cell, validNumber));
                        }
                    // TODO - Uses of "index" not required: still in C++ code.
                        // index++;
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
                            if (_random.nextInt(guessCounter) == 0) {
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
            // dbo2 "Guess    ");
            for (int i = 0; i < guesses.length; i++) {
                // dbo3 "%d,%d ",
                        // pairPos (guesses[i]), pairVal (guesses[i]));
            }
            // dbo2 "\n");

            // print('\nGuesses $guesses');
            if (gMode == GuessingMode.Random) {
              // Put the list of guesses into random order.
              guesses.shuffle();
              // print('Shuffled guesses $guesses');
            }

            // dbo2 "Shuffled ");
            for (int i = 0; i < guesses.length; i++) {
                // dbo3 "%d,%d ",
                        // pairPos (guesses[i]), pairVal (guesses[i]));
            }
            // dbo2 "\n");

            // TODO: We never get here. Why not?
            // print('STUCK: guesses $guesses\n');
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

    // TODO if (dbgLevel >= 2) {
        // print('ENTER _setUpValueRequirements()\n');
        // _puzzleMap.printBoard(boardValues);
    // TODO }

    // Set bit-patterns to show what values each row, col or block needs.
    // The starting pattern is allValues, but bits are set to zero as the
    // corresponding values are supplied during puzzle generation and solving.

    // TODO - Maybe should initialise this to the right size earlier and
    //        just do a fillRange() here.
    _requiredGroupValues = List.filled(_nGroups, 0, growable: false);

    // TODO - Uses of "index" not required: still in C++ code.
    // int index = 0;
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
            // TODO - Uses of "index" not required: still in C++ code.
            // index++;
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

    // TODO - Maybe should initialise this to the right size earlier and
    //        just do a fillRange() here.
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
    // TODO - Uses of "index" not required: still in C++ code.
    // index = 0;
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
	List<int> cellList = _puzzleMap.group (groupNumber);
        for (int n = 0; n < _nSymbols; n++) {
	    int cell = cellList[n];
            _validCellValues [cell] &= _requiredGroupValues[groupNumber];
            // TODO - Uses of "index" not required: still in C++ code.
            // index++;
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
/********************************************************************
********************************************************************/
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
 * ... operator delivers the current *contents* of the collections (e.g.
 * Lists) rather than *references* to the collections back in the caller.
 * The caller (the solver) is likely to add to the moves, guesses and board
 * contents, but may get stuck and then have to revert to an earlier state
 * and try another guess from the guesses list.
 */

/* public: */
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

  GuessesList    get   guesses     => _guesses;
  int            get   guessNumber => _guessNumber;
  BoardContents  get   values      => _values;
  MoveList       get   moves       => _moves;
  MoveTypeList   get   moveTypes   => _moveTypes;

  void           set   guessNumber(int n) => _guessNumber = n;

/* private: */
  GuessesList    _guesses;
  int            _guessNumber;
  BoardContents  _values = [];
  MoveList       _moves;
  MoveTypeList   _moveTypes;
}
