import 'package:flutter/material.dart';

Future<bool> questionMessage(
  BuildContext context,
  String heading,
  String question,
  {
  // Optional named parameters and their default values.
  String okText     = 'Yes',
  String cancelText = 'No',
  }
) async
{
  // Set up the buttons.
  Widget okButton = TextButton(
    child: Text(okText),
    onPressed: () {
      print('User pressed $okText button in questionMessage()');
      Navigator.of(context).pop(true);	// Dismiss the dialog box.
    },
  );
  Widget cancelButton = TextButton(
    child: Text(cancelText),
    onPressed: () {
      print('User pressed $cancelText button in questionMessage()');
      Navigator.of(context).pop(false);	// Dismiss the dialog box.
    },
  );
  // Set up the AlertDialog.
  AlertDialog alert = AlertDialog(
    title:   Text(heading),
    content: Text(question),
    actions: [
      cancelButton,
      okButton,
    ],
  );

  bool reply = await showDialog(
      context: context,
      barrierDismissible: false,	// User must tap button, not background.
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
    actions: [
      okButton,
    ],
  );
  // Show the info message.
  bool? reply = await showDialog(
    context: context,
    barrierDismissible: false,		// User must tap button, not background.
    builder: (BuildContext context) {
      return alert;
    },
  );
}
