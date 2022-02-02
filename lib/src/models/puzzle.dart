import 'dart:math';
import '../settings/settings_controller.dart';
import '../globals.dart';
import 'puzzle_map.dart';
import 'puzzle_types.dart';
import '../views/painting_specs_2d.dart';
import '../engines/sudoku_generator.dart';
import '../engines/sudoku_solver.dart';

class CellChange
{
  int       cellIndex;		// The position of the cell that changed.
  CellState before;		// The status and value before the change.
  CellState after;		// The status and value after the change.

  CellChange(this.cellIndex, this.before, this.after);
}

class Puzzle
{
  late PuzzleMap _puzzleMap;

  PuzzleMap get puzzleMap => _puzzleMap;

  // Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  Random _random = Random(266133);	// Fixed seed: no sophistication needed.

  // A stash where View widgets can find a copy of the puzzle's Painting Specs.
  PaintingSpecs _paintingSpecs = PaintingSpecs.empty();	// Dummy for compiling.

  PaintingSpecs get paintingSpecs => _paintingSpecs;
  void set paintingSpecs(PaintingSpecs p) => _paintingSpecs = p;

  // The status of puzzle-play. Determines what moves are allowed and their
  // meaning. In NotStarted status, the puzzle is set to be empty and can be
  // tapped in by the user or generated by the computer.
  Play             _puzzlePlay  =  Play.NotStarted;
  Play         get puzzlePlay   => _puzzlePlay;

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
  Difficulty _difficulty = Difficulty.Diabolical;
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

  Puzzle(int index)				// Create selected puzzle type.
  {
    print('Create Puzzle: index $index hash ${hashCode}');

    // Create a list of puzzle specifications in textual form.
    PuzzleTypesText puzzleList = PuzzleTypesText();

    // Get a specification of a puzzle, using the index supplied via the user.
    List<String> puzzleMapSpec = puzzleList.puzzleTypeText(index);

    // Parse it and create the corresponding Puzzle Map, with an empty board.
    _puzzleMap = PuzzleMap(specStrings: puzzleMapSpec);

    _init();
  }

  void _init()
  {
    // Initialize the lists of cells, using deep copies.
    _puzzleGiven = [..._puzzleMap.emptyBoard];
    _solution    = [..._puzzleMap.emptyBoard];
    _stateOfPlay = [..._puzzleMap.emptyBoard];
    _cellStatus  = [..._puzzleMap.emptyBoard];

    _cellChanges.clear();

    Random _random = Random(DateTime.now().millisecondsSinceEpoch);

    // TODO - Get/set these in Settings. Prompt the user.
    Difficulty _difficulty = Difficulty.Diabolical;
    Symmetry   _symmetry   = Symmetry.NONE;

    int  _indexUndoRedo  = 0;

    int  selectedControl = 1;
    bool notesMode       = false;
    int  lastCellHit     = 0;

    _puzzlePlay = Play.NotStarted;
  }

