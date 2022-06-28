import 'puzzle_types.dart';

/// A placeholder class that represents an entity or model.
class PuzzleList
{
  const PuzzleList();

  int get length => puzzleList.length;

  List<String> getItem(int index) => puzzleList[index];

  // static const List<List<String>> puzzleList =
  static const List<List<String>> puzzleList =
  [
  ['2', // Puzzle ID
  'Classic 9x9 Sudoku',
  'Each row, column and square block must contain each symbol 1-9 exactly once.',
  // Author Francesco Rossi
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['5', // Puzzle ID
  'Roxdoku 9 (3x3x3)',
  'Three-dimensional puzzle with one 3x3x3 cube',
  // Author Ian Wadham
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['9', // Puzzle ID
  'Killer Sudoku',
  'Classic Sudoku, but cages must add to totals shown',
  // Author Ian Wadham
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['11', // Puzzle ID
  'Mathdoku - Settable Size',
  'Size 3x3 to 9x9 grid, with calculated cages',
  // Author Ian Wadham
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['15', // Puzzle ID
  'Samurai',
  'Samurai shape puzzle',
  // Author Francesco Rossi
  'ksudoku-samurai' // Icon ID
  ],
  ['20', // Puzzle ID
  'XSudoku',
  'XSudoku shape puzzle',
  // Author Francesco Rossi
  'ksudoku-xsudoku' // Icon ID
  ],
  ['0', // Puzzle ID
  'Classic 4x4 Sudoku',
  'Each row, column and square block must contain each symbol 1-4 exactly once.',
  // Author Francesco Rossi
  'ksudoku-ksudoku_4x4' // Icon ID
  ],
  ['1', // Puzzle ID
  'Tiny Samurai',
  'A smaller samurai puzzle',
  // Author Francesco Rossi
  'ksudoku-tiny_samurai' // Icon ID
  ],
  ['3', // Puzzle ID
  '6x6 Pseudo Sudoku',
  '6x6 puzzle with rectangular blocks',
  // Author Ian Wadham
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['4', // Puzzle ID
  'Aztec',
  'Jigsaw variant shaped like an Aztec pyramid',
  // Author Ian Wadham
  'ksudoku-jigsaw' // Icon ID
  ],
  ['6', // Puzzle ID
  'Double Roxdoku',
  'Three-dimensional puzzle with two interlocking 3x3x3 cubes',
  // Author Ian Wadham
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['7', // Puzzle ID
  'Jigsaw',
  'Jigsaw shape puzzle',
  // Author Francesco Rossi
  'ksudoku-jigsaw' // Icon ID
  ],
  ['8', // Puzzle ID
  'Tiny Killer',
  '4x4 Sudoku, but cages must add to totals shown',
  // Author Ian Wadham
  'ksudoku-ksudoku_4x4' // Icon ID
  ],
  ['10', // Puzzle ID
  'Mathdoku 101',
  'Size 4x4 grid, with calculated cages',
  // Author Ian Wadham
  'ksudoku-ksudoku_4x4' // Icon ID
  ],
  ['12', // Puzzle ID
  'Nonomino 9x9',
  'Jigsaw variant with irregularly shaped Nonomino blocks',
  // Author Ian Wadham
  'ksudoku-jigsaw' // Icon ID
  ],
  ['13', // Puzzle ID
  'Pentomino 5x5',
  'Jigsaw variant with irregularly shaped Pentomino blocks',
  // Author Ian Wadham
  'ksudoku-jigsaw' // Icon ID
  ],
  ['14', // Puzzle ID
  'Roxdoku Twin',
  'Three-dimensional puzzle with two 3x3x3 cubes which share a corner',
  // Author Ian Wadham
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['16', // Puzzle ID
  'Samurai Roxdoku',
  'Samurai three-dimensional puzzle with nine 3x3x3 cubes',
  // Author Ian Wadham
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['17', // Puzzle ID
  'Sohei',
  'Sohei puzzle with four overlapping 9x9 squares',
  // Author Ian Wadham
  'ksudoku-samurai' // Icon ID
  ],
  ['18', // Puzzle ID
  'Tetromino 4x4',
  'Jigsaw with Tetromino blocks (Tetris pieces)',
  // Author Ian Wadham
  'ksudoku-ksudoku_4x4' // Icon ID
  ],
  ['19', // Puzzle ID
  'Windmill',
  'Windmill puzzle with five overlapping 9x9 squares',
  // Author Ian Wadham
  'ksudoku-samurai' // Icon ID
  ],
  ['21', // Puzzle ID
  'Classic 16x16 Sudoku',
  'Each row, column and square block must contain each symbol A-P exactly once.',
  // Author Francesco Rossi
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['22', // Puzzle ID
  'Classic 25x25 Sudoku',
  'Each row, column and square block must contain each symbol A-Y exactly once.',
  // Author Francesco Rossi
  'ksudoku-ksudoku_9x9' // Icon ID
  ],
  ['23', // Puzzle ID
  'Roxdoku 16 (4x4x4)',
  'Three-dimensional puzzle with one 4x4x4 cube',
  // Author Francesco Rossi
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['24', // Puzzle ID
  'Roxdoku 25 (5x5x5)',
  'Three-dimensional puzzle with one 5x5x5 cube',
  // Author Francesco Rossi
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ['25', // Puzzle ID
  'Windmill Roxdoku',
  'Windmill three-dimensional puzzle with five 3x3x3 cubes',
  // Author Ian Wadham
  'ksudoku-roxdoku_3x3x3' // Icon ID
  ],
  ];
}

/*
class PuzzleInfo 
{
  PuzzleInfo(String name,
             String description,
             String iconFilePath,
             int    specIndex)
    :
    _name         = name,
    _description  = description,
    _iconFilePath = iconFilePath,
    _specIndex    = specIndex
  {
  }

  String get name         => _name;
  String get description  => _description;
  String get iconFilePath => _iconFilePath;
  int    get specIndex    => _specIndex;

  String _name;
  String _description;
  String _iconFilePath;
  int    _specIndex;
}
*/
