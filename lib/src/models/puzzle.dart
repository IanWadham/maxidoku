import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../settings/settings_controller.dart';

import '../globals.dart';
import 'puzzle_map.dart';
import 'puzzle_types.dart';

import 'game_timer.dart';

import '../engines/sudoku_generator.dart';
import '../engines/sudoku_solver.dart';
import '../engines/mathdoku_generator.dart';

import '../layouts/board_layout_2d.dart';
// import '../layouts/board_layout_3d.dart';

class Puzzle with ChangeNotifier
{
  // Constructor.
  Puzzle(int index, this.settings)
  {
    createState(index);
  }

  final SettingsController settings;

  late PuzzleMap     _puzzleMap;
  late BoardLayout2D _boardLayout2D;
  // ?????? late BoardLayout3D _boardLayout3D;

  // Layout data for 2D Puzzles: stays empty in 3D, set ONCE in Puzzle lifetime.
  List<int>       _edgesEW = [];	// East-West edges of cells in 2D.
  List<int>       _edgesNS = [];	// North-South edges of cells in 2D.
  BoardContents   _cellColorCodes = [];	// Codes for colours to paint cells.
  List<List<int>> _cagePerimeters = [];	// Cage-layouts for Mathdoku and Killer.

  // TODO - Insert 3D layout data here...

  PuzzleMap       get puzzleMap      => _puzzleMap;
  List<int>       get edgesEW        => _edgesEW;
  List<int>       get edgesNS        => _edgesNS;
  BoardContents   get cellColorCodes => _cellColorCodes;
  List<List<int>> get cagePerimeters => _cagePerimeters;

  Message delayedMessage = Message('', '');

  int _firstTimeCount = 2;	// Skip 2 notifyListeners() during first build.

  bool firstBuild()
  {
    if (_firstTimeCount <= 0) {
      return false;
    }
    _firstTimeCount--;
    return true;		// Avoid errors in first build of PuzzleView.
  }

  bool createState(int index)
  {
    // Create the layout, clues and model for the puzzle type the user selected.
    debugPrint('Create Puzzle: index $index hash $hashCode');

    // TODO - Could do the string-handling in PuzzleMap and just pass it index.
    // Get a list of puzzle specifications in textual form.
    PuzzleTypesText puzzleList = PuzzleTypesText();

    // Get a specification of a puzzle, using the index selected by the user.
    List<String> puzzleMapSpec = puzzleList.puzzleTypeText(index);

    // Parse it and create the corresponding Puzzle Map, with an empty board.
    _puzzleMap = PuzzleMap(specStrings: puzzleMapSpec);

    // The only time the Board Layout is calculated in the lifetime of a Puzzle.
    if (_puzzleMap.sizeZ == 1) {
      BoardLayout2D _boardLayout2D = BoardLayout2D(_puzzleMap);
      _boardLayout2D.calculateLayout(_edgesEW, _edgesNS, _cellColorCodes);
    }
    else {
      // BoardLayout3D _boardLayout3D = BoardLayout3D(_puzzleMap);
      // _boardLayout3D.calculateLayout();
    }

    // Start by generating a puzzle and a delayed message. Maybe the users
    // can tap an icon button or message reply if they wish to tap in a puzzle.
    // _puzzlePlayer = PuzzlePlayer(_puzzleMap, this)
    // generatePuzzle(puzzlePlayer);		// ???????? generatePuzzle();

    // NOTE - Flutter is already painting. Issuing a message right now causes
    //        a crash and calling notifyListeners() also causes Flutter errors.
    //        The delayed message will appear in PuzzleView.executeAfterBuild().
    return true;
  }

