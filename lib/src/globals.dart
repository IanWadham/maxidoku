// ignore_for_file: constant_identifier_names
// Flutter likes names of constants to start in lower-case then use Camel Case.

/* **************************************************************************
 *    Copyright 2007      Francesco Rossi <redsh@email.it>                  *
 *    Copyright 2006-2007 Mick Kappenburg <ksudoku@kappendburg.net>         *
 *    Copyright 2011  Ian Wadham <iandw.au@gmail.com>                       *
 *    Copyright 2015  Ian Wadham <iandw.au@gmail.com>                       *
 *                                                                          *
 *    This program is free software; you can redistribute it and/or         *
 *    modify it under the terms of the GNU General Public License as        *
 *    published by the Free Software Foundation; either version 2 of        *
 *    the License, or (at your option) any later version.                   *
 *                                                                          *
 *    This program is distributed in the hope that it will be useful,       *
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *    GNU General Public License for more details.                          *
 *                                                                          *
 *    You should have received a copy of the GNU General Public License     *
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>. *
 ***************************************************************************/

// NOTE: On most platforms Dart/Flutter integers are 64 bits, BUT in Web apps,
//       based on JavaScript, bit-wise operations are limited to 32 bits and
//       true integers are whatever fits a float with exponent zero. So the
//       following definitions are constrained to be +ve integers < 32 bits.

// Definitions of Sudoku, Roxdoku and Mathdoku cell values.

// There is a maximum of 25 symbols,represented visually as 1-9 or A-Y.

const int MaxValue  = 25;
const int MaxValue1 = MaxValue + 1;

// If the NotesBit is 0, the cell contains a single value and the MaxValue1
// value represents an UNUSABLE cell, as in Samurai and some Roxdoku puzzles.
// If the NotesBit is 1, bits 1-25 represent Notes with values 1-25. 

const int NotesBit  = 1 << MaxValue1;

// Play-status of the Puzzle. Determines what user-actions are valid any time.
enum Play {NotStarted, BeingEntered, ReadyToStart, InProgress, Solved, HasError}

// Integers used as cell-statuses during puzzle-generation and play.

// Each type may also have its own colour or highlight. All except SPECIAL are
// used in puzzle generation and play. VACANT, CORRECT and NOTES cells are
// painted in the normal cell-colour. GIVEN cells and (optionally) ERROR cells
// have a colour or highlight that overlays or replaces the normal cell-colour.

const int UNUSABLE = MaxValue1;	// Cell is in background, not part of puzzle.
const int VACANT   = 0;		// Empty cell painted in the main cell-colour.
const int GIVEN    = 1;		// A clue given by a puzzle-generator.
const int CORRECT  = 2;		// Contains a symbol that matches the solution.
const int ERROR    = 3;		// Optionally painted to show a user-error.
const int NOTES    = 4;		// Contains a bit-map of Notes.
const int INVALID  = 5;		// No move: the user's move was invalid.

// The following is used ONLY for a colour in 2D Painting Specs and Puzzle View.

const int SPECIAL  =  6;	// Painted a special colour (eg. XSudoku diags).

// Symbols used when displaying, printing or storing puzzles.
// Digits are used for sizes up to 9x9, letters for sizes 16x16 and 25x25.
const String digits  = '.123456789';
const String letters = '.ABCDEFGHIJKLMNOPQRSTUVWXY';

// The SudokuType and size determine which puzzle is generated and which
// puzzle-generator class is used, Mathdoku for Killer and Mathdoku types,
// Sudoku for all the other puzzles, including Samurai and 3D Roxdoku types.

enum SudokuType {PlainSudoku, XSudoku, Jigsaw, Samurai, TinySamurai, Roxdoku,
                 Aztec, Mathdoku, KillerSudoku, Sohei, Windmill, PseudoSudoku,
                 EndSudokuTypes, Invalid}

// Const Difficulty and Symmetry texts must appear as simple names in Flutter's
// StatelessWidgets, but are needed in lookup-lists for generated messages.

enum Difficulty {VeryEasy, Easy, Medium, Hard, Diabolical, Unlimited}

const String diff0 = 'Very Easy';
const String diff1 = 'Easy';
const String diff2 = 'Medium';
const String diff3 = 'Hard';
const String diff4 = 'Diabolical';
const String diff5 = 'Unlimited';
const List<String> difficultyTexts =
                             [diff0, diff1, diff2, diff3, diff4, diff5];

enum Symmetry   {DIAGONAL_1, CENTRAL, LEFT_RIGHT, SPIRAL, FOURWAY,
                 RANDOM_SYM, NONE, DIAGONAL_2}

const String symm0 = 'Diagonal';
const String symm1 = 'Central';
const String symm2 = 'Left-Right';
const String symm3 = 'Spiral';
const String symm4 = 'Four-Way';
const String symm5 = 'Randomly Chosen Symmetry';
const String symm6 = 'No Symmetry';
const List<String> symmetryTexts =
                           [symm0, symm1, symm2, symm3, symm4, symm5, symm6];

enum CageOperator {NoOperator, Divide, Subtract, Multiply, Add}

typedef CellValue     = int;		// Bits or a value, see consts above.

typedef CellStatus    = int;		// Cell status, see consts above.

typedef BoardContents = List<int>;	// Cell values or statuses, see above.

typedef Pair         = int;		// Two small integers packed into one.
const int lowWidth   = 8;		// Right-hand value is 8 bits.
const int lowMask    = 255;		// Mask for right-hand value.

typedef Move         = Pair;		// Position (pairPos) | value (pairVal).
typedef MoveList     = List<Move>;
typedef MoveTypeList = List<MoveType>;

enum    MoveType     {Single, Spot, Guess, Wrong, Deduce, Result}

enum    GuessingMode {Random, NotRandom}

// The maximum digit that can be used in a Mathdoku or Killer Sudoku puzzle.
const int MaxMathOrder = 9;

// CELL CONSTANTS --- Proportional values for painting cells
//                    in the puzzle's board and control bar.

const double topMargin         = 0.2;	// Proportion of top margin.
const double bottomMargin      = 0.2;	// Proportion of bottom margin.
const double bottomNotesMargin = 0.15;	// Proportion of bottom Notes margin.

// The proportion of the cell taken up by a single Sudoku symbol.
const double symbolFraction    = 1.0 - topMargin - bottomMargin;

const double thinGridFactor    = 30.0;	// Divisor for thin grid-line's width.
const double boldGridFactor    = 15.0;	// Divisor for thick grid-line's width.
const double cageGridFactor    = 20.0;	// Divisor for cage-outline's width.
const double cageInsetFactor   = 12.0;	// Divisor for cage-outline's inset.
const double labelInsetFactor  = 20.0;	// Divisor for cage-label's inset.
const double labelTextFactor   =  6.0;	// Divisor for cage-label's text-size.


class Message
{
  String     messageType;
  String     messageText;
  Message(this.messageType, this.messageText);
}

class CellState			// Used by model of puzzle and view of puzzle.
{
  CellStatus status;		// Cell status: values defined above.
  CellValue  cellValue;		// Bits or int as defined above.

  CellState(this.status, this.cellValue);
}

class PuzzleState		// Used by model of puzzle and view of puzzle.
{
  int        position;		// Position of last move.
  CellState  cellState;		// Cell state: values defined above.
  Play       playBefore;
  Play       playAfter;

  final Message    _message = Message('', '');

  PuzzleState(this.position, this.cellState, this.playBefore, this.playAfter);

  String get messageType => _message.messageType;
  String get message     => _message.messageText;

         set messageType(String t) => _message.messageType = t;
         set message(String s)     => _message.messageText = s;
}
