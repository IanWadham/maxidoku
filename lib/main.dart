import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

import 'src/models/puzzle.dart';

void main() async {

  // Start up the persistent-storage package for Settings (on file).
  // Remembering a player's preferences between sessions is an
  // important feature of MultiDoku

  await GetStorage.init();

  // Set up the SettingsController and SettingsService. These will provide
  // user-chosen values to multiple Flutter Widgets and Data Models.

  final settingsController = SettingsController(SettingsService());

  // Load the saved values of Settings, including the preferred Colour Theme.
  // Do this while/if a splash screen is displayed, to prevent a sudden theme
  // change when the app is first displayed.

  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes that require a screen repaint. The Puzzle
  // object and its friends PuzzleMap and PuzzlePlayer are also constructed.

  runApp(MultiDokuApp(Puzzle(), settingsController: settingsController));
}