  void generatePuzzle(PuzzlePlayer puzzlePlayer)
  {
    PuzzleGenerator generator = PuzzleGenerator();

    // Generate a puzzle of the required layout type, difficulty and symmetry.
    // Note that symmetry is not supported in 3D, Mathdoku and Killer Sudoku.
    // The result-message either informs the user about the puzzle generated or
    // asks whether to Accept or Retry, if the requirements have not been met.
    // The message is stashed, in case the Puzzle View is currently painting.

    delayedMessage = generator.generatePuzzle(
                                 _puzzleMap, puzzlePlayer,
                                 settings.difficulty, settings.symmetry);

    if(_puzzleMap.cageCount() > 0) {
      BoardLayout2D _boardLayout2D = BoardLayout2D(_puzzleMap);
      _cagePerimeters.clear();	// Get the cage-layouts for Mathdoku and Killer.
      _boardLayout2D.calculateCagesLayout(_puzzleMap, _cagePerimeters);
    }

    if (firstBuild()) {
      return;		// Avoid notifyListeners() during Flutter's first build.
    }
    notifyListeners();	// Else make sure PuzzleView issues the delayedMessage.
  }

} // End Puzzle class.

class PuzzleGenerator
{
  // Generate a puzzle of the required layout type, difficulty and symmetry.
  // Note that symmetry is not supported in 3D, Mathdoku and Killer Sudoku.

  PuzzleGenerator();

  // Below are the results of generating a puzzle. Note that these lists are
  // the only Properties of the Puzzle Generator. It consumes (briefly) an
  // enormous share of CPU time and memory, so everything is done inside
  // functions and procedures, here or in Engine objects, so that all memory
  // should get released after all the calculation is done or the generator
  // has made a number of attempts to meet the user's requirementsr. Then it
  // is time to ask them to accept the best result so far - or try again.

  // That situation is more likely to arise if the Difficulty and Symmetry
  // are high or the puzzle-type is large and complex.

  BoardContents _puzzleGiven  = [];	// Starting state of generated puzzle.
  BoardContents _solution     = [];	// Finishing state of generated puzzle.
  List<int>     _sudokuMoves  = [];	// Move-list: for hints.

  Message generatePuzzle(PuzzleMap puzzleMap, PuzzlePlayer puzzlePlayer,
                         Difficulty difficulty, Symmetry symmetry)
  // Generate a new puzzle of the type and size selected by the user.
  {
    // Clear the Puzzle state. Make THIS._puzzleGiven (above) an empty board.
    puzzlePlayer.initialise();
    _puzzleGiven = [...puzzleMap.emptyBoard];

    Message response = Message('', '');
    SudokuType puzzleType = puzzleMap.specificType;
    switch (puzzleType) {
      case SudokuType.Mathdoku:
      case SudokuType.KillerSudoku:
	// Generate variants of Killer Sudoku or Mathdoku (aka Kenken TM) types.
        MathdokuKillerGenerator mg = MathdokuKillerGenerator(puzzleMap);
	int maxTries = 10;
        debugPrint('GENERATE $puzzleType, $difficulty');
        for (int numTries = 1; numTries <= maxTries; numTries++) {
          // Try up to 10 different starting-solutions.
          _solution = _fillBoard(puzzleMap);
          response  = mg.generateMathdokuKillerTypes(_puzzleGiven, _solution,
                                                     _sudokuMoves, difficulty);
          if ((response.messageType != '') && (response.messageType != 'F')) {
            break;
          }
        }
        if (response.messageType == '') {
          // Used up max tries with no valid puzzle - 10 solutions x 20 tries.
          // TODO - There IS no puzzle to Accept... Try again or go back to menu
          //        or change the Difficulty... ???????
          response.messageType = 'F';		// Warning.
          response.messageText = 'Attempts to generate a puzzle failed after'
                                 ' about 200 tries.';
        }
        break;
      default:
	// Generate Sudoku (2D) and Roxdoku (3D) types - and all their variants.
        SudokuGenerator srg = SudokuGenerator(puzzleMap);
        debugPrint('GENERATE $puzzleType, $difficulty, $symmetry');
	response = srg.generateSudokuRoxdoku(_puzzleGiven, _solution,
                                             _sudokuMoves,
                                             difficulty, symmetry);
        break;
    }

    debugPrint('_puzzleGiven = $_puzzleGiven');
    debugPrint('_solution    = $_solution   ');
    // debugPrint('_sudokuMoves = $_sudokuMoves');

    if (response.messageType != 'F') {	// Succeeded - up to a point maybe...
      puzzlePlayer.makeReadyToPlay(_puzzleGiven, _solution, _sudokuMoves);
      // PuzzlePlayer calls notifyListeners() and the puzzle clues appear...

      // Release PuzzleGenerator storage.
      _puzzleGiven.clear();
      _solution.clear();
      _sudokuMoves.clear();
    }
    else {				// FAILED. Please try again.
      debugPrint('In PuzzleGenerator class: Puzzle generation failed');
    }
    return response;
  }

