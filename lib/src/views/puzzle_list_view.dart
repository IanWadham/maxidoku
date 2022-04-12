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
                child: Text('Very Easy'),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Easy,
                child: Text('Easy'),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Medium,
                child: Text('Medium'),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Hard,
                child: Text('Hard'),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Diabolical,
                child: Text('Diabolical'),
              ),
              const PopupMenuItem<Difficulty>(
                value: Difficulty.Unlimited,
                child: Text('Unlimited'),
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
                child: Text('Diagonal'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.CENTRAL,
                child: Text('Central'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.LEFT_RIGHT,
                child: Text('Left-Right'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.SPIRAL,
                child: Text('Spiral'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.FOURWAY,
                child: Text('Four-Way'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.RANDOM_SYM,
                child: Text('Randomly Chosen Symmetry'),
              ),
              const PopupMenuItem<Symmetry>(
                value: Symmetry.NONE,
                child: Text('No Symmetry'),
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
        ],
      ),
      body: MyListView(initialSelection: settings.selectedIndex,
                              onChanged: handleSelection),
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
  _MyListViewState createState() => _MyListViewState();
}

/// This is the private State class that goes with MyListView.
class _MyListViewState extends State<MyListView>
{
  final PuzzleList items = const PuzzleList();

  int _selectedIndex = -1;

@override
  void _handleTap ()
  {
    widget.onChanged (_selectedIndex);
  }

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
            'assets/icons/hi48-action-' + item[3] + '.png',
            color: null,    // Don't blend in any colour.
          ),
          // Highlight prevous selection (from settings).
          selected:    index == _selectedIndex,
          enabled:     true,	// TODO - Use for unavailable puzzles?
          // Called when the user has selected an item from the list.
          onTap: () {
            item = items.getItem(index);
            print('TAP received: index = $index, item = $item');
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