  // Generate a new puzzle of the type and size selected by the user.
  void generatePuzzle()
  {
    _init();

    SudokuType puzzleType = _puzzleMap.specificType;
    switch (puzzleType) {
      case SudokuType.Roxdoku:
        // 3D puzzles not yet supported in Flutter and Multidoku.
        // TODO - When they are, they can be generated by the "default:" branch
        //        below, but should have a 3D CustomPainter() in the view.
        // TODO - Issue a message.
        return;
      case SudokuType.Mathdoku:
      case SudokuType.KillerSudoku:
	// Generate variants of Killer Sudoku or Mathdoku (aka KenKen TM) types.
        // MathdokuGenerator mg = MathdokuGenerator(_puzzleMap);
	// int maxTries = 10;
	// int numTries;
        // for (numTries = 1; numTries <= maxTries; numTries++) {
          // _solution = _fillBoard();
          // if (mg.generateMathdokuKiller(_puzzleGiven, _solution, _SudokuMoves,
                                        // _difficulty)) {
            // return;
          // } 
        // }
        // TODO - Issue a message.
		// QWidget owner;
		// if (KMessageBox::questionYesNo (&owner,
			    // i18n("Attempts to generate a puzzle failed after "
				 // "about 200 tries. Try again?"),
			    // i18n("Mathdoku or Killer Sudoku Puzzle"))
			    // == KMessageBox::No) {
		    // return false;	// Go back to the Welcome screen.
		// }
		// numTries = 0;		// Try again.
        break;
      default:
	// Generate variants of Sudoku (2D) and Roxdoku (3D) types.
        SudokuGenerator srg = SudokuGenerator(_puzzleMap);
	bool success = srg.generateSudokuRoxdoku(_puzzleGiven, _solution,
                                                 _SudokuMoves,
                                                 _difficulty, _symmetry);
        if (success) {
          // print('_puzzleGiven $_puzzleGiven');
          _stateOfPlay = [..._puzzleGiven];
          for (int n = 0; n < _puzzleGiven.length; n++) {
            if ((_puzzleGiven[n] > 0) && (_puzzleGiven[n] != UNUSABLE)) {
              _cellStatus[n] = GIVEN;
            }
          }
          _cellChanges.clear();		// No moves made yet.
          print('PUZZLE\n');
          _puzzleMap.printBoard(_stateOfPlay);
          // print('Cell statuses $_cellStatus');
          print('Cell changes  $_cellChanges');
          _puzzlePlay = Play.ReadyToStart;
        }
        else {
          // TODO - Issue messages.
          //        Generator could have failed internally OR the user could
          //        have rejected the best puzzle that was generated.
          _puzzlePlay = Play.NotStarted;
          return;
        }
    }
    _puzzlePlay = Play.ReadyToStart;
    return;
  }

  BoardContents _fillBoard()
  {
    // This is in a function so that "solver" will release resources as soon
    // as possible, in cases when the Mathdoku/Killer-Sudoku generator runs.
    SudokuSolver solver = SudokuSolver(puzzleMap: _puzzleMap);
    return solver.createFilledBoard();
  }

  // Check the validity of a puzzle tapped in by the user.
  void checkPuzzle()
  {
  }

  CellState hitPuzzleArea(int n)		// User has hit a puzzle-cell.
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

    if ((_puzzlePlay == Play.ReadyToStart) && (symbol != VACANT)) {
      _puzzlePlay = Play.InProgress;	// First move in solving a Puzzle.
    }

    // Make a move. Return the status and value.
    return move(n, symbol);
  }

  CellState move(int n, CellValue symbol)	// Update the Puzzle state.
  { 
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
        // TODO - TEST various combinations of move, erase, prune & undo/redo.
        newValue  = VACANT;
        newStatus = VACANT;
        // Don't treat this as an Erase... TODO - Reinstate Erase behaviour.
        // return CellState(currentStatus, currentValue);
      }
      else {
        // If puzzle exists and has been solved, check for errors, otherwise
        // allow entry of a puzzle without error-checking, until checkPuzzle().
        newStatus = ((newValue != _solution[n]) && (_solution[n] != VACANT)) ?
                     ERROR : CORRECT;
      }
    }

    CellState newState = CellState(newStatus, newValue);
    CellState oldState = CellState(currentStatus, currentValue);
    // TODO - New move: prune _cellChanges list, unless new move == undone???
    int nCellChanges = _cellChanges.length;
    if (_indexUndoRedo < nCellChanges) {
      print('PRUNE _indexUndoRedo $_indexUndoRedo nCellChanges $nCellChanges');
      _cellChanges.removeRange(_indexUndoRedo, nCellChanges - 1);
    }
    _cellChanges.add(CellChange(n, oldState, newState));
    _indexUndoRedo     = _cellChanges.length;
    _cellStatus[n]     = newStatus;
    _stateOfPlay[n]    = newValue;

    print('NEW MOVE: cell $n status $newStatus value $newValue changes ${_cellChanges.length} Undo/Redo $_indexUndoRedo');
    // print('StateOfPlay $_stateOfPlay');
    lastCellHit = n;
    return newState;
  }

  bool undo() {					// Undo a move.
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
    return true;
  }

  bool redo() {					// Redo a move.
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
