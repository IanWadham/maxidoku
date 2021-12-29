// Properties: playing board - empty, generated, reloaded
//             solution
//             puzzle map - selected by user via puzzle-list screen
//
// Methods:    generate puzzle
//             reload puzzle?
//             check puzzle validity (solvable and only one solution)
//             get hint
//             print puzzle
//             constructor (selection index, empty?, difficulty, [symmetry])


import 'dart:math';
import '../globals.dart';
import 'puzzlemap.dart';
import 'puzzletypes.dart';
// import 'sudokusolver.dart';

class CellChange
{
  int       cellIndex;		// The position of the cell that changed.
  CellState before;		// The status and value before the change.
  CellState after;		// The status and value after the change.

  CellChange(this.cellIndex, this.before, this.after);
}

class Puzzle
{
//  final BoardContents boardValues = [0, 0, 1, 0, 4, 0, 0, 0, 0, 0, 0, 2, 0, 3, 0, 0];
//  final BoardContents boardValues = [0, 2, 0, 0, 0, 0, 0, 2, 3, 0, 0, 0, 0, 0, 4, 0];
//  final BoardContents boardValues = [0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 2, 0, 3, 0];
/*  // No symmetry, easy, no guesses needed.
    final BoardContents boardValues = [0, 6, 0, 0, 0, 0, 0, 0, 0,
                                     9, 0, 0, 0, 5, 0, 0, 4, 2,
                                     0, 5, 8, 0, 0, 7, 0, 0, 9, 
                                     8, 0, 6, 0, 2, 0, 0, 0, 1, 
                                     0, 0, 2, 0, 3, 9, 0, 7, 4, 
                                     7, 0, 0, 0, 8, 5, 9, 2, 6, 
                                     0, 0, 9, 0, 0, 0, 0, 0, 0, 
                                     3, 8, 5, 2, 4, 6, 0, 9, 7, 
                                     0, 4, 0, 0, 0, 8, 0, 5, 3]; */
/*  // Spiral, Hard, 1 level of guessing needed.
    final BoardContents boardValues = [0, 0, 9, 0, 5, 2, 0, 0, 0,
                                     0, 0, 0, 3, 1, 8, 0, 0, 0,
                                     0, 0, 1, 7, 9, 0, 2, 0, 4,
                                     5, 1, 0, 0, 0, 0, 8, 7, 0,
                                     4, 9, 8, 0, 0, 0, 1, 3, 6,
                                     0, 3, 2, 0, 0, 0, 0, 4, 9,
                                     1, 0, 5, 0, 7, 3, 9, 0, 0,
                                     0, 0, 0, 1, 4, 9, 0, 0, 0,
                                     0, 0, 0, 8, 6, 0, 4, 0, 0]; */
/*  // No symmetry, Diabolical, 3 levels of guessing needed.
    final BoardContents boardValues = [0, 0, 0, 0, 8, 0, 0, 0, 0,
                                     0, 0, 8, 0, 0, 2, 5, 0, 0,
                                     0, 5, 0, 0, 0, 0, 0, 4, 0,
                                     0, 0, 5, 4, 1, 0, 0, 8, 0,
                                     0, 1, 0, 0, 2, 5, 0, 6, 0,
                                     0, 0, 9, 0, 0, 8, 0, 2, 0,
                                     0, 0, 0, 6, 0, 0, 2, 0, 3,
                                     5, 0, 1, 0, 4, 7, 0, 0, 0,
                                     0, 0, 0, 0, 0, 1, 0, 0, 4]; */
  // No symmetry, Unlimited, 6 levels of guessing needed (more than 1 descent).
  final BoardContents boardValues = [0, 0, 2, 0, 0, 7, 0, 0, 0,
                                     4, 0, 0, 0, 0, 5, 1, 0, 0,
                                     0, 0, 0, 8, 1, 0, 0, 9, 0,
                                     0, 0, 0, 0, 0, 0, 9, 0, 0,
                                     6, 0, 0, 0, 7, 0, 0, 0, 4,
                                     0, 2, 7, 1, 0, 0, 0, 3, 0,
                                     0, 0, 3, 0, 0, 0, 7, 0, 0,
                                     1, 0, 0, 0, 0, 0, 0, 2, 5,
                                     0, 0, 4, 0, 9, 8, 0, 0, 0];
  // int _nSymbols  = 9;
  // int _nGroups   = 0;
  // int _groupSize = 9;
  // int _boardArea = 81;

  late PuzzleMap _puzzleMap;

  PuzzleMap get puzzleMap => _puzzleMap;

  // Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  Random _random = Random(266133);	// Fixed seed: no sophistication needed.