  BoardContents _fillBoard(PuzzleMap puzzleMap)
  {
    // This is in a function so that "solver" will release resources as soon
    // as possible, in cases when the Mathdoku/Killer-Sudoku generator runs.
    // Both generators use it to fill the board with values that satisfy the
    // constraints of the type of puzzle selected. These values will become
    // the solution to the puzzle that is generatedi from them.

    SudokuSolver solver = SudokuSolver(puzzleMap: puzzleMap);
    return solver.createFilledBoard();	// createFilledBoard() does cleanup().
  }

  /*
   * Check that a puzzle is soluble, has the desired solution and has only one
   * solution.  This method can be used to check puzzles loaded from a file or
   * entered manually, in which case the solution parameter can be omitted. It
   * is also used to check a puzzle tapped in by the user.
   *
   * @return              The result of the check, with values as follows:
   * @retval >= 0         The difficulty of the puzzle, approximately, after
   *                      one solver run.  If there are guesses, the
   *                      difficulty can vary from one run to another,
   *                      depending on which guesses are randomly chosen.
   * @retval -1           No solution.
   * @retval -2           Wrong solution.
   * @retval -3           More than one solution.
   */
/* ********************* TEMPORARILY DISABLED BACK IN PuzzleView...
  int checkPuzzle(PuzzleMap puzzleMap, PuzzlePlayer puzzlePlayer)
  {
    // Check that a puzzle tapped in or loaded by user has a proper solution.
    debugPrint('ENTERED checkPuzzle().');
    SudokuSolver solver = SudokuSolver(puzzleMap: puzzleMap);
    BoardContents stateOfPlay = puzzlePlayer.stateOfPlay;
    int error = 0;
    error = solver.checkSolutionIsValid (stateOfPlay, _solution);
    if (error != 0) {
      return error;
    }
    // TODO - It would be nice if we could return a Difficulty index >= 0.
    error = solver.checkSolutionIsUnique(stateOfPlay, _solution);
    solver.cleanUp();
    return error;
  }
*/

} // End PuzzleGenerator class.

class CellChange
{
  int       cellIndex;		// The position of the cell that changed.
  CellState after;		// The status and value after the change.

  CellChange(this.cellIndex, this.after);
}

class PuzzlePlayer with ChangeNotifier
{
  PuzzleMap _puzzleMap;
  Puzzle    _puzzle;

  PuzzlePlayer(this._puzzleMap, this._puzzle)
  {
    initialise();
  }

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
  List<int>        _sudokuMoves = [];	// Move-list for Sudoku hints.

  // Current values of each cell, which may be +ve integers or bitmaps of Notes.
  BoardContents    _stateOfPlay = [];
  BoardContents get stateOfPlay => _stateOfPlay;
  BoardContents get solution => _solution;	// TODO - Testing ONLY...

  int cellValue(int n)
  {
    return _stateOfPlay[n];
  }

  // The current status of each cell.
  // Possible values are UNUSABLE, VACANT, GIVEN, CORRECT, ERROR and NOTES.
  BoardContents    _cellStatus  = [];
  BoardContents get cellStatus => _cellStatus;

  // The sequence of cell-changes and user-moves, for undo/redo purposes.
  final List<CellChange> _cellChanges = [];

  // Index ranges from 0 to the number of undoable moves that have been made,
  // which is the length of the _cellChanges list. If 0, either no moves have
  // been made yet or all the moves have been undone. If equal to the number
  // of undoable moves, then all moves have been done or redone and Redo is
  // not valid.
  int  _indexUndoRedo  = 0;

  int  selectedControl = 1;
  int? selectedCell;		// Null means no valid cell to play.
  bool notesMode       = false;

  // The View's interface to the Game Timer.
  // The time appears (optionally) in the PuzzleView screen once per second.
  // The clock is started by user's response to a message in PuzzleBoardView.
  // It stops when the user finishes the puzzle or abandons it. It is reset to
  // zero by PuzzlePlayer.initialise().

