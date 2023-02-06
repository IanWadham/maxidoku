// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart' show debugPrint;

import 'dart:math';		// For random-number generator Random class.
import '../globals.dart';

/* *************************************************************************
 *   Copyright 2005-2007 Francesco Rossi <redsh@email.it>                  *
 *   Copyright 2006      Mick Kappenburg <ksudoku@kappendburg.net>         *
 *   Copyright 2006-2008 Johannes Bergmeier <johannes.bergmeier@gmx.net>   *
 *   Copyright 2012      Ian Wadham <iandw.au@gmail.com>                   *
 *   Copyright 2015      Ian Wadham <iandw.au@gmail.com>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.         *
 ***************************************************************************/

/*
 * @class PuzzleMap
 * @short Generalized data representing a Sudoku puzzle size, shape and rules.
 *
 * PuzzleMap is a class that can represent any type or size of Sudoku layout,
 * either in two dimensions or three. It is used, together with the Puzzle class,
 * by the puzzle generator/solver, the 2-D and 3-D views, the Save action and
 * the Load action.
 *
 * The data structures in PuzzleMap are loaded from strings of the form
 * <keyword> <space-separated value(s)> in file models/puzzle_types.dart.
 *
 * The basic attributes are:
 *
 *      nSymbols  The number of symbols (digits or letters) to be used when
 *                solving a puzzle of this type and size (e.g. 9, but can be
 *                4, 16 or 25).
 *      sizeX     The number of cells in the X direction.
 *      sizeY     The number of cells in the Y direction.
 *      sizeZ     The number of cells in the Z direction.
 *
 * A conventional two-dimensional type of puzzle has a square grid, where
 * sizeX = sizeY and sizeZ = 1.  A three-dimensional type of puzzle (Roxdoku)
 * has a three-dimensional grid with sizeZ > 1.
 *
 * The actual contents of a puzzle or solution are represented as a vector of
 * integers (see classes Puzzle and SudokuBoard).  PuzzleMap provides methods to
 * convert both ways between XYZ co-ordinates and a cell index (or cell number)
 * in an integer list representing a puzzle or solution.  The total size of the
 * list is (sizeX * sizeY * sizeZ) cells, but in some types of puzzle not all
 * cells are used (e.g. gaps between the five sub-grids of a Samurai puzzle).
 * In such cases sizeX, sizeY and sizeX can be greater than the size of a Sudoku
 * square or Roxdoku cube and the unused cells become empty space on the screen.
 *
 * Finally, the cells are organised into groups (or cliques) which represent
 * everything that needs to be known about the rules and structure of a
 * particular type of puzzle.  Each group or clique has as many members as
 * there are symbols in the puzzle (i.e. that number = nSymbols).  Each member
 * of a group is a cell number (or index) representing a cell that is in the
 * group.  A group may represent a row, a column, a block of some shape (not
 * necessarily square) or a plane within a 3-D grid.  The fact that each
 * row, column, block or plane must contain each symbol exactly once is the
 * cardinal rule of Sudoku puzzles in general.
 *
 * For example, the XSudoku puzzle type has order 9 and 29 groups (or cliques)
 * of 9 cells each: 9 rows, 9 columns and 9 blocks 3x3 square, plus 2 diagonals,
 * which must also comtain the numbers 1 to 9 in that type of Sudoku.  A Roxdoku
 * puzzle of order 16 has a cubic grid containing 12 planes, each a square of
 * 4x4 cells and each having 16 cells to be filled with the letters A to P.
 * There are three sets of 4 planes, which are perpendicular to the X, Y and Z
 * directions respectively.
 *
 * For brevity and the convenience of classes using PuzzleMap, the groups or
 * cliques are organised into high-level structures such as a square grid (with
 * rows and columns, but with or without square blocks), a large NxNxN cube or a
 * special block, such as a diagonal in XSudoku or an irregularly shaped block
 * in jigsaw-type puzzles.  These structures also make it easier to write data
 * strings for new 2-D puzzle shapes and open the way for 3-D puzzles containing
 * more than one NxNxN cube overlapping in various ways.
 *
 * Cages, introduced in May-June 2015, are a new data-structure to support
 * Killer Sudoku and Mathdoku (aka Kenken TM) types of puzzle. A cage is an
 * irregular group of cells with size 1 to puzzle-order. Cages are imposed over
 * a Latin Square of digits, as used in 2-D Sudokus. A cage of size 1 is
 * equivalent to a clue or given value in a Sudoku. Cages of size 2 or more
 * provide the rest of the clues. In Mathdoku, each such cage has an arithmetic
 * operator (+-x/) and a value that is calculated, using that operator and
 * the hidden solution-values of the cells in the cage. The user has to work
 * out what the solutions are from the clues in the cages and the regular
 * Sudoku rules for rows and columns (but not blocks). In Killer Sudoku, there
 * are the usual 3x3 or 2x2 Sudoku blocks and the only operator is addition.
 * Note that a Mathdoku puzzle can have any size from 3x3 up to 9x9, but a
 * Killer Sudoku can have sizes 4x4 or 9x9 only.
 */

