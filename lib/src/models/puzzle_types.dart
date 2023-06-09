/*
    SPDX-FileCopyrightText: 2005-2007 Francesco Rossi <redsh@email.it>
    SPDX-FileCopyrightText: 2012      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2015      Ian Wadham <iandw.au@gmail.com>
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/foundation.dart' show debugPrint;

class PuzzleTypesText {

  const PuzzleTypesText();

  static int _nTypes = puzzleTypes.length;

  // Extract the specification String of the Puzzle Type at [index] and
  // split it into parseable lines, each line beginning with a keyword.
  List<String> puzzleTypeText (int index)
  {
    List<String> result = [];
    // debugPrint('\nNumber of puzzle types = $_nTypes, selected index $index');

    // Split the string into lines, removing leading and trailing blanks.
    if ((index < _nTypes) && (index >= 0)) {
      result = puzzleTypes[index].split('\n');
      for (int i = 0; i < result.length; i++) {
        result[i] = result[i].trim();
        // debugPrint(result[i]);
      }
    }

    // Result-list will be empty if index was out of the valid range.
    return result;
  }

  static const List<String> puzzleTypes = [
''' Name Classic 4x4 Sudoku
    Description Each row, column and square block must contain each symbol 1-4 exactly once.
    Author Francesco Rossi
    FileName 4x4.xml
    Icon ksudoku-ksudoku_4x4
    SizeX 4
    SizeY 4
    SizeZ 1
    NSymbols 4
    SpecificType PlainSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name Tiny Samurai
    Description A small Samurai puzzle, with five overlapping 4x4 Sudoku puzzles.
    Author Francesco Rossi
    FileName TinySamurai.xml
    Icon ksudoku-tiny_samurai
    SizeX 10
    SizeY 10
    SizeZ 1
    NSymbols 4
    SpecificType TinySamurai
    PuzzleMap
    SudokuGroups 0  HasSquareBlocks
    SudokuGroups 60 HasSquareBlocks
    SudokuGroups 33 HasSquareBlocks
    SudokuGroups 6  HasSquareBlocks
    SudokuGroups 66 HasSquareBlocks '''
,
''' Name Classic 9x9 Sudoku
    Description Each row, column and square block must contain each symbol 1-9 exactly once.
    Author Francesco Rossi
    FileName 9x9.xml
    Icon ksudoku-ksudoku_9x9
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType PlainSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name 6x6 Pseudo Sudoku
    Description A 6x6 Sudoku puzzle with rectangular blocks that must each contain the symbols 1-6 exactly once.
    Author Ian Wadham
    FileName 6x6.xml
    Icon ksudoku-ksudoku_9x9
    SizeX 6
    SizeY 6
    SizeZ 1
    NSymbols 6
    SpecificType PseudoSudoku
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 6  0  1  6  7 12 13
    Group 6 18 19 24 25 30 31
    Group 6  2  3  8  9 14 15
    Group 6 20 21 26 27 32 33
    Group 6  4  5 10 11 16 17
    Group 6 22 23 28 29 34 35  '''
,
''' Name Aztec Pyramid 9x9
    Description The central square and the irregular blocks must each contain the symbols 1-9 exactly once.
    Author Ian Wadham
    FileName Aztec.xml
    Icon ksudoku-jigsaw
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType Aztec
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 9 0 1 9 10 11 19 20 21 29
    Group 9 18 27 28 36 37 38 45 46 54
    Group 9 47 55 56 57 63 64 65 72 73
    Group 9 2 3 4 5 6 12 13 14 22
    Group 9 30 31 32 39 40 41 48 49 50
    Group 9 58 66 67 68 74 75 76 77 78
    Group 9 7 8 15 16 17 23 24 25 33
    Group 9 26 34 35 42 43 44 52 53 62
    Group 9 51 59 60 61 69 70 71 79 80 '''
,
''' Name 3D Roxdoku 3x3x3
    Description Each of the nine 3x3 slices through the cube must contain the symbols 1-9 exactly once.
    Author Ian Wadham
    FileName DoubleRoxdoku.xml
    Icon ksudoku-roxdoku_3x3x3
    SizeX 3
    SizeY 3
    SizeZ 3
    NSymbols 9
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY 27
    SpecialCells 1 13
    PuzzleMap
    RoxdokuGroups 0 '''
,
''' Name Double 3D Roxdoku
    Description Three-dimensional puzzle with two interlocking 3x3x3 cubes.
    Author Ian Wadham
    FileName DoubleRoxdoku.xml
    Icon ksudoku-roxdoku_3x3x3
    SizeX 5
    SizeY 5
    SizeZ 3
    NSymbols 9
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY -27
    SpecialCells 3 36 37 38
    PuzzleMap
    RoxdokuGroups 0
    RoxdokuGroups 36 '''
,
''' Name Jigsaw 9x9
    Description The central square and the 8 jigsaw pieces must each contain the symbols 1-9 exactly once.
    Author Francesco Rossi
    FileName Jigsaw.xml
    Icon ksudoku-jigsaw
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType Jigsaw
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 9 0 1 2 9 10 28 18 19 20
    Group 9 3 4 5 12 13 11 21 22 23
    Group 9 6 7 8 15 16 17 24 14 26
    Group 9 27 55 29 36 37 38 45 46 47
    Group 9 30 31 32 39 40 41 48 49 50
    Group 9 33 34 35 42 43 44 51 25 53
    Group 9 54 66 56 63 64 65 72 73 74
    Group 9 57 58 59 69 67 68 75 76 77
    Group 9 60 61 62 52 70 71 78 79 80 '''
,
''' Name Tiny Killer Sudoku 4x4
    Description Same rules as 4x4 Sudoku, but each cage must also add to the total shown, using digits no more than once per cage.
    Author Ian Wadham
    FileName Killer_4x4.xml
    Icon ksudoku-ksudoku_4x4
    SizeX 4
    SizeY 4
    SizeZ 1
    NSymbols 4
    SpecificType KillerSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name Killer Sudoku 9x9
    Description Same rules as Classic 9x9 Sudoku, but each cage must also add to the total shown, using digits no more than once per cage.
    Author Ian Wadham
    FileName Killer_9x9.xml
    Icon ksudoku-ksudoku_9x9
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType KillerSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name Mathdoku 101 4x4
    Description Size 4x4 grid, with calculated cages. A digit can occur more than once in a cage.
    Author Ian Wadham
    FileName Mathdoku_4x4.xml
    Icon ksudoku-ksudoku_4x4
    SizeX 4
    SizeY 4
    SizeZ 1
    NSymbols 4
    SpecificType Mathdoku
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks '''
,
''' Name Mathdoku - Settable Size
    Description Size 3x3 to 9x9 grid, with calculated cages. A digit can occur more than once in a cage.
    Author Ian Wadham
    FileName Mathdoku_Settable.xml
    Icon ksudoku-ksudoku_9x9
    SizeX Mathdoku
    SizeY Mathdoku
    SizeZ 1
    NSymbols Mathdoku
    SpecificType Mathdoku
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks '''
,
''' Name Nonomino 9x9
    Description Jigsaw variant with irregularly shaped Nonomino (9 piece) blocks.
    Author Ian Wadham
    FileName Nonomino.xml
    Icon ksudoku-jigsaw
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType Jigsaw
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 9  0  9 18  1 10 19  2  3 12
    Group 9 27 28 37 46 47 56 65 66 75
    Group 9 36 45 54 63 72 55 64 73 74
    Group 9 11 20 29 38 21  4 13 22 31
    Group 9 30 39 48 57 40 23 32 41 50
    Group 9 49 58 67 76 59 42 51 60 69
    Group 9  5 14 15 24 33 34 43 52 53
    Group 9 68 77 78 61 70 79 62 71 80
    Group 9  6  7 16 25  8 17 26 35 44 '''
,
''' Name Pentomino 5x5
    Description Jigsaw variant with irregularly shaped Pentomino (5 piece) blocks.
    Author Ian Wadham
    FileName Pentomino.xml
    Icon ksudoku-jigsaw
    SizeX 5
    SizeY 5
    SizeZ 1
    NSymbols 5
    SpecificType PseudoSudoku
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 5  0  5  1  6  2
    Group 5 10 15 11 16 12
    Group 5 20 21 17 22 18
    Group 5  7  3  8 13  4
    Group 5 23  9 14 19 24 '''
,
''' Name 3D Roxdoku Twin
    Description Three-dimensional puzzle with two 3x3x3 cubes that share a corner.
    Author Ian Wadham
    FileName RoxdokuTwin.xml
    Icon ksudoku-roxdoku_3x3x3
    SizeX 5
    SizeY 5
    SizeZ 5
    NSymbols 9
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY -27
    SpecialCells 1 62
    PuzzleMap
    RoxdokuGroups 0
    RoxdokuGroups 62 '''
,
''' Name Samurai
    Description Classic Samurai puzzle, with five overlapping 9x9 Sudoku puzzles.
    Author Francesco Rossi
    FileName Samurai.xml
    Icon ksudoku-samurai
    SizeX 21
    SizeY 21
    SizeZ 1
    NSymbols 9
    SpecificType Samurai
    PuzzleMap
    SudokuGroups 0   HasSquareBlocks
    SudokuGroups 12  HasSquareBlocks
    SudokuGroups 132 NoSquareBlocks
    Group 9 135 136 137 156 157 158 177 178 179
    Group 9 195 196 197 216 217 218 237 238 239
    Group 9 198 199 200 219 220 221 240 241 242
    Group 9 201 202 203 222 223 224 243 244 245
    Group 9 261 262 263 282 283 284 303 304 305
    SudokuGroups 252 HasSquareBlocks
    SudokuGroups 264 HasSquareBlocks '''
,
''' Name Samurai 3D Roxdoku
    Description Samurai three-dimensional puzzle with nine overlapping 3x3x3 cubes.
    Author Ian Wadham
    FileName SamuraiRoxdoku.xml
    Icon ksudoku-roxdoku_3x3x3
    SizeX 7
    SizeY 7
    SizeZ 7
    NSymbols 9
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY -27
    SpecialCells 27 114 115 116 121 122 123 128 129 130 163 164 165 170 171 172 177 178 179 212 213 214 219 220 221 226 227 228
    PuzzleMap
    RoxdokuGroups 0
    RoxdokuGroups 196
    RoxdokuGroups 28
    RoxdokuGroups 224
    RoxdokuGroups 114
    RoxdokuGroups 4
    RoxdokuGroups 200
    RoxdokuGroups 32
    RoxdokuGroups 228 '''
,
''' Name Sohei
    Description Sohei puzzle with four overlapping 9x9 Sudoku squares and a hole in the middle.
    Author Ian Wadham
    FileName Sohei.xml
    Icon ksudoku-samurai
    SizeX 21
    SizeY 21
    SizeZ 1
    NSymbols 9
    SpecificType Sohei
    PuzzleMap
    SudokuGroups 126 HasSquareBlocks
    SudokuGroups 6   HasSquareBlocks
    SudokuGroups 258 HasSquareBlocks
    SudokuGroups 138 HasSquareBlocks '''
,
''' Name Tetromino 4x4
    Description Jigsaw with Tetromino size 4 blocks (Tetris pieces).
    Author Ian Wadham
    FileName Tetromino.xml
    Icon ksudoku-ksudoku_4x4
    SizeX 4
    SizeY 4
    SizeZ 1
    NSymbols 4
    SpecificType Jigsaw
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks
    Group 4 0  4  1  5
    Group 4  8 12 13 14
    Group 4  9 10 11 15
    Group 4  2  6  3  7 '''
    // Alternate Tetromino map. It works, but the last group is not perfect.
    // Group 4 0  1  4  8
    // Group 4 12 13 10 14
    // Group 4 5  9  2  6
    // Group 4 3  7 11 15
,
''' Name Windmill
    Description Windmill puzzle with five overlapping 9x9 Sudoku squares.
    Author Ian Wadham
    FileName Windmill.xml
    Icon ksudoku-samurai
    SizeX 21
    SizeY 21
    SizeZ 1
    NSymbols 9
    SpecificType Windmill
    PuzzleMap
    SudokuGroups 63  HasSquareBlocks
    SudokuGroups 255 HasSquareBlocks
    SudokuGroups 132 NoSquareBlocks
    Group 9 198 199 200 219 220 221 240 241 242
    SudokuGroups 9   HasSquareBlocks
    SudokuGroups 201 HasSquareBlocks '''
,
''' Name XSudoku 9x9
    Description Same rules as Classic 9x9 Sudoku, but each diagonal must also contain the symbols 1-9.
    Author Francesco Rossi
    FileName XSudoku.xml
    Icon ksudoku-xsudoku
    SizeX 9
    SizeY 9
    SizeZ 1
    NSymbols 9
    SpecificType XSudoku
    SpecialCells 17 0 10 20 30 40 50 60 70 80 8 16 24 32 48 56 64 72
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks
    Group 9 0 10 20 30 40 50 60 70 80
    Group 9 8 16 24 32 40 48 56 64 72 '''
,
''' Name Classic 16x16 Sudoku
    Description Each row, column and square block must contain each symbol A-P exactly once.
    Author Francesco Rossi
    Icon ksudoku-ksudoku_9x9
    SizeX 16
    SizeY 16
    SizeZ 1
    NSymbols 16
    SpecificType PlainSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name Classic 25x25 Sudoku
    Description Each row, column and square block must contain each symbol A-Y exactly once.
    Author Francesco Rossi
    Icon ksudoku-ksudoku_9x9
    SizeX 25
    SizeY 25
    SizeZ 1
    NSymbols 25
    SpecificType PlainSudoku
    PuzzleMap
    SudokuGroups 0 HasSquareBlocks '''
,
''' Name 3D Roxdoku 4x4x4
    Description Three-dimensional puzzle with one 4x4x4 cube, using the 16 symbols A-P.
    Author Francesco Rossi
    Icon ksudoku-roxdoku_3x3x3
    SizeX 4
    SizeY 4
    SizeZ 4
    NSymbols 16
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY 27
    PuzzleMap
    SpecialCells 8 21 22 25 26 37 38 41 42
    RoxdokuGroups 0 '''
,
''' Name 3D Roxdoku 5x5x5
    Description Three-dimensional puzzle with one 5x5x5 cube, using the 25 symbols A-Y.
    Author Francesco Rossi
    Icon ksudoku-roxdoku_3x3x3
    SizeX 5
    SizeY 5
    SizeZ 5
    NSymbols 25
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY 27
    SpecialCells 27 31 32 33 36 37 38 41 42 43 56 57 58 61 62 63 66 67 68 81 82 83 86 87 88 91 92 93
    PuzzleMap
    RoxdokuGroups 0 '''
,
''' Name 3D Windmill Roxdoku
    Description Windmill shaped hree-dimensional puzzle with five 3x3x3 cubes.
    Author Ian Wadham
    FileName SamuraiRoxdoku.xml
    Icon ksudoku-roxdoku_3x3x3
    SizeX 7
    SizeY 7
    SizeZ 3
    NSymbols 9
    SpecificType Roxdoku
    Diameter 350
    RotateX 15
    RotateY -27
    SpecialCells 12 48 49 50 54 55 56 90 91 92 96 97 98
    PuzzleMap
    RoxdokuGroups 0
    RoxdokuGroups 12
    RoxdokuGroups 48
    RoxdokuGroups 84
    RoxdokuGroups 96 '''
,
''' Name Blindfold Mathdoku 101
    Description Size 4x4 grid, with calculated cages, but the operators +-/x are hidden.
    Author Ian Wadham
    FileName Mathdoku_4x4.xml
    Icon ksudoku-ksudoku_4x4
    SizeX 4
    SizeY 4
    SizeZ 1
    NSymbols 4
    SpecificType Mathdoku
    HideOperators
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks '''
,
''' Name Blindfold Mathdoku
    Description Size 3x3 to 9x9 grid, with calculated cages, but the operators +-/x are hidden.
    Author Ian Wadham
    FileName Mathdoku_Settable.xml
    Icon ksudoku-ksudoku_9x9
    SizeX Mathdoku
    SizeY Mathdoku
    SizeZ 1
    NSymbols Mathdoku
    SpecificType Mathdoku
    HideOperators
    PuzzleMap
    SudokuGroups 0 NoSquareBlocks '''
,
  ];
}