  GameTimer  _puzzleTimer    =  GameTimer();
  String get userTimeDisplay => _puzzleTimer.userTimeDisplay;
  void       startClock()    => _puzzleTimer.startClock();

  void initialise()
  {
    // Initialize the lists of cells, using deep copies. The solution is empty
    // in case the user taps in a puzzle: it gets filled if they generate one.
    //
    // Having separate initialisation or re-initialisation for this part of the
    // Puzzle Model allows the user to generate new puzzles of the same type as
    // before, but without having to go back to the Puzzle List screen.

    _puzzleGiven = [..._puzzleMap.emptyBoard];
    _solution    = [];		// Needs to be empty when tapping in a puzzle.
    _stateOfPlay = [..._puzzleMap.emptyBoard];
    _cellStatus  = [..._puzzleMap.emptyBoard];

    _cellChanges.clear();	// No moves to undo/redo yet.
    _sudokuMoves.clear();	// No hints available yet.

    _indexUndoRedo  = 0;

    selectedCell    = null;	// TODO - Could be 0/
    selectedControl = 1;
    notesMode       = false;

    _puzzlePlay = Play.NotStarted;

    _puzzleTimer.init();
  }

  void makeReadyToPlay(BoardContents puzzleGiven,
                       BoardContents solution,
                       List<int>     sudokuMoves)
  {
    selectedCell = null;	// Set invalid index for first selected cell.
    _puzzleGiven = [...puzzleGiven];
    _stateOfPlay = [...puzzleGiven];
    _solution    = [...solution];
    _sudokuMoves = [...sudokuMoves];

    // Set the first VACANT cell to be highlighted. If all cells are Given
    // or unusable, the selectedCell stays null and is not highlighted, so no
    // moves are possible then. This could arise if a fully-solved Puzzle is
    // loaded from a file or entered manually.
    for (int n = 0; n < _puzzleGiven.length; n++) {
      if (_puzzleGiven[n] != UNUSABLE) {
        if (_puzzleGiven[n] > 0) {
          _cellStatus[n] = GIVEN;
        }
        else {
          selectedCell ??= n;	// The default selected cell needs to be VACANT.
        }
      }
    }

    _cellChanges.clear();	// No moves made yet.

    // Change the Puzzle Play status to receive solving moves.
    _puzzlePlay = Play.ReadyToStart;
    if (_puzzle.firstBuild()) {
      return;		// Avoid notifyListeners() during Flutter's first build.
    }
    notifyListeners();  // Else ensure the board and initial clues get painted.
  }