// High-level structure types are a square grid, a large cube or a
// special or irregularly-shaped group, as in XSudoku or jigsaw types.
enum StructureType { SudokuGroups, RoxdokuGroups, Groups }

class PuzzleMap
{
  // The constructor uses a list of lines, with line-endings (\n) removed, taken
  // from a const List<String> of multi-line strings in file puzzle_types.dart.
  // The file has one string per puzzle-type specification, containing Name,
  // Description and layout details for the puzzle map.

  PuzzleMap({required List<String> specStrings})
    :
      _name = '',
      _specificType = SudokuType.Invalid,
      _sizeX        = 0,
      _sizeY        = 0,
      _sizeZ        = 0,
      _size         = 0,
      _blockSize    = 0,
      _nGroups      = 0,
      _nSymbols     = 0,
      _hideOperators = false
  {
    bool   mapStarted = false;
    int    index = 0;
    int    nSpecs = specStrings.length;
    if (nSpecs < 1) return;
    RegExp whiteSpace = RegExp(r'(\s+)');

    while (index < nSpecs) {
      // debugPrint('Index: $index of $nSpecs');
      String specLine = specStrings[index];

      if (specLine.isEmpty) { index++; continue; }	// Skip empty line(s).

      List<String> fields = specLine.split(whiteSpace);
      int nFields = fields.length;
      if (nFields < 1) { break; }	// Must have one or more fields.
      // debugPrint('nFields = $nFields');
      // debugPrint(fields);
      String key = fields[0];

      int ok = -1;
      switch (key) {
        case 'Name':
          if (_name == '') {
            // Get the remainder of the line after the key.
            _name = specLine.substring(key.length, specLine.length).trim();
          }
          else {
            _name = 'More than one Name line.';
          }
          if (_name == '') {
            _name = 'Missing name on Name line.';
          }
          // debugPrint(_name);
          break;
        case 'SpecificType':
          String st  = specLine.substring(key.length, specLine.length).trim();
          String stx = 'SudokuType.$st';
          // Convert the name of the Sudoku type to a SudokuType enum value.
          SudokuType t = SudokuType.values.firstWhere((f)=> f.toString() == stx,
                                               orElse: ()=> SudokuType.Invalid);
          if (t == SudokuType.Invalid) {
            debugPrint('$st is an invalid name for a SpecificType.');
          }
          else if (_specificType == SudokuType.Invalid) {
            _specificType = t;		// Valid SpecificType found.
          }
          else {
            debugPrint('More than one SpecificType line for $_name.');
          }
          break;
        case 'SizeX':
          _sizeX = fields[1] == 'Mathdoku' ? 6 :
                                  _getDimension(fields, nFields, _sizeX);
          // debugPrint('_sizeX = $_sizeX');
          break;
        case 'SizeY':
          _sizeY = fields[1] == 'Mathdoku' ? 6 :
                                  _getDimension(fields, nFields, _sizeY);
          // debugPrint('_sizeY = $_sizeY');
          break;
        case 'SizeZ':
          _sizeZ = _getDimension(fields, nFields, _sizeZ);
          // debugPrint('_sizeZ = $_sizeZ');
          break;
        case 'NSymbols':
          _nSymbols = fields[1] == 'Mathdoku' ? 6 :
                                     _getDimension(fields, nFields, _nSymbols);
          // debugPrint('_nSymbols = $_nSymbols');
          break;
        case 'SpecialCells':
          // Cells that are specially coloured to draw attention, such as the
          // diagonals in XSudoku or certain cells in 3D Roxdoku puzzles.
          for (int i = 2; i < nFields; i++) {
            int cell = int.tryParse(fields[i], radix: 10) ?? -1; 
            if (cell >= 0) {
              _specialCells.add(cell);
            }
          }
          break;
        case 'HideOperators':		// Blindfold Mathdoku option. Default
          _hideOperators = true;	// is false (operators are SHOWN).
          // debugPrint('PuzzleMap: _hideOperators = $_hideOperators');
          break;

        case 'PuzzleMap':
          mapStarted = true;

          // Calculate the size of square blocks in Sudoku or cubes in Roxdoku.
          // This is needed when mapping layouts of Sudoku or Roxdoku Groups.
          _blockSize  = 3;
          for (int n = 2; n <= 5; n++) {
              if (_nSymbols == n * n) {
                  _blockSize = n;
              }
          }
          debugPrint('Block size = $_blockSize');

          // Create a blank puzzle map filled with UNUSABLE cells. Some may
          // remain and be displayed as empty space, e.g. in Samurai puzzles.
          _size  = _sizeX * _sizeY * _sizeZ;
          // debugPrint('_size = $_size');
          if(_size > 0) {	// Create a new board of the required size.
            _emptyBoard = List.filled(_size, UNUSABLE, growable: false);
          }
          // debugPrint(_emptyBoard);
          break;
        case 'SudokuGroups':
          if (mapStarted) {
            int  pos = 0;			// Default.
            bool hasSquareBlocks = true;	// Default.
            if (nFields >= 2) {
              pos = int.tryParse(fields[1], radix: 10) ?? -1; 
            }
            if (nFields >= 3) {
              if (fields[2] != 'HasSquareBlocks') {
                hasSquareBlocks = false;
              }
            }
            _initSudokuGroups(pos, hasSquareBlocks);
          }
          break;
        case 'RoxdokuGroups':
          if (mapStarted) {
            int  pos = 0;			// Default.
            if (nFields >= 2) {
              pos = int.tryParse(fields[1], radix: 10) ?? -1; 
            }
            _initRoxdokuGroups(pos);
          }
          break;
        case 'Group':
          if (mapStarted && (nFields >= 6)) {
            int groupSize = _getDimension(fields, nFields, 0);
            if (groupSize >= 4) {
              List<int> data = List.empty(growable: true);
              for (int i = 2; i < nFields; i++) {
                if (i < (groupSize + 2)) {
                  data.add(int.tryParse(fields[i], radix: 10) ?? -1); 
                }
                else {
                  data.add(-1);
                }
              }
              // debugPrint('IRREGULAR GROUP $data');
              _addGroupStructure(data);
            }
          }
          break;
        // Settings for a good view of a 3D Roxdoku puzzle.
        case 'Diameter':	// Diameter of spheres * 100.
          ok = _getDimension(fields, nFields, _diameter);
          if (ok > 0) _diameter = ok;
          // debugPrint('$fields ok = $ok _diameter = $_diameter');
          break;
        case 'RotateX':		// Degrees rotation around the X axis.
          ok = _getDimension(fields, nFields, _rotateX);
          if (ok != -1) _rotateX = ok;
          // debugPrint('$fields ok = $ok _rotateX = $_rotateX');
          break;
        case 'RotateY':		// Degrees rotation around the Y axis.
          ok = _getDimension(fields, nFields, _rotateY);
          if (ok != -1) _rotateY = ok;
          // debugPrint('$fields ok = $ok _rotateY = $_rotateY');
          break;
        default:
          // Skip unused or obsolete tags in puzzle_types.dart.
          break;
      }
      index++;
    }

    // Finalise the number of groups.
    _nGroups = groupCount();

    // printBoard(_emptyBoard);
    // printGroups();

    // Create an index to help puzzle generators and solvers.
    _createIndexOfCellsToGroups();

  } // End of PuzzleMap constructor.

