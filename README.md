# signature

[![pub package](https://img.shields.io/pub/v/signature.svg)](https://pub.dartlang.org/packages/signature)

A Flutter plugin providing performance optimized signature canvas with ability
to set custom style, boundaries and initial state. This is native flutter
implementation, so it supports all platforms.

## Why

In time of creation of this plugin, there was no available solution that had:

- required performance on wide range of devices
- ability to set canvas boundaries
- ability to initialize using previously saved state

## Migration to 5.0.0+

- This version no longer wraps `Signature` in `Expanded` widget if you are using
  it without specifying dimensions
- This removes error `Incorrect use of ParentDataWidget`, see
  [this issue](https://github.com/4Q-s-r-o/signature/issues/49) for more
  information.
- If you are passing dimensions to widget, you do not have to change anything.
- If you are using widget without dimensions inside `Row`, `Column` or `Flex`
  widgets, you have to wrap `Signature` inside `Expanded` yourself.
- If you are using widget without dimensions, but not inside mentioned widgets
  you do not have change anything and error should dissapear from your logs :)

## Usage

To use this plugin, add `signature` as a
[dependency in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).

## Example

Take a look at our example project as well: [Signature Demo](https://github.com/4Q-s-r-o/signature/tree/master/example)

```dart
// IMPORT PACKAGE
import 'package:signature/signature.dart';

// Initialise a controller. It will contains signature points, stroke width and pen color.
// It will allow you to interact with the widget
final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.red,
    exportBackgroundColor: Colors.blue,
);

// INITIALIZE. RESULT IS A WIDGET, SO IT CAN BE DIRECTLY USED IN BUILD METHOD 
var _signatureCanvas = Signature(
  controller: _controller,
  width: 300,
  height: 300,
  backgroundColor: Colors.lightBlueAccent,
);

// CLEAR CANVAS
_controller.clear();

// EXPORT BYTES AS PNG
// The exported image will be limited to the drawn area
_controller.toPngBytes();

// isEmpty/isNotEmpty CAN BE USED TO CHECK IF SIGNATURE HAS BEEN PROVIDED
_controller.isNotEmpty; //true if signature has been provided
_controller.isEmpty; //true if signature has NOT been provided

// EXPORT POINTS (2D POINTS ROUGHLY REPRESENTING WHAT IS VISIBLE ON CANVAS)
var exportedPoints = _controller.points;

//EXPORTED POINTS CAN BE USED TO INITIALIZE PREVIOUS CONTROLLER
final SignatureController _controller = SignatureController(points: exportedPoints);

//DONT FORGET TO DISPOSE IT IN THE `dispose()` METHOD OF STATEFUL WIDGETS
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

![Example image](example.gif)

## Contribution and Support

- Contributions are welcome!
- If you want to contribute code please create a PR
- If you find a bug or want a feature, please fill an issue
