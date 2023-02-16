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

  final SettingsController settings;

  void handleSelection (int newSelection)
  {
    // print('PuzzleListView::handleSelection(); Selected Item $newSelection');
    PuzzleList   items     = const PuzzleList();
    List<String> item      = items.getItem(newSelection);
    settings.selectedIndex = newSelection;	// Save selection in Settings.
    settings.puzzleSpecID  = item[0];		// Save specID in Settings.
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder in app.dart and NotifyListeners() in SettingsController
    // guarantee a repaint whenever Difficulty, Symmetry, ThemeMode etc. change.
    Difficulty initialDifficulty = settings.difficulty;
    Symmetry   initialSymmetry   = settings.symmetry;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to MultiDoku'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: null,
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'More Settings',
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
          // Packing to avoid Debug stripe covering last icon.
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: () {},
          ),
        ],
      ),

// TODO - Sort out the highlighting of the last item selected AND automatically
//        scrolling to it. Wanted teal not red, but teal text not conspicuous...
// https://stackoverflow.com/questions/49153087/flutter-scrolling-to-a-widget-in-listview
//        Lots of interesting answers, many of them a bit hackish...

      body: ListTileTheme(
        selectedColor: Colors.green, // red[700],
        child: MyListView(
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
  const MyListView({required this.initialSelection,
                    required this.onChanged,
                    Key? key}) : super(key: key);

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
      itemCount:     items.length,
      itemBuilder:   (BuildContext context, int index) {
        List<String> item = items.getItem(index);
        return ListTile(
          title:       Text(item[1]),
          subtitle:    Text(item[2]),
          isThreeLine: true,
          leading:     Image.asset(
            // Display a MultiDoku icon from the assets folder.
            'assets/icons/hi48-action-${item[3]}.png',
            color: null,    // Don't blend in any colour.
          ),
          // Highlight prevous selection (from settings).
          selected:    index == _selectedIndex,
          enabled:     true,
          // Called when the user has selected an item from the list.
          onTap: () {
            item = items.getItem(index);
            debugPrint('TAP received: index = $index, item = $item');
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
            );
          } // End onTap: ()
        ); // End ListTile
      }, // End itemBuilder
    ); // End ListView.builder
  } // End Widget build()
} // End _MyListViewState class