  // Getters for PuzzleMap properties.
  int get nSymbols   => _nSymbols;
  int get blockSize  => _blockSize;

  int get sizeX      => _sizeX;
  int get sizeY      => _sizeY;
  int get sizeZ      => _sizeZ;

  int get size       => _size;

  String get name    => _name;

  bool get hideOperators => _hideOperators;

  SudokuType    get specificType  => _specificType;
  BoardContents get emptyBoard    => _emptyBoard;

  List<int>     get specialCells  => _specialCells;

  // Viewing parameters for 3D Roxdoku puzzles.
  int get diameter   => _diameter;
  int get rotateX    => _rotateX;
  int get rotateY    => _rotateY;

  // Methods for calculating cell positions and X, Y and Z co-ordinates.

  // In a BoardContents list the fastest variations are in Z, Y and X, in that
  // order. The cells in a two-dimensional board are listed one complete column
  // at a time.

  int cellIndex(int x, int y, [int z = 0])	// BoardContents index (x,y,z).
  {
    return (x * _sizeY + y) * _sizeZ + z;
  }

  int cellPosX(int i) {				// X co-ordinate of cell i.
    if(_size <= 0) return 0;
    return i ~/ _sizeZ ~/ _sizeY;
    // NOTE: Truncated integer operator is ~/ in Dart (/ converts to double).
  }

