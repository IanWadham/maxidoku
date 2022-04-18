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
  Puzzle(int index, this.settings)
  {
    createState(index);
  }

  final SettingsController settings;

  late PuzzleMap _puzzleMap;
  PuzzleMap get puzzleMap => _puzzleMap;

  late PaintingSpecs2D _paintingSpecs2D;
  late PaintingSpecs3D _paintingSpecs3D;

  PaintingSpecs2D get paintingSpecs2D => _paintingSpecs2D;
  PaintingSpecs3D get paintingSpecs3D => _paintingSpecs3D;

  void set portrait(bool b)           => (_puzzleMap.sizeZ == 1) ?
                                         _paintingSpecs2D.portrait = b :
                                         _paintingSpecs3D.portrait = b;

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
  Difficulty _difficulty = Difficulty.Easy;
  Symmetry   _symmetry   = Symmetry.RANDOM_SYM;

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
  bool multiNotes      = false;

  bool createState(int index)
  {
    // Create the state for the puzzle type the user selected.
    print('Create Puzzle: index $index hash ${hashCode}');

    // Get a list of puzzle specifications in textual form.
    PuzzleTypesText puzzleList = PuzzleTypesText();

    // Get a specification of a puzzle, using the index selected by the user.
    List<String> puzzleMapSpec = puzzleList.puzzleTypeText(index);

    // Parse it and create the corresponding Puzzle Map, with an empty board.
    _puzzleMap = PuzzleMap(specStrings: puzzleMapSpec);

    // Precalculate and save the operations for paint(Canvas canvas, Size size).
    // These are held in unit form and scaled up when the canvas-size is known.
    if (_puzzleMap.sizeZ == 1) {
      _paintingSpecs2D = PaintingSpecs2D(_puzzleMap);
      _paintingSpecs2D.calculatePainting();
    }
    else {
      _paintingSpecs3D = PaintingSpecs3D(_puzzleMap);
      _paintingSpecs3D.calculatePainting();
    }

    // Set up data structures and PuzzleMap for an empty Puzzle Board.
    _init();

    // Already painting. Do NOT call notifyListeners(): it would cause a crash.
    return true;
  }

  void _init()
  {
    // Initialize the lists of cells, using deep copies. The solution is empty
    // in case the user taps in a puzzle: it gets filled if they generate one.
    //
    // Having separate initialisation or re-initialisation for this part of the
    // Puzzle Model allows the user to generate new puzzles of the same type as
    // before, but without having to go back to the Puzzle List screen.

    _puzzleGiven = [..._puzzleMap.emptyBoard];
    _solution    = [];		// Needs to be empty if tapping in a puzzle.
    _stateOfPlay = [..._puzzleMap.emptyBoard];
    _cellStatus  = [..._puzzleMap.emptyBoard];

    _cellChanges.clear();

    // Get the user's chosen/default Difficulty and Symmetry from Settings.
    _difficulty = settings.difficulty;
    _symmetry   = settings.symmetry;
    print('Puzzle._init(): Difficulty $_difficulty, Symmetry $_symmetry');

    int  _indexUndoRedo  = 0;

    selectedControl = 1;
    notesMode       = false;
    lastCellHit     = 0;
    multiNotes      = false;

    _puzzlePlay = Play.NotStarted;
  }

  Message generatePuzzle()
  // Generate a new puzzle of the type and size selected by the user.
  // This can be re-used, without going back to the puzzle selection screen.
  {
    _init();			// Clear relevant parts of the Puzzle state.

    // TODO - Generate Roxdoku Twin, Very Easy level ===> LOOP ... Easy is OK.

    Message response = Message('', '');
    SudokuType puzzleType = _puzzleMap.specificType;
    switch (puzzleType) {
      case SudokuType.Mathdoku:
      case SudokuType.KillerSudoku:
	// Generate variants of Killer Sudoku or Mathdoku (aka KenKen TM) types.
        MathdokuGenerator mg = MathdokuGenerator(_puzzleMap);
	int maxTries = 10;
	// int maxTries = 1;	// DEBUG.
	int numTries;
        for (numTries = 1; numTries <= maxTries; numTries++) {
          _solution = _fillBoard();
          print('GENERATE $puzzleType, $_difficulty');
          if (mg.generateMathdokuKillerTypes(_puzzleGiven, _solution,
                                             _SudokuMoves, _difficulty)) {
            response.messageType = 'I';
            response.messageText = 'TESTING: MathdokuKiller generator = TRUE';
            _paintingSpecs2D.markCageBoundaries(_puzzleMap);
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
        print('GENERATE $puzzleType, $_difficulty, $_symmetry');
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

  bool triggerRepaint()
  {
    // Used by 3D View Rotation (with no Puzzle Model change).
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
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
      print('hitControlArea: Selected control $selectedControl');
      // Conditionally allow multiple entry of Notes in current Puzzle cell.
      print('NotesMode $notesMode lastCellHit $lastCellHit');
      if (notesMode && (_cellStatus[lastCellHit] == NOTES)) {
        // Cell already has a note, so OK to add more or clear existing.
        print('Call hitPuzzleCell for lastCellHit $lastCellHit');
        move(lastCellHit, selectedControl);
        multiNotes = true;
      }
    }
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  bool hitPuzzleArea(int x, int y)
  {
    // User has tapped on a puzzle-cell in 2D: use a generic handler.
    return hitPuzzleCellN(_puzzleMap.cellIndex(x, y));
  }

  bool hitPuzzleCellN(int n)
  {
    // User has tapped on a puzzle-cell in 2D or 3D: apply the rules of play.
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

    // Check that the user has selected a symbol and that the cell is usable.
    if (symbol == UNUSABLE || status == UNUSABLE || status == GIVEN) {
      return false;
    }

    if ((symbol == VACANT) && (_stateOfPlay[n] == VACANT)) {
      // Don't clear a cell that is already empty.
      return false;
    }

    if (n != lastCellHit) {
      lastCellHit = n;
      if (multiNotes) {
         multiNotes = false;
         if (notesMode) {
           // Avoid automatically repeating the last note in the previous cell,
           // but do a repaint to capture the highlight  on the new cell.
           notifyListeners();
           return false;
         }
      }
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
        newValue   = VACANT;
        newStatus  = VACANT;
        multiNotes = false;
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
        if (newStatus == CORRECT) {
          autoClearNotes(n, newValue);
          autoDimControls(n);
        }
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

  void hint()
  {
    // print('HINTS: $_SudokuMoves');		// Cell numbers in play-order.
    if(_puzzlePlay != Play.ReadyToStart && _puzzlePlay != Play.InProgress) {
      return;
    }
    for (int n in _SudokuMoves) {
      if (stateOfPlay[n] == VACANT) {
        // Move in the usual way, including Undo/Redo data and highlighting.
        bool savedNotesMode = notesMode;
        notesMode = false;		// Do not display the move as a Note.
        move(n, _solution[n]);		// Copy a move from the solution.
        notesMode = savedNotesMode;
        notifyListeners();		// Trigger a repaint of the Puzzle View.
        break;
      }
    }
    return;
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

  void autoClearNotes(int n, int newValue)
    // TODO - Does this function need to be Undoable. If so how? Would it need
    //        the Undo/Redo to handle multi-cell changes? It all seems  academic
    //        considering that the user has just made a winning move.
    //
    //        Or maybe a Redo could just redo every move from the start of play.
  {
    // print('autoClearNotes cell $n value $newValue');
    int noteBit = 1 << newValue;
    List<int> groupList = puzzleMap.groupList(n);
    for (int g in groupList) {
      for (int cell in puzzleMap.group(g)) {
        if ((cell != n) && (_cellStatus[cell] == NOTES)) {
          if ((_stateOfPlay[cell] & noteBit) != 0) {
            // Use an exclusive-OR to clear the required bit.
            _stateOfPlay[cell] = _stateOfPlay[cell] ^ noteBit;
            if (_stateOfPlay[cell] == NotesBit) {
              _stateOfPlay[cell] = VACANT;
              _cellStatus[cell]  = VACANT;
            }
          }
        }
      }
    }
  }

  void autoDimControls(int n)
  {
    // Not implemented yet.
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
