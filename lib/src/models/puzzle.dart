import 'package:flutter/foundation.dart';

import '../settings/settings_controller.dart';
import '../globals.dart';
import 'puzzle_map.dart';
import 'puzzle_types.dart';
import '../views/painting_specs_2d.dart';
import '../engines/sudoku_generator.dart';
import '../engines/sudoku_solver.dart';
import '../engines/mathdoku_generator.dart';

class CellChange
{
  int       cellIndex;		// The position of the cell that changed.
  CellState before;		// The status and value before the change.
  CellState after;		// The status and value after the change.

  CellChange(this.cellIndex, this.before, this.after);
}

class Puzzle with ChangeNotifier
{
  // Constructor.
  Puzzle();

  late PuzzleMap _puzzleMap;

  PuzzleMap get puzzleMap => _puzzleMap;

  // A stash where View widgets can find a copy of the puzzle's Painting Specs.
  PaintingSpecs _paintingSpecs = PaintingSpecs.empty();	// Dummy for compiling.

  PaintingSpecs get paintingSpecs => _paintingSpecs;
  void set paintingSpecs(PaintingSpecs p) => _paintingSpecs = p;

  // The status of puzzle-play. Determines what moves are allowed and their
  // meaning. In NotStarted status, the puzzle is set to be empty and can be
  // tapped in by the user or generated by the computer.
  Play             _puzzlePlay         =  Play.NotStarted;
  Play         get puzzlePlay          => _puzzlePlay;
  Play             _previousPuzzlePlay =  Play.NotStarted;
  Play         get previousPuzzlePlay  => _previousPuzzlePlay;

  // The starting position of the puzzle, +ve integers. Stays fixed during play.
  BoardContents    _puzzleGiven = [];

  // The full solution of the puzzle, +ve integers. Stays fixed during play.
  BoardContents    _solution    = [];
  List<int>        _SudokuMoves = [];	// Move-list for Sudoku hints.

  // Current values of each cell, which may be +ve integers or bitmaps of Notes.
  BoardContents    _stateOfPlay = [];
  BoardContents get stateOfPlay => _stateOfPlay;

  // The required difficulty and symmetry of the puzzle to be generated.
  // Note that symmetry is not supported in 3D, Mathdoku and Killer Sudoku.
  // Difficulty _difficulty = Difficulty.Diabolical;
  Difficulty _difficulty = Difficulty.Easy;
  Symmetry   _symmetry   = Symmetry.NONE;

  // The current status of each cell.
  // Possible values are UNUSABLE, VACANT, GIVEN, CORRECT, ERROR and NOTES.
  BoardContents    _cellStatus  = [];
  BoardContents get cellStatus => _cellStatus;

  // The sequence of cell-changes and user-moves, for undo/redo purposes.
  List<CellChange> _cellChanges = [];

  // Index ranges from 0 to the number of undoable moves that have been made,
  // which is the length of the _cellChanges list. If 0, either no moves have
  // been made yet or all the moves have been undone. If equal to the number
  // of undoable moves, then all moves have been done or redone and Redo is
  // not valid. 
  int  _indexUndoRedo  = 0;

  int  selectedControl = 1;
  bool notesMode       = false;
  int  lastCellHit     = 0;

  bool createState(int index)
  {
    // Create the state for the puzzle type the user selected.
    print('Create Puzzle: index $index hash ${hashCode}');

    // Create a list of puzzle specifications in textual form.
    PuzzleTypesText puzzleList = PuzzleTypesText();

    // Get a specification of a puzzle, using the index supplied via the user.
    List<String> puzzleMapSpec = puzzleList.puzzleTypeText(index);

    // Parse it and create the corresponding Puzzle Map, with an empty board.
    _puzzleMap = PuzzleMap(specStrings: puzzleMapSpec);

    // Set up data structures and PuzzleMap for an empty Puzzle Board.
    _init();

    // Already repainting. Do NOT do notifyListeners(): it would cause a crash.
    return true;
  }

