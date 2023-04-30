/*
    SPDX-FileCopyrightText: 2023      Ian Wadham <iandw.au@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import 'package:flutter/material.dart';

import '../settings/game_theme.dart';

// Because the message is issued by the AlertDialog in a changed Build Context,
// Provider will not find the GameTheme object (red screen of death at run time)
// and there is an optional gameTheme parameter in the Message calls.

Future<bool> questionMessage(
  BuildContext context,
  String heading,
  String question,
  {
  // Optional named parameters and their default values.
  String yesText = 'Yes',
  String noText  = 'No',
  GameTheme? gameTheme,
  }
) async
{
  // Set up the buttons.
  Widget yesButton = TextButton(
    child: Text(yesText),
    onPressed: () {
      debugPrint('User pressed $yesText button in questionMessage()');
      Navigator.of(context).pop(true);	// Dismiss the dialog box.
    },
  );
  Widget noButton = TextButton(
    child: Text(noText),
    onPressed: () {
      debugPrint('User pressed $noText button in questionMessage()');
      Navigator.of(context).pop(false);	// Dismiss the dialog box.
    },
  );
  // Set up the AlertDialog. 
  Color? background = gameTheme?.messageBkgrColor;
  AlertDialog alert = AlertDialog(
    title:   Text(heading),
    content: Text(question),
    backgroundColor: background,
    actions: [
      noButton,
      yesButton,
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
  GameTheme? gameTheme,
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
  Color? background = gameTheme?.messageBkgrColor;
  AlertDialog alert = AlertDialog(
    title:   Text(heading),
    content: Text(information),
    backgroundColor: background,
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