  int cellPosY(int i) {				// Y co-ordinate of cell i.
    if(_size <= 0) return 0;
    return i ~/ _sizeZ % _sizeY;
  }

  int cellPosZ(int i) {				// Z co-ordinate of cell i.
    if(_size <= 0) return 0;
    return i % _sizeZ;
  }

  // Get the total number of groups (cliques) -- rows, columns and blocks.
  int groupCount()   { return _groups.length; }

  // Get a list of the cells in a group (clique).
  List<int> group(int i) { return _groups[i]; }

  // Get a list of the groups (cliques) to which a cell belongs.
  List<int> groupList(int cellNumber) => _indexOfCellsToGroups[cellNumber];

    // NOTE: This index's main usage is on an inner loop of the
    // generator/solver and execution time is a concern there.

  // Get the total number of high-level structures.
  int structureCount() { return _structureTypes.length; }

  // Get the type of a structure (square, cube, etc.).
  StructureType structureType(int n) { return _structureTypes.elementAt(n); }

  // Get the position of a structure within the puzzle-map.
  int structurePosition(int n) { return _structurePositions.elementAt(n); }

  // Find out whether a 2-D structure has square blocks or not.
  bool structureHasBlocks(int n) { return _structuresWithBlocks.elementAt(n); }

  // Get the total number of cages (0 if not Mathdoku or Killer Sudoku)..
  int cageCount() { return _cages.length; }

  // Get a list of the cells in a cage.
  List<int> cage(int i) { return _cages.elementAt(i).cage; }

  // Get the mathematical operator of a cage (+ - * or /).
  CageOperator cageOperator(int i) { return
                                 _cages.elementAt(i).cageOperator; }

  // Get the calculated value of the cells in a cage.
  int cageValue(int i) { return _cages.elementAt(i).cageValue; }

  // Get the top left cell in a cage.
  int cageTopLeft(int i) { return _cages.elementAt(i).cageTopLeft; }

  // Add a cage (applicable to Mathdoku or Killer Sudoku puzzles only).
  void addCage(List<int> cage, CageOperator cageOperator, int cageValue)
  {
        // Add to the cages list.
        _cages.add (Cage());
        Cage   newCage        = _cages.last;
        newCage.cage          = cage;
        newCage.cageOperator  = cageOperator;
        newCage.cageValue     = cageValue;

        // Calculate cageTopLeft cell (used for displaying operator and value).
        int topY              = _nSymbols; // Start at the bottom right of the
        int leftX             = _nSymbols; // user's view of the Sudoku grid.
        newCage.cageTopLeft   = 0;
        for (int cell in cage) {
            int X = cellPosX(cell);
            int Y = cellPosY(cell);
            // Is this cell higher than before or same height and further left.
            if ((Y < topY) || (Y == topY) && (X < leftX)) {
              newCage.cageTopLeft = cell;
              topY  = Y;
              leftX = X;
            }
        }
  }

