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
