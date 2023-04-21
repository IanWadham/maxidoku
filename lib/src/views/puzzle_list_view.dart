import 'package:flutter/material.dart';

import '../settings/settings_view.dart';
import '../settings/settings_controller.dart';
import '../globals.dart';
import '../models/puzzle_list.dart';
import 'puzzle_view.dart';

/// Displays a list of Sudoku puzzles of various sizes and layouts.
class PuzzleListView extends StatelessWidget
{
  const PuzzleListView({
    Key? key,
    required this.settings,
  }) : super(key: key);

  static const routeName = '/';

  static const List<String> selections = [
                 "Beginners' Selection", "Main Selection",
                 "Additional Selection", "Tap In A Puzzle"];

  final SettingsController settings;

  void handleSelection (int newSelection)
  {
    PuzzleList   items     = const PuzzleList();
    List<String> item      = items.getItem(settings.puzzleRange, newSelection);
    settings.selectedIndex = newSelection;	// Save selection in Settings.
    settings.puzzleSpecID  = item[0];		// Save specID in Settings.
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder in app.dart and NotifyListeners() in SettingsController
    // guarantee a repaint whenever Difficulty, Symmetry, ThemeMode etc. change.

    Difficulty initialDifficulty  = settings.difficulty;
    Symmetry   initialSymmetry    = settings.symmetry;
    int        initialPuzzleRange = settings.puzzleRange;

    // TODO - Tried to get a copy of the AppBar's titleTextStyle, but could
    //        not get the Theme ... titleMedium approach to work. My "print"
    //        gets specs that look reasonable, but are NOT a TextStyle type.
    // TextStyle myStyle = Theme.of(context)!.textTheme!.titleMedium!;
    // if (myStyle == null) {
      // print('Could not get AppBar title text style.');
    // }
    // else print('MY STYLE ${myStyle.toString()}');

    TextStyle myStyle = TextStyle(		// Imitate AppBar style...
      inherit: true,
      color: Colors.white,
      fontSize: 16.0,);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MaxiDoku"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Align(				// ... to add AppBar subtitle.
            alignment: Alignment.centerLeft,	// Don't let the Text center,
            child: Padding(			// but indent and style it.
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                selections[settings.puzzleRange],
                style: myStyle,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: null,
        // TODO - Move AppBar actions: to bottom: and TabBar()... ?
        //        See example in AppBar API doco.
        actions: [
          PopupMenuButton<Difficulty>(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Difficulty',
            initialValue: initialDifficulty,
            onSelected: settings.setDifficulty,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Difficulty>>[
              const PopupMenuItem<Difficulty>(
                value: Difficulty.VeryEasy,
                child: Text(diff0),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Easy,
                child: Text(diff1),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Medium,
                child: Text(diff2),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Hard,
                child: Text(diff3),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Diabolical,
                child: Text(diff4),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Unlimited,
                child: Text(diff5),
              ),
            ],
          ),
          PopupMenuButton<Symmetry>(
            icon: const Icon(Icons.all_out),
            tooltip: 'Symmetry',
            initialValue: initialSymmetry,
            onSelected: settings.setSymmetry,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Symmetry>>[
              const PopupMenuItem<Symmetry>(
                value: Symmetry.DIAGONAL_1,
                child: Text(symm0),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.CENTRAL,
                child: Text(symm1),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.LEFT_RIGHT,
                child: Text(symm2),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.SPIRAL,
                child: Text(symm3),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.FOURWAY,
                child: Text(symm4),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.RANDOM_SYM,
                child: Text(symm5),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.NONE,
                child: Text(symm6),
              ),
            ],
          ),
          PopupMenuButton<int>(
            child: Text('Menu...', style: myStyle),
            tooltip: 'Select range of puzzles',
            initialValue: initialPuzzleRange, 
            itemBuilder: (context){
              return [
                PopupMenuItem<int>(
                  value: 0,
                  child: Text(selections[0]),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: Text(selections[1]),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Text(selections[2]),
                ),
                PopupMenuItem<int>(
                  value: 3,
                  child: Text(selections[3]),
                ),
              ];
            },
            onSelected: (value) {
              // _listNumber = value;
              settings.puzzleRange = value;
            }
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'More Settings',
            color: Colors.white,
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),

// TODO - Sort out the highlighting of the last item selected AND automatically
//        scrolling to it.
// https://stackoverflow.com/questions/49153087/flutter-scrolling-to-a-widget-in-listview
//        Lots of interesting answers, many of them a bit hackish...

      body: ListTileTheme(
        selectedColor: Colors.teal, // green,
        child: MyListView(
          listNumber: settings.puzzleRange,
          initialSelection: settings.selectedIndex,
          onChanged: handleSelection,
        ),
      ),
    );
  }
}

/// A stateful ListView which updates tile selections and provides a callback.
class MyListView extends StatefulWidget
{
  const MyListView({required this.listNumber,
                    required this.initialSelection,
                    required this.onChanged,
                    Key? key}) : super(key: key);

  final int listNumber;
  final int initialSelection;
  final ValueChanged<int> onChanged;
 
  @override
  createState() => _MyListViewState();
}

/// This is the private State class that goes with MyListView.
class _MyListViewState extends State<MyListView>
{
  final PuzzleList items = const PuzzleList();

  int _selectedIndex = -1;

  void _handleTap ()
  {
    widget.onChanged (_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    // To work with lists that may contain a large number of items, it’s best
    // to use the ListView.builder constructor.
    //
    // In contrast to the default ListView constructor, which requires
    // building all Widgets up front, the ListView.builder constructor lazily
    // builds Widgets as they are scrolled into view.
    if (_selectedIndex == -1) {
      _selectedIndex = widget.initialSelection;
    }
    return ListView.builder(
      // Providing a restorationId allows the ListView to restore the
      // scroll position when a user leaves and returns to the app after it
      // has been killed while running in the background.
      restorationId: 'puzzleListView',
      itemCount:     items.listLength(widget.listNumber),
      itemBuilder:   (BuildContext context, int index) {
        List<String> item = items.getItem(widget.listNumber, index);
        return ListTile(
          title:       Text(item[1]),
          subtitle:    Text(item[2]),
          isThreeLine: true,
          leading:     Image.asset(
            // Display a MaxiDoku icon from the assets folder.
            'assets/icons/hi48-action-${item[3]}.png',
            color: null,    // Don't blend in any colour.
          ),
          // Highlight prevous selection (from settings).
          selected:    index == _selectedIndex,
          enabled:     true,
          // Called when the user has selected an item from the list.
          onTap: () {
            // TODO - Call a small function in models/puzzle_list.dart.
            List<int> parameters = [];	// Parameters to be sent to PuzzleView.
            parameters.add(PuzzleList.puzzles[widget.listNumber].first);
            parameters.add(PuzzleList.puzzles[widget.listNumber][index + 1]);
            print('Parameters for PuzzleView: $parameters');

            item = items.getItem(widget.listNumber, index);
            // Make the highlight on this selection persist.
            setState(() { _selectedIndex = index; });
            // Pass the selection to app.dart via the Settings Controller.
            _handleTap();
            // Navigate to the details page via app.dart. If the user leaves
            // and returns to the app after it has been killed while running
            // in the background, the navigation stack is restored.
            Navigator.restorablePushNamed(
              context,
              PuzzleView.routeName,
              arguments: parameters,
            );
          } // End onTap: ()
        ); // End ListTile
      }, // End itemBuilder
    ); // End ListView.builder
  } // End Widget build()
} // End _MyListViewState class
