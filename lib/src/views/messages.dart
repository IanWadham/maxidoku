import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../settings/game_theme.dart';

// TODO - Use a better barrier colour than black54 (black with 54% opacity),
//        use better backround and foreground colours for the message area
//        and shape and size the message-area nicely, e.g. rounded corners.

Future<bool> questionMessage(
  BuildContext context,
  String heading,
  String question,
  {
  // Optional named parameters and their default values.
  String okText     = 'Yes',
  String cancelText = 'No',
  // String ignoreText = '',	// No good. Makes an invisible tappable button.
  }
) async
{
  // Set up the buttons.
  Widget okButton = TextButton(
    child: Text(okText),
    onPressed: () {
      debugPrint('User pressed $okText button in questionMessage()');
      Navigator.of(context).pop(true);	// Dismiss the dialog box.
    },
  );
  Widget cancelButton = TextButton(
    child: Text(cancelText),
    onPressed: () {
      debugPrint('User pressed $cancelText button in questionMessage()');
      Navigator.of(context).pop(false);	// Dismiss the dialog box.
    },
  );
  // Widget ignoreButton = TextButton(
    // child: Text(ignoreText),
    // onPressed: () {
      // debugPrint('User pressed $ignoreText button in questionMessage()');
      // Navigator.of(context).pop(false);	// Dismiss the dialog box.
    // },
  // );
  // Set up the AlertDialog.
  AlertDialog alert = AlertDialog(
    title:   Text(heading),
    content: Text(question),
    backgroundColor:  Colors.amber.shade100,
    actions: [
      // ignoreButton,
      cancelButton,
      okButton,
    ],
  );

  bool reply = await showDialog(
      context: context,
      barrierDismissible: false,	// User must tap button, not background.
      barrierColor: Colors.transparent,
      builder: (BuildContext context)
      {
        return alert;
      },
    );
  return reply;
}

Future<void> infoMessage
(
  BuildContext context,
  String heading,
  String information,
  {
  // Optional named parameter and its default value.
  String okText     = 'OK',
  }
)
async
{
  // Set up the buttons.
  Widget okButton = TextButton(
    child: Text(okText),
    onPressed: () {
      Navigator.of(context).pop();	// Dismiss the dialog box.
    },
  );
  // Set up the AlertDialog.
  AlertDialog alert = AlertDialog(
    title:   Text(heading),
    content: Text(information),
    backgroundColor:  Colors.amber.shade100,
    actions: [
      okButton,
    ],
  );
  // Show the info message.
  // bool? reply = await showDialog(
  await showDialog(
    context: context,
    barrierDismissible: false,		// User must tap button, not background.
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