  void _init()
  {
    // Initialize the lists of cells, using deep copies. The solution is empty
    // in case the user taps in a puzzle: it gets filled if they generate one.
    _puzzleGiven = [..._puzzleMap.emptyBoard];
    _solution    = [];		// Needs to be empty if tapping in a puzzle.
    _stateOfPlay = [..._puzzleMap.emptyBoard];
    _cellStatus  = [..._puzzleMap.emptyBoard];

    _cellChanges.clear();

    // TODO - Get/set these in Settings. Prompt the user.
    Difficulty _difficulty = Difficulty.Diabolical;
    Symmetry   _symmetry   = Symmetry.NONE;

    int  _indexUndoRedo  = 0;

    int  selectedControl = 1;
    bool notesMode       = false;
    int  lastCellHit     = 0;

    _puzzlePlay = Play.NotStarted;
  }

  Message generatePuzzle()
  // Generate a new puzzle of the type and size selected by the user.
  // This can be re-used, without going back to the puzzle selection screen.
  {
    _init();			// Clear the state of the Puzzle.

    Message response = Message('', '');
    SudokuType puzzleType = _puzzleMap.specificType;
    switch (puzzleType) {

      case SudokuType.Roxdoku:
        // 3-D puzzles are not yet supported in Flutter and Multidoku.
        // TODO - When they are, they can be generated by the "default:" branch
        //        below, but should have a 3D CustomPainter() in the view.
        response.messageType = 'W';		// Warning.
        response.messageText = 'Roxdoku (3-D) puzzles not yet supported.';
        return response;			// Convey the message.
        // notifyListeners();	// If puzzle OK.
        break;

      case SudokuType.Mathdoku:
      case SudokuType.KillerSudoku:
	// Generate variants of Killer Sudoku or Mathdoku (aka KenKen TM) types.
        MathdokuGenerator mg = MathdokuGenerator(_puzzleMap);
	// int maxTries = 10;	// TODO - RESTORE THIS !!!!!!!!!
	int maxTries = 1;
	int numTries;
        for (numTries = 1; numTries <= maxTries; numTries++) {
          _solution = _fillBoard();
          if (mg.generateMathdokuKillerTypes(_puzzleGiven, _solution,
                                             _SudokuMoves, _difficulty)) {
            response.messageType = 'I';
            response.messageText = 'TESTING: MathdokuKiller generator = TRUE';
            _paintingSpecs.markCageBoundaries(_puzzleMap);
            break;
          } 
        }
        if (response.messageType == '') {
          // Used up max tries and found no valid puzzle.
          response.messageType = 'Q';		// Warning.
          response.messageText = 'Attempts to generate a puzzle failed after'
                                 ' about 200 tries. Try again?';
        }
        else {
          // Valid puzzle found: move single-cell cage-values to _puzzleGiven.
          for (int cageNum = 0; cageNum < _puzzleMap.cageCount(); cageNum++) {
            List<int> cage = _puzzleMap.cage(cageNum);
            if (cage.length == 1) {
              int cell = cage[0];
              _puzzleGiven[cell] = _solution[cell];
              print('Cage $cageNum $cage cell $cell value ${_solution[cell]}');
            }
          }
          // Cages have been added to PuzzleMap. Move to ReadyToPlay status.
          makeReadyToPlay();
          notifyListeners();		// Trigger a repaint of the Puzzle View.
        }
        return response;
        break;

      default:
	// Generate variants of Sudoku (2D) and Roxdoku (3D) types.
        SudokuGenerator srg = SudokuGenerator(_puzzleMap);
	response = srg.generateSudokuRoxdoku(_puzzleGiven, _solution,
                                             _SudokuMoves,
                                             _difficulty, _symmetry);
        if (response.messageType != 'F') {	// Succeeded - up to a point...
          makeReadyToPlay();
          notifyListeners();		// Trigger a repaint of the Puzzle View.
        }
        else {				// FAILED. Please try again.
          // Generator/solver may have failed internally.
        }
        return response;
        break;
    }
  }

