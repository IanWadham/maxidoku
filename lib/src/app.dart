/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// IDW TODO import 'app_lifecycle/app_lifecycle.dart';

import 'models/puzzle.dart';
import 'models/game_timer.dart';

import 'views/puzzle_view.dart';
import 'views/puzzle_list_view.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'settings/game_theme.dart';

class MaxiDokuApp extends StatelessWidget {
  // Adapted from the Flutter create command's "skeleton" example.

  const MaxiDokuApp(
    Puzzle this.puzzle, {
    Key? key,
    required this.settingsController,
    }
  ) : super(key: key);

  final SettingsController settingsController;
  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    // Make the MaterialApp listen for changes in Settings, by using the
    // AnimatedBuilder to listen to the SettingsController. So whenever the
    // user updates their settings, the MaterialApp and dependent widgets
    // can be rebuilt - IF the screen colors or appearance are affected.
    //
    // NOTE: In this instance the AnimatedBuilder does not listen for a tick of
    //       the clock. Rather it listens for any NotifyListeners() in the
    //       SettingsController, signalling a change in a Setting or Preference.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) { // The child is null.
        debugPrint('BUILD APP.');
        return MaterialApp(

          // Show stripe in work-version, but NOT in /Applications play-version.
          debugShowCheckedModeBanner: false, // No Debug stripe at top-right.

          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the required theme.
          theme: ThemeData(
            brightness:      Brightness.light,
            useMaterial3:    true,
          ),
          darkTheme: ThemeData(
            brightness:      Brightness.dark,
            useMaterial3:    true,
          ),
          themeMode: settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    // Show Settings screen.
                    return SettingsView(controller: settingsController);

                  case PuzzleView.routeName:
                    bool isDarkMode =
                         (Theme.of(context).brightness == Brightness.dark);

                    // Use Providers to monitor the state of the puzzle-model
                    // and then repaint puzzle-views, after any change of any
                    // kind: such as taps on puzzle or control cells by the user
                    // when making puzzle moves or taps on buttons to undo/redo
                    // moves, get a hint or generate a new puzzle. There are
                    // several places in the puzzle-model classes where they
                    // call notifyListeners(). The Providers listen for them.

                    debugPrint('\nMyApp: Create Providers,'
                               ' dark mode $isDarkMode.');
                    return MultiProvider(
                      providers: [
                        // Access to model of game in Puzzle class.
                        ChangeNotifierProvider.value(
                          value: puzzle,
                        ),
                        // Access to model of gameplay in PuzzlePlayer class.
                        ChangeNotifierProvider.value(
                          value: puzzle.puzzlePlayer,
                        ),
                        // Access to model of timer in GameTimer class.
                        ChangeNotifierProvider.value(
                          value: puzzle.gameTimer,
                        ),
                        // Access to Game Theme colours.
                        Provider(
// TODO - PROBLEM: This one re-creates GameTheme and changes Theme Brightness
//        colors, BUT PuzzleView keeps the same colors, until return to the menu
//        screen, selection of a Puzzle and PuzzleView starting a new puzzle.
//        The menu and settings screens go dark or light as the setting changes.
                          create: (context) => GameTheme(isDarkMode),
                          lazy:   false,
                        ),
                      ],
                      builder: (context, child) {
                      // Top widget of puzzle screen.
                      // ?????? child: PuzzleView(puzzle, isDarkMode,
                      final value = context.watch<GameTheme>();
                      return PuzzleView(puzzle, isDarkMode,
                        settings: settingsController
                        );
                      }
                      // ?????? ),
                    ); // End MultiProvider.

                  case PuzzleListView.routeName:
                  default:
                    // Choose from a list of puzzle types and sizes.
                    return PuzzleListView(settings: settingsController);
                }
              },
            );
          },
        ); // End MaterialApp.
      }, // }, // End builder:
    ); // ); // End AnimatedBuilder.
  }
}