  // Remove a cage (when keying in a Mathdoku or Killer Sudoku puzzle).
  void dropCage(int cageNum)
  {
        if (cageNum >= _cages.length) {
            return;
        }
        _cages.removeAt (cageNum);
  }

  // Clear cages used in a previous puzzle, if any.
  void clearCages() {
        // Clear previous cages (if any).
        if (_cages.isNotEmpty) {
            _cages.clear();
        }
  }

  // Private values and methods.

  int _sizeX;
  int _sizeY;
  int _sizeZ;
  int _size;		// Size of puzzle's whole area or volume (the board).
  int _blockSize;	// Edge-length of a square 2D block or 3D cube.
  int _nGroups;		// Number of groups (cliques) in the puzzle.
  int _nSymbols;	// Number of symbols (4 9 16 25: 0-4, 0-9, A-P or A-Y).

  bool _hideOperators = false;	// Default Mathdoku option: operators are SHOWN.

  int _diameter = 350;	// Default diameter of spheres in 3D puzzle * 100.
  int _rotateX  = 15;	// Default degrees rotation of view around X axis.
  int _rotateY  = 27;	// Default degrees rotation of view around Y axis.

  // Cells to get special colour, such as XSudoku diagonals and some 3D cells.
  final List<int>            _specialCells = [];

  // High-level structures, 3 values per structure: structure type (see
  // enum), structure position and whether structure has square blocks.
  final List<StructureType>  _structureTypes = [];
  final List<int>            _structurePositions = [];
  final List<bool>           _structuresWithBlocks = [];

  // Low-level structures (rows, columns and blocks) also known as groups.
  final List<List<int>>  _groups = [];

  // Cages are for Mathdoku and Killer Sudoku puzzles only, else empty.
  final List<Cage>       _cages = [];

  String           _name = 'PlainSudoku';
  SudokuType       _specificType = SudokuType.PlainSudoku;

  // Initialise the board to zero size until we know what size is required.
  BoardContents    _emptyBoard = List.empty(growable: true);

  int _getDimension(List<String>fields, int nFields, int dimension)
  {
    if (nFields < 2) {
    // debugPrint('_getDimension() nFields is $nFields');
    return -1;
    }
    // The value should be in the second field.
    int i = int.tryParse(fields[1], radix: 10) ?? -1; 
    // debugPrint('_getDimension() returns i = $i');
    return i;
  }

  void _initSudokuGroups([int pos = 0, bool withBlocks = true])
  {
    // _initSudokuGroups() sets up rows and columns in a Sudoku grid of size
    // (_nSymbols*_nSymbols) cells. Its first parameter (usually 0) shows where
    // on the whole board the grid goes. This is relevant in Samurai and
    // related layouts. Its second attribute is true if square-block groups
    // are required (e.g. as in Classic and Killer Sudoku) or false if not
    // (e.g. as in a Jigsaw, Aztec or Mathdoku type).

    // _structures << SudokuGroups << pos << (withBlocks ? 1 : 0);
    _structureTypes.add(StructureType.SudokuGroups);
    _structurePositions.add(pos);
    _structuresWithBlocks.add(withBlocks);

    List<int> rowc, colc, blockc;
    for (int i = 0; i < _nSymbols; ++i) {
      rowc   = List.empty(growable: true);
      colc   = List.empty(growable: true);
      blockc = List.empty(growable: true);

      for (int j = 0; j < _nSymbols; ++j) {
        // Truncated integer division operator is ~/ in Dart.
        rowc.add (pos + j*_sizeY + i);
        colc.add (pos + i*_sizeY + j);
        blockc.add (pos + ((i ~/ _blockSize)*_blockSize + j%_blockSize) * _sizeY
                          + (i%_blockSize)*_blockSize + j ~/ _blockSize);
      }
      _addGroup(rowc);
      _addGroup(colc);
      if (withBlocks) {
        _addGroup(blockc);
      }
    }
  }