  void testPuzzle() {
    print('TEST Puzzle class');
    print(boardValues);
    print('');
    BoardContents board = boardValues;
    _puzzleMap.printBoard(board);
    // _setUpValueRequirements (board);
    // _deduceValues (board);
    // print('RETURNED FROM _deduceValues');
    /* ---------------------------------------------------------- */
    /* SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap); */
    /* ---------------------------------------------------------- */
    Stopwatch sw = Stopwatch();
    sw.start();
    /* ---------------------------------------------------------- */
    /* board = solver.solveBoard(board, GuessingMode.Random); */
    /* ---------------------------------------------------------- */
    print('RETURNED FROM solveBoard');
    _puzzleMap.printBoard(board);
    print('ELAPSED TIME (msec)');
    print (sw.elapsedMilliseconds);
    for (int n = 0; n < 1; n++) {
      /* --------------------------- */
      /* solver.createFilledBoard(); */
      /* --------------------------- */
    }
    print('ELAPSED TIME (msec)');
    print (sw.elapsedMilliseconds);
    return;
  }
  // The starting position of the puzzle, +ve integers. Stays fixed during play.
  BoardContents    _puzzleGiven = [];

  // The full solution of the puzzle, +ve integers. Stays fixed during play.
  BoardContents    _solution    = [];

  // Current values of each cell, which may be +ve integers or bitmaps of Notes.
  BoardContents    _stateOfPlay = [];
  BoardContents get stateOfPlay => _stateOfPlay;

  // The current status of each cell.
  // Possible values are UNUSABLE, VACANT, GIVEN, CORRECT, ERROR and NOTES.
  BoardContents    _cellStatus  = [];

  // The sequence of cell-changes and user-moves, for undo/redo purposes.
  List<CellChange> _cellChanges = [];

  int  selectedControl = 1;
  bool notesMode       = false;

  Puzzle({required int index})
  {
    // Create a list of puzzle speciifications in textual form.
    PuzzleTypesText puzzleList = PuzzleTypesText();

    // Get a specification of a puzzle, using the index supplied by the caller..
    List<String> puzzleMapSpec = puzzleList.puzzleTypeText(index);

    // Parse it and create the corresponding Puzzle Map, with an empty board.
    _puzzleMap = PuzzleMap(specStrings: puzzleMapSpec);

    // Initialize the lists of cells, using deep copies.
    _puzzleGiven = [..._puzzleMap.emptyBoard];
    _solution    = [..._puzzleMap.emptyBoard];
    _stateOfPlay = [..._puzzleMap.emptyBoard];
    _cellStatus  = [..._puzzleMap.emptyBoard];
  }

  CellState hitPuzzleArea(int n)
  {
    CellValue  symbol = selectedControl;
    CellStatus status = _cellStatus[n];

    // Check that the user has selected a symbol and that the cell is usable.
    if (symbol == UNUSABLE || status == UNUSABLE || status == GIVEN) {
      return CellState(UNUSABLE, UNUSABLE);
    }

    // Don't clear a cell that is already empty.
    if ((symbol == VACANT) && (_stateOfPlay[n] == VACANT)) {
      return CellState(UNUSABLE, UNUSABLE);
    }

    // Make the move. Return the status and value.
    return move(n, symbol);
  }

  CellState move(int n, CellValue symbol)
  { 
    CellStatus currentStatus = _cellStatus[n];
    CellValue  currentValue  = _stateOfPlay[n];
    CellStatus newStatus;
    CellValue  newValue;

    if (notesMode) {
      // If it is a new Note value, set the Notes bit, else copy the old Notes.
      newValue = (currentStatus != NOTES) ? NotesBit : currentValue;

      // Use an exclusive-OR to set or clear (toggle, flip) the required bit.
      newValue  = newValue ^ (1 << symbol);
      newStatus = NOTES;

      int currV  = currentValue & (NotesBit - 1);
      int newV   = newValue     & (NotesBit - 1);
      // If the last Note has been cleared, clear the whole cell-state.
      if (newValue == NotesBit) {
        newValue  = VACANT;
        newStatus = VACANT;
      }
      print('Puzzle: cell $n: new val $newV status $newStatus');
      print('Puzzle: cell $n: old val $currV status $currentStatus');
    }
    else {
      // Normal entry of a possible solution-value or a delete.
      newValue = symbol;
      if ((newValue == currentValue) || (newValue == VACANT)) {
        newValue  = VACANT;
        newStatus = VACANT;
      }
      else {
        newStatus = (newValue == _solution[n]) ? CORRECT : ERROR;
      }
    }

    CellState newState = CellState(newStatus, newValue);
    CellState oldState = CellState(currentStatus, currentValue);
    _cellChanges.add(CellChange(n, oldState, newState));
    _cellStatus[n]  = newStatus;
    _stateOfPlay[n] = newValue;
    print('NEW MOVE: cell $n status $newStatus value $newValue');
    print('StateOfPlay $_stateOfPlay');
    return newState;
  }
}
