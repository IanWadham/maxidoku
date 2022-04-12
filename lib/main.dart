import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  // Start up the persistent-storage package for Settings (on file).
  //
  // The GetStorage package is preferred over SharedSettings because it is
  // synchronous (apart from the startup line below), worked "out of the box",
  // avoided all the async/Future/null coding-tangles that came with
  // SharedSettings and made it easy to encapsulate the package-dependent
  // settings-details in the SettingsService class.
  await GetStorage.init();

  // Set up the SettingsController and SettingsService. These will provide
  // user-chosen values to multiple Flutter Widgets and Data Models.
  final settingsController = SettingsController(SettingsService());

  // Load the saved values of Settings, including the preferred Colour Theme.
  // Do this while/if a splash screen is displayed, to prevent a sudden theme
  // change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes.
  runApp(MyApp(settingsController: settingsController));
}
