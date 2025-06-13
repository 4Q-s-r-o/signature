import 'package:flutter/material.dart';

/// Pushes a widget to a new route.
Future push(context, widget) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (BuildContext context) {
        return widget;
      },
    ),
  );
}

/// Prints long string to logs
void printLongString(String? text) {
  if (text != null) {
    final pattern = RegExp('.{1,800}');
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }
}