  void _initRoxdokuGroups([int pos = 0])
  {
     // initRoxdokuGroups() sets up the intersecting planes in a
     // 3-D Roxdoku grid. Its only parameter shows where in the entire
     // three-dimensional layout the grid goes.

     // _structures << RoxdokuGroups << pos << 1;
     _structureTypes.add(StructureType.RoxdokuGroups);
     _structurePositions.add(pos);
     _structuresWithBlocks.add(false);

     List<int> xFace, yFace, zFace;
     int x = cellPosX(pos);
     int y = cellPosY(pos);
     int z = cellPosZ(pos);

    for (int i = 0; i < _blockSize; i++) {
      xFace = List.empty(growable: true);
      yFace = List.empty(growable: true);
      zFace = List.empty(growable: true);
      for (int j = 0; j < _blockSize; j++) {
        for (int k = 0; k < _blockSize; k++) {
          // Intersecting faces at relative (0,0,0), (1,1,1), etc.
          xFace.add (cellIndex (x + i, y + j, z + k));
          yFace.add (cellIndex (x + k, y + i, z + j));
          zFace.add (cellIndex (x + j, y + k, z + i));
        }
      }
      _addGroup(xFace);
      _addGroup(yFace);
      _addGroup(zFace);
    }
  }

  // Add a special or irregularly-shaped group to the list of structures.
  void _addGroupStructure(List<int> data) {

        _structureTypes.add(StructureType.Groups);
        _structurePositions.add(_groups.length);
        _structuresWithBlocks.add(false);

        _addGroup(data);
  }

  void _addGroup(List<int> data) {
        // Add to the groups (cliques) list.
        _groups.add (data);
        for (int n = 0; n < data.length; n++) {
            // Set cells in groups VACANT: cells not in groups are UNUSABLE.
            _emptyBoard [data.elementAt(n)] = VACANT;
        }
        // debugPrint('ADD GROUP $data');
        // printBoard(_emptyBoard);
  }

  // For time-efficiency in generating and solving puzzles, make an index from
  // each cell number to the list of groups (cliques) where the cell belongs.
  final List<List<int>> _indexOfCellsToGroups = [];

  void _createIndexOfCellsToGroups()
  {
    // Create the structure and contents of the index.
    //
    // For each cell on the puzzle board there is a list of groups to which the
    // cell belongs. These lists may vary in length. On a Classic Sudoku board
    // each cell belongs to three groups: a row, a column and a square block.
    // But in XSudoku cells on the diagonals belong to four groups and the cell
    // where the diagonals intersect belongs to five: two diagonals, a row, a
    // column and a block. In Samurai puzzles some cells do not belong in any
    // group, because they are in the empty space between puzzle structures
    // and are unusable.

    if ((_size <= 0) || (_nGroups <= 0)) {
      return;			 // Nothing to do: empty constructor.
    }

    for (int i = 0; i < _size; i++) {
      _indexOfCellsToGroups.add(List.empty(growable: true));
    }
    // debugPrint('Empty index created');
    // debugPrint(_indexOfCellsToGroups);	// Print an empty index.

    // Now look up each group, break out the cells that belong to it and
    // add the group number to the index-list of each cell.
    for (int groupNumber = 0; groupNumber < _nGroups; groupNumber++) {
      List<int> cells = _groups[groupNumber];
      int nCells = cells.length;
      // debugPrint('\nGroup: $groupNumber nCells: $nCells --- '
      //            'List of cells: $cells');
      for (int n = 0; n < nCells; n++) {
        int cell = cells[n];
        _indexOfCellsToGroups[cell].add(groupNumber);
        // debugPrint('Cell $cell: add group: $groupNumber: '
        //            'giving index ${_indexOfCellsToGroups}');
      }
    }
    // _testIndexOfCells();
  }

/*
  void _testIndexOfCells()
  {
    debugPrint('');
    for (int n = 0; n < _size; n++) {
      List<int> indexEntry = _indexOfCellsToGroups[n];
      debugPrint('Index of cell $n: $indexEntry');
    }
    // debugPrint('');
    // debugPrint('Whole Index');
    // debugPrint(_indexOfCellsToGroups);

    debugPrint('\nTest groupList(int cellNumber)\n');
    List<int> result;
    result = groupList(0);
    debugPrint('Cell 0 is in groups $result');
    result = groupList(5);
    debugPrint('Cell 5 is in groups $result');
    result = groupList(10);
    debugPrint('Cell 10 is in groups $result');
    result = groupList(15);
    debugPrint('Cell 15 is in groups $result');
    result = groupList(33);
    debugPrint('Cell 33 is in groups $result');
    result = groupList(63);
    debugPrint('Cell 63 is in groups $result');
    result = groupList(36);
    debugPrint('Cell 36 is in groups $result');
    result = groupList(66);
    debugPrint('Cell 66 is in groups $result');
    result = groupList(42);
    debugPrint('Cell 42 is in groups $result');
    result = groupList(50);
    debugPrint('Cell 50 is in groups $result');
  }
*/

