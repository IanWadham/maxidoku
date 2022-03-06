import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/puzzle.dart';
import 'views/puzzle_view.dart';
import 'views/puzzle_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.settingsController,
  }) : super(key: key);

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // TODO - Try out the shared_preferences package. It is Flutter's most
    //        popular package. Sounds as if it is something like KConfig.
    //
    // Glue the SettingsController to the MaterialApp.
    //
    // The AnimatedBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // TODO - DROP THIS body: const MyStatefulWidget(),

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
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
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
                    // Show empty layout of selected puzzle board.
                    String puzzleSpecID = settingsController.puzzleSpecID;
                    int index = int.tryParse(puzzleSpecID, radix: 10) ?? 1;

                    // Use Provider to monitor the state of the Puzzle model
                    // and repaint the Puzzle View after any change of any type:
                    // such as taps on the CustomPaint Canvas by the user when
                    // making Puzzle moves or taps on buttons to Undo/Redo
                    // moves, get a Hint or generate a new Puzzle. There are
                    // several places in the Puzzle Class code where it calls
                    // notifyListeners() and these are watched for by Provider.

                    return ChangeNotifierProvider(
                      create: (context) => Puzzle(),	// Model to watch.
                      child:  PuzzleView(index),	// Top widget in screen.
                      lazy:   false,			// Create Puzzle NOW, to
                                                        // avoid startup crash.
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
