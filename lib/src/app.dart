import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// IDW TODO import 'app_lifecycle/app_lifecycle.dart';

import 'models/puzzle.dart';
import 'views/puzzle_view.dart';
import 'views/puzzle_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {

/* IDW GoRouter disabled for now.
  static final _router = GoRouter(
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) =>
              const MainMenuScreen(key: Key('main menu')),
          routes: [
            GoRoute(
                path: 'play',
                pageBuilder: (context, state) => buildMyTransition<void>(
                      child: const LevelSelectionScreen(
                          key: Key('level selection')),
                      color: context.watch<Palette>().backgroundLevelSelection,
                    ),
                routes: [
                  GoRoute(
                    path: 'session/:level',
                    pageBuilder: (context, state) {
                      final levelNumber = int.parse(state.params['level']!);
                      final level = gameLevels
                          .singleWhere((e) => e.number == levelNumber);
                      return buildMyTransition<void>(
                        child: PlaySessionScreen(
                          level,
                          key: const Key('play session'),
                        ),
                        color: context.watch<Palette>().backgroundPlaySession,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'won',
                    pageBuilder: (context, state) {
                      final map = state.extra! as Map<String, dynamic>;
                      final score = map['score'] as Score;

                      return buildMyTransition<void>(
                        child: WinGameScreen(
                          score: score,
                          key: const Key('win game'),
                        ),
                        color: context.watch<Palette>().backgroundPlaySession,
                      );
                    },
                  )
                ]),
            GoRoute(
              path: 'settings',
              builder: (context, state) =>
                  const SettingsScreen(key: Key('settings')),
            ),
          ]),
    ],
  );
*/ // IDW End GoRouter disabled for now.

  const MyApp({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Make the MaterialApp listen for changes in Settings, by using the
    // AnimatedBuilder to listen to the SettingsController. So whenever
    // the user updates their settings, the MaterialApp and dependent
    // widgets are rebuilt.
    //
    // NOTE: In this instance the AnimatedBuilder does not listen for a tick of
    //       the clock. Rather it listens for any NotifyListeners() in the
    //       SettingsController, signalling a change in a Setting or Preference.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(

          // Show stripe in work-version, but NOT in /Applications play-version.
          // debugShowCheckedModeBanner: false, // No Debug stripe at top-right.

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
          // TODO - Home screen's appBar is white, not teal, since Flutter 3.
          //        So what colours are acceptable as a "seed" and does it make
          //        a difference which type of seed invocation is used?
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            // primaryColor: Colors.teal,
            brightness:      Brightness.light,
            // useMaterial3:    true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            // primaryColor: Colors.teal,
            brightness:      Brightness.dark,
            // useMaterial3:    true,
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
                    // Show selected puzzle board.
                    String puzzleSpecID = settingsController.puzzleSpecID;
                    int    index = int.tryParse(puzzleSpecID, radix: 10) ?? 1;

                    // Use Provider to monitor the state of the Puzzle model
                    // and then repaint the Puzzle View after any change of any
                    // kind: such as taps on the CustomPaint Canvas by the user
                    // when making Puzzle moves or taps on buttons to Undo/Redo
                    // moves, get a Hint or generate a new Puzzle. There are
                    // several places in the Puzzle Class code where it calls
                    // notifyListeners() and these are watched for by Provider.

                    bool darkMode =
                         (Theme.of(context).brightness == Brightness.dark);

// IDW TODO - Should have separate Provider for Palette and Dark/Light changes,
//            and maybe for other purposes (see examples in TicTacToe game).

                    return ChangeNotifierProvider(
                      create: (context) =>		// The Model to watch.
                              Puzzle(index, settingsController, darkMode),
                      lazy:   false,			// Create Puzzle NOW, to
                                                        // avoid startup crash.
                      child:  PuzzleView(darkMode),	// Top widget of screen.
                    );

                  case PuzzleListView.routeName:
                  default:
                    // Show a list of available puzzle types and sizes.
                    return PuzzleListView(settings: settingsController);
                }
              },
            );
          },
        );
      },
    );
  }
}