  // **********************************************************  //
  // Random-number functions for puzzle generators and solvers.  //
  // **********************************************************  //

  // Random _random = Random(266133);	// Fixed seed for testing only.
  // NOTE: There is no setSeed() function. Must re-create _random to set seed.
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  // Generate a random integer in a given range.
  int randomInt(int limit)
  {
    return _random.nextInt(limit);
  }

  // Generate a random sequence of non-repeating integers: range 0 to nItems - 1.
  List<int> randomSequence (int nItems)
  {
    List<int> sequence = [];

    // Fill the list with consecutive integers.
    for (int i = 0; i < nItems; i++) {
        sequence.add(i);
    }

    if (nItems <= 1) return sequence;

    // Shuffle the integers.
    int last = nItems;
    int z    = 0;
    int temp = 0;
    for (int i = 0; i < nItems; i++) {
        z = _random.nextInt(nItems);
        last--;
        temp            = sequence[z];
        sequence [z]    = sequence[last];
        sequence [last] = temp;
    }
    return sequence;
  }

  // *********************************************** //
  // Public methods, for testing and debugging only. //
  // *********************************************** //

  void printGroups()
  {
    debugPrint('NUMBER OF GROUPS: ${groupCount()}');
    debugPrint('_nGroups = $_nGroups');
    debugPrint('LIST OF GROUPS: ${_groups.toString()}');
    debugPrint('');
  }

  void printBoard(BoardContents board)
  {
    int value = 0;
    const String digits  = '.123456789';
    const String letters = '.abcdefghijklmnopqrstuvwxyz';
    String symbol = ' ';

    if (board.isEmpty) {
      debugPrint('NO BOARD VALUES');
      return;
    }

    debugPrint('');
    for (int y=0; y < _sizeY; y++) {
      String line = '  ';
      for (int z=0; z < sizeZ; z++) {
        for (int x=0; x < _sizeX; x++) {
          value = board[cellIndex(x, y, z)];
          if (value == UNUSABLE) {
            symbol = ' ';		// Hide unusable cells.
          }
          else if (value < 0) {
            symbol = '?';		// Flag null cells (if any).
          }
          else {
            // Show a symbol for a filled value or '.' for an unfilled cell.
            symbol = (_nSymbols > 9) ?  letters[value] : digits[value];
          }
          line = '$line $symbol';
        }
        line = '$line  ';
      }				// End x
      debugPrint(line);
    }				// End z
    debugPrint('');
  }				// End y

} // End of PuzzleMap class.


class Cage {					// In lieu of a struct { }...
  List<int>    cage = [];			// The cells in the cage.
  CageOperator cageOperator = CageOperator.Add;	// The mathematical operator.
  int          cageValue = 1;			// The value to be calculated.
  int          cageTopLeft = 0;			// The top-left (display) cell.
  bool         hideOperator = false;		// Applies to Mathdoku only.
}