  bool triggerRepaint()
  {
    // Used by 3D View Rotation (with no Puzzle Model change).
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  void  hitPuzzleCellN(int n)
  {
    // Step 1 in making a move: highlight a cell that is to receive a new value.

    print('Selected cell $n');
    if (! validCellSelection(n)) {
      return;
    }
    selectedCell = n;
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return;
  }

  void hitPuzzleArea(int x, int y)
  {
    // User has tapped on a puzzle-cell in 2D: use the generic handler (above).
    hitPuzzleCellN(_puzzleMap.cellIndex(x, y));
    return;
  }

  void hitControlArea(int selection)
  {
    if (puzzlePlay == Play.Solved) {
      // All done! Can use undo/redo to review moves, but cannot make new moves.
      return;
    }

    // Step 2 in making a move: tap on the control area to choose a value
    // (1-9, A-Y) to enter into a puzzle cell, to switch Notes mode on/off
    // or to clear a puzzle cell. In Notes mode, multiple values can be
    // entered into one selected cell. In either mode, a value can be
    // deleted by tapping on the same value again.

    bool hideNotes = (puzzlePlay == Play.NotStarted) ||
                     (puzzlePlay == Play.BeingEntered);
    debugPrint('hitControlArea: selection $selection, hideNotes $hideNotes');
    if ((! hideNotes) && (selection == 0)) {
      // If solving, switch Notes mode and change colour of highlight.
      notesMode = !notesMode;
      debugPrint('Switched Notes to $notesMode');
      notifyListeners();	// Trigger a repaint of the Puzzle View.
      return;
    }
    // The value selected is treated as a cell-value, a note or an erase.
    selectedControl = selection - (hideNotes ? 0 : 1);
    debugPrint('hitControlArea: Selected control $selectedControl');

    int cellToChange = selectedCell ?? -1;
    if (cellToChange < 0) {
      return;		// No cell selected: cannot make a move.
    }
    debugPrint('Check valid move: cell $cellToChange control $selectedControl');
    if (! validMove(cellToChange, selectedControl)) {
      print('Invalid move');
      return;
    }

    CellValue symbol = selectedControl;

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

    // Make the move.
    move(cellToChange, symbol);

    if ((_puzzlePlay == Play.InProgress) || (_puzzlePlay == Play.HasError)) {
      // If all cells are now filled, change the Puzzle Play status to Solved or
      // HasError: otherwise leave it at InProgress. If Solved, no more moves
      // are allowed: only undo/redo (to review the moves).
      _puzzlePlay = _isPuzzleSolved();

      // Stop the clock when changing to Solved status.
      if (_puzzlePlay == Play.Solved) {
        /////////// ????????????? _puzzleTimer.stopClock();
      }

      // Need to select a message and display it in PuzzleBoardView.
      _puzzle.notifyListeners();
    }

    // The move has been accepted and made.
    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return;
  }

  bool validCellSelection(int n)
  {
    // The user has tapped on a puzzle-cell in 2D/3D: apply the rules of play.
    if ((n < 0) || (n > _puzzleMap.size)) {
      debugPrint('puzzle.dart:validCellSelection() - INVALID CELL-INDEX $n');
      return false;
    }
    if (_puzzlePlay == Play.Solved) {
      // The Puzzle has been solved: only undo/redo  moves are allowed.
      // The user can also generate a new Puzzle or Quit/Save, etc.
      return false;
    }
    else if (_puzzlePlay == Play.HasError) {
      // Allow moves to correct the error(s) in a potential solution.
      _puzzlePlay = Play.InProgress;
    }

    CellStatus status = _cellStatus[n];
    // debugPrint('Cell status $n = $status');

    // Check that the user has selected a symbol and that the cell is usable.
    if (status == UNUSABLE || status == GIVEN) {
      debugPrint('Invalid: Status is UNUSABLE or GIVEN');
      return false;
    }
    return true;
  }

  bool validMove(int n, CellValue symbol)
  {
    // The user has tapped on a control-cell: if OK, allow a move to be made.
    if ((n < 0) || (n > _puzzleMap.size)) {
      debugPrint('puzzle.dart:validMove() - INVALID CELL-INDEX $n');
      return false;
    }
    if ((symbol < 0) || (symbol > _puzzleMap.nSymbols)) {
      debugPrint('puzzle.dart:validMove() - INVALID SYMBOL $symbol');
      return false;
    }
    if ((symbol == VACANT) && (_stateOfPlay[n] == VACANT)) {
      // Don't clear a cell that is already empty.
      return false;
    }
    return true;
  }

  void move(int n, CellValue symbol)
  {
    debugPrint('PuzzlePlayer move: cell $n symbol $symbol');

    // Register a move in the Model data and update the Puzzle cell's state.
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

      // int currV  = currentValue & (NotesBit - 1);
      // int newV   = newValue     & (NotesBit - 1);
      // debugPrint('Puzzle: cell $n: new val $newV status $newStatus');
      // debugPrint('Puzzle: cell $n: old val $currV status $currentStatus');

      // If the last Note has been cleared, clear the whole cell-state.
      if (newValue == NotesBit) {
        newValue   = VACANT;
        newStatus  = VACANT;
      }
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
          _autoClearNotes(n, newValue);
        }
      }
      debugPrint('New value $newValue, new status $newStatus');
    }

    // TODO - Need to test newValue == currentValue, i.e. that cell did change?
    //        If no change, do not update the puzzle state and undo/redo list.
    CellState newState = CellState(newStatus, newValue);

    int nCellChanges = _cellChanges.length;
    if (_indexUndoRedo < nCellChanges) {
      // Prune the list of cell changes (i.e. list of undo/redo possibilities).
      _cellChanges.removeRange(_indexUndoRedo, nCellChanges);
    }

    // Update the undo/redo list and record the move.
    _cellChanges.add(CellChange(n, newState));
    _indexUndoRedo     = _cellChanges.length;
    _cellStatus[n]     = newStatus;
    _stateOfPlay[n]    = newValue;

    // debugPrint('NEW MOVE: cell $n status $newStatus value $newValue changes'
          // ' ${_cellChanges.length} Undo/Redo $_indexUndoRedo');
    return;
  }

  Play _isPuzzleSolved()
  {
    // Check whether all playable cells are filled, with or without error(s).
    bool hasError = false;
    for (int n = 0; n < _solution.length; n++) {
      if ((_cellStatus[n] == VACANT) || (_cellStatus[n] == NOTES)) {
        // Not finished yet: found Notes or an empty cell.
        return _puzzlePlay;
      }
      if (_stateOfPlay[n] != _solution[n]) {	// Items are equal if UNUSABLE.
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
    // debugPrint('HINTS: $_sudokuMoves');	// Cell numbers in play-order.
    if (_puzzlePlay != Play.ReadyToStart && _puzzlePlay != Play.InProgress) {
      return;
    }
    for (int n in _sudokuMoves) {
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

  bool undo()
  {
    // Undo a move. This goes back to the start of the puzzle so that all
    // _autoClearNotes() operations in the last move can be undone correctly.
    // For further information, see the comments in _autoClearNotes() below.
    if (_indexUndoRedo <= 0) {
      debugPrint('NO MOVES available to Undo');
      return false;		// No moves left to undo - or none made yet.
    }

    // Redo all moves from the start, except for the latest one.
    _indexUndoRedo--;
    _indexUndoRedo--;
    bool result = redo();
    return result;
  }

  bool redo()
  {
    // Redo a move. This goes right back to the start of the puzzle so that all
    // _autoClearNotes() operations can be re-done correctlyi at every step.
    // For further information, see the comments in _autoClearNotes() below.
    if (_indexUndoRedo >= _cellChanges.length) {
      debugPrint('NO MOVES available to Redo');
      return false;		// No moves left to redo - or none made yet.
    }

    // Restore the initial state of the Puzzle.
    _stateOfPlay = [..._puzzleGiven];
    for (int n = 0; n < _puzzleGiven.length; n++) {
      if (_puzzleGiven[n] != UNUSABLE) {
        _cellStatus[n] = (_puzzleGiven[n] > 0) ? GIVEN : VACANT;
      }
    }

    // Get details of all moves (from the beginning) and redo them.
    _indexUndoRedo++;
    for (int n = 0; n < _indexUndoRedo; n++) {
      CellChange change = _cellChanges[n];
      int cell = change.cellIndex;
      _cellStatus[cell]  = change.after.status;
      _stateOfPlay[cell] = change.after.cellValue;
      _autoClearNotes(cell, _stateOfPlay[cell]);
    }

    notifyListeners();		// Trigger a repaint of the Puzzle View.
    return true;
  }

  void _autoClearNotes(int n, int newValue)
    // This operation is undoable and redoable. It can affect several cells at
    // once, whereas the move that gives rise to it affects only one cell.
    //
    // One way to implement undo/redo might have been to allow _cellChanges[] to
    // contain a list of resulting cell-states for every move, even if only
    // one cell is affected. Instead, redo() repeats every move from the first
    // and undo() does the same for all moves but one, using redo() to do most
    // of the work. This is fast enough because puzzle boards alway have < 1000
    // cells and most have < 100 cells.
  {
    int noteBit = 1 << newValue;
    List<int> groupList = _puzzleMap.groupList(n);
    for (int g in groupList) {
      for (int cell in _puzzleMap.group(g)) {
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

  @override
  void dispose() // TODO - Probably belongs in GameTimer.
  {
    // This is needed if the Puzzle is terminated before it is solved. It avoids
    // an error when the Timer runs on and the Puzzle object no longer exists.
    debugPrint('Puzzle DISPOSED');

    ////////// ??????????????  _puzzleTimer.stopClock();

    super.dispose();
  }

} // End PuzzlePlayer class.