  void makeReadyToPlay()
  {
    // print('_puzzleGiven $_puzzleGiven');
    _stateOfPlay = [..._puzzleGiven];
    for (int n = 0; n < _puzzleGiven.length; n++) {
      if ((_puzzleGiven[n] > 0) && (_puzzleGiven[n] != UNUSABLE)) {
        _cellStatus[n] = GIVEN;
      }
    }
    _cellChanges.clear();			// No moves made yet.
    print('PUZZLE\n');
    _puzzleMap.printBoard(_stateOfPlay);
    // print('Cell statuses $_cellStatus');
    print('Cell changes  $_cellChanges');

    // Change the Puzzle Play status to receive solving moves.
    _puzzlePlay = Play.ReadyToStart;
    // TODO - Start clock, but only AFTER user has replied to message.
  }

  BoardContents _fillBoard()
  {
    // This is in a function so that "solver" will release resources as soon
    // as possible, in cases when the Mathdoku/Killer-Sudoku generator runs.
    print('In Puzzle._fillBoard(): SudokuSolver about to be created.');
    SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap);
    return solver.createFilledBoard();
  }

  int checkPuzzle()
  {
    // Check that a puzzle tapped in or loaded by user has a proper solution.
    // Returns 0 if solution is OK, -1 if no solution, -3 if solution not unique
    // or -2 if puzzle and solution loaded from a file are not self-consistent.
    print('ENTERED checkPuzzle().');
    SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap);
    int error = 0;
    error = solver.checkSolutionIsValid (_stateOfPlay, _solution);
    if (error != 0) {
      return error;
    }
    error = solver.checkSolutionIsUnique(_stateOfPlay, _solution);
    return error;
  }

  void convertDataToPuzzle()
  {
    print('ENTERED convertDataToPuzzle().');
    _puzzleGiven = [..._stateOfPlay];
    for (int n = 0; n < _puzzleGiven.length; n++) {
      if ((_puzzleGiven[n] > 0) && (_puzzleGiven[n] != UNUSABLE)) {
        _cellStatus[n] = GIVEN;
      }
    }
    SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap);
    _solution = solver.solveBoard (_puzzleGiven, GuessingMode.Random);
    _cellChanges.clear();			// No moves made yet.
    _puzzlePlay = Play.ReadyToStart;
    notifyListeners();
  }

  bool hitControlArea(int selection)
  {
    // User has tapped on the control area, to choose a symbol (1-9, A-Y)
    // to enter, to switch Notes mode or to set Delete (or Erase) mode.
    bool hideNotes = (puzzlePlay == Play.NotStarted) ||
                     (puzzlePlay == Play.BeingEntered);
    print('hitControlArea: selection $selection, hideNotes $hideNotes');
    if (! hideNotes && (selection == 0)) {
      notesMode = !notesMode;	// Switch Notes mode, but only when solving.
      print('Switched Notes to $notesMode');
    }
    else {
      // The value selected is treated as a cell-value, a note or an erase.
      selectedControl = selection - (hideNotes ? 0 : 1);
      print('Selected control $selectedControl');
      // TODO - Allow multiple entry of Notes in current Puzzle cell.
    }
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  bool hitPuzzleArea(int x, int y)
  {
    // User has tapped on  a puzzle-cell: implement the rules of play.
    int n = _puzzleMap.cellIndex(x, y);
    if (_puzzlePlay == Play.Solved) {
      // The Puzzle has been solved: only undo/redo  moves are allowed.
      // The user can also generate a new Puzzle or Quit/Save, etc.
      return false;
    }
    else if (_puzzlePlay == Play.HasError) {
      // Allow moves to correct the error(s) in a potential solution.
      _puzzlePlay = Play.InProgress;
    }

    CellValue  symbol = selectedControl;
    CellStatus status = _cellStatus[n];

    if (symbol == UNUSABLE || status == UNUSABLE || status == GIVEN) {
      // Check that the user has selected a symbol and that the cell is usable.
      return false;
    }

    if ((symbol == VACANT) && (_stateOfPlay[n] == VACANT)) {
      // Don't clear a cell that is already empty.
      return false;
    }

    _previousPuzzlePlay = _puzzlePlay;	// In case the move changes the Play.

    if ((_puzzlePlay == Play.ReadyToStart) && (symbol != VACANT)) {
      // Change the Puzzle Play status to show that solving has started.
      _puzzlePlay = Play.InProgress;	// First move in solving a Puzzle.
    }

    if ((_puzzlePlay == Play.NotStarted) && (symbol != VACANT)) {
      // Maybe this is the First move when tapping in a Puzzle.
      // Change the Puzzle Play status to BeingEntered. The user will be asked
      // about this, but not until we are back in the Puzzle View and the widget
      // building flow. Issuing a message any earlier makes Flutter crash.
      _puzzlePlay = Play.BeingEntered;
    }

    // Attempt to make the move. Return the status and value of the cell.
    CellState c =  move(n, symbol);

    if ((_puzzlePlay == Play.InProgress) && (c.status == CORRECT)) {
      // If all cells are now filled, change the Puzzle Play status to Solved or      // HasError: otherwise leave it at InProgress. If Solved, no more moves
      // are allowed: only undo/redo (to review the moves).
      _puzzlePlay = _isPuzzleSolved();

      // TODO - Stop the clock when changing to Solved status.
    }
    // The move has been accepted and made.
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  CellState move(int n, CellValue symbol)
  { 
    // Make a move and update the state of the Puzzle cell.
    CellStatus currentStatus = _cellStatus[n];
    CellValue  currentValue  = _stateOfPlay[n];
    CellStatus newStatus;
    CellValue  newValue;

    if (symbol == VACANT) {
      // This a delete of a symbol or of one or more notes in a cell.
      newValue  = VACANT;
      newStatus = VACANT;
    }
    else if (notesMode) {
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
      if (newValue == currentValue) {
        // Entering a value a second time clears the cell.
        newValue  = VACANT;
        newStatus = VACANT;
      }
      else if (_puzzlePlay == Play.BeingEntered) {
        // Let the user go on tapping in a puzzle, until checkPuzzle() is used.
        newStatus = CORRECT;
      }
      else {
        // If puzzle exists and has a solution, check for incorrect moves.
        newStatus = ((newValue != _solution[n]) && (_solution[n] != VACANT)) ?
                     ERROR : CORRECT;
      }
    }

    // TODO - TEST various combinations of move, erase, prune & undo/redo.
    // TODO - New move: prune _cellChanges list, unless new move == undone???

    CellState newState = CellState(newStatus, newValue);
    CellState oldState = CellState(currentStatus, currentValue);

    int nCellChanges = _cellChanges.length;
    if (_indexUndoRedo < nCellChanges) {
      // Prune the list of cell changes (i.e. list of undo/redo possibilities).
      print('PRUNE _indexUndoRedo $_indexUndoRedo nCellChanges $nCellChanges');
      _cellChanges.removeRange(_indexUndoRedo, nCellChanges - 1);
    }

    // Update the undo/redo list and record the move.
    _cellChanges.add(CellChange(n, oldState, newState));
    _indexUndoRedo     = _cellChanges.length;
    _cellStatus[n]     = newStatus;
    _stateOfPlay[n]    = newValue;

    print('NEW MOVE: cell $n status $newStatus value $newValue changes'
          ' ${_cellChanges.length} Undo/Redo $_indexUndoRedo');
    // print('StateOfPlay $_stateOfPlay');
    lastCellHit = n;
    return newState;
  }

  Play _isPuzzleSolved()
  {
    // Check whether all playable cells are filled, with or without error(s).
    bool hasError = false;
    for (int n = 0; n < _solution.length; n++) {
      if (_cellStatus[n] == ERROR) {
        hasError = true;
      }
      if ((_cellStatus[n] == VACANT) || (_cellStatus[n] == NOTES)) {
        // Not finished yet: found Notes or an empty cell.
        return _puzzlePlay;
      }
      if (_stateOfPlay[n] != _solution[n]) {
        hasError = true;
        _cellStatus[n] = ERROR;
      }
    }

    // All cells have been filled now.
    return hasError ? Play.HasError : Play.Solved;
  }

  bool isPlayUnchanged()
  {
    // Helper for Puzzle View, to decide what messages to issue and when.
    bool isChanged = (_puzzlePlay != _previousPuzzlePlay);
    if (isChanged) {
      _previousPuzzlePlay = _puzzlePlay;	// Don't repeat this result.
      return false;				// Play status changed.
    }
    return true;				// Play status is unchanged.
  }

  bool undo() {
    // Undo a move.
    int l = _cellChanges.length;
    print('UNDO: _indexUndoRedo = $_indexUndoRedo, cell-changes $l');
    if (_indexUndoRedo <= 0) {
      print('NO MOVES available to Undo');
      return false;		// No moves left to undo - or none made yet.
    }

    // Get details of the move to be undone and apply them.
    _indexUndoRedo--;
    CellChange change = _cellChanges[_indexUndoRedo];
    int n = change.cellIndex;
    _cellStatus[n]  = change.before.status;
    _stateOfPlay[n] = change.before.cellValue;
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  bool redo() {
    // Redo a move.
    int l = _cellChanges.length;
    print('REDO: _indexUndoRedo = $_indexUndoRedo, cell-changes $l');
    if (_indexUndoRedo >= _cellChanges.length) {
      print('NO MOVES available to Redo');
      return false;		// No moves left to redo - or none made yet.
    }

    // Get details of the move to be redone and apply them.
    CellChange change = _cellChanges[_indexUndoRedo];
    int n = change.cellIndex;
    _cellStatus[n]  = change.after.status;
    _stateOfPlay[n] = change.after.cellValue;
    _indexUndoRedo++;
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  void testPuzzle() {
    SudokuGenerator generator = SudokuGenerator(_puzzleMap);
    BoardContents puzzle = [];
    BoardContents solution = [];
    generator.generateSudokuRoxdoku(puzzle,
                                    solution,
                                    _SudokuMoves,
                                    Difficulty.Easy,
                                    Symmetry.SPIRAL);
    return;
    // print('TEST Puzzle class');
    // print(boardValues);
    print('');
    BoardContents _testBoard = []; // = boardValues;
    for (int n = 0; n < _puzzleMap.size; n++) {
      _testBoard.add(_stateOfPlay[n]);
      // _testBoard[n] = _stateOfPlay[n];
      // if (boardValues[n] > 0) {
        // _cellStatus[n] = GIVEN;
      // }
    }
    // paintingSpecs.cellBackG = _cellStatus;
    _puzzleMap.printBoard(_testBoard);

    // _setUpValueRequirements (board);
    // _deduceValues (board);
    // print('RETURNED FROM _deduceValues');
    /* ---------------------------------------------------------- */
    SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap);
    /* ---------------------------------------------------------- */
    Stopwatch sw = Stopwatch();
    sw.start();
    /* ---------------------------------------------------------- */
    _testBoard = solver.solveBoard(_testBoard, GuessingMode.Random);
    /* ---------------------------------------------------------- */
    print('RETURNED FROM solveBoard');
    _puzzleMap.printBoard(_testBoard);
    // TODO - If _testBoard is empty, NO SOLUTION.
    //        If not, need to enter solver again and check for >1 solution.
    // TODO - If solution is unique and accepted by user, set up the lists for
    //        _puzzleGiven, _solution, _stateOfPlay and _cellStatus. Then actual
    //        play can begin...
 
    // int result = solver.checkPuzzle(_testBoard); // TODO - IMPLEMENT THIS.
    // print('Solver RESULT = $result');
    // print('ELAPSED TIME (msec)');
    // print (sw.elapsedMilliseconds);
    // for (int n = 0; n < 1; n++) {
      /* --------------------------- */
      /* solver.createFilledBoard(); */
      /* --------------------------- */
    // }
    // print('ELAPSED TIME (msec)');
    // print (sw.elapsedMilliseconds);
    return;
  }
}
