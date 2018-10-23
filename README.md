# signature

[![pub package](https://img.shields.io/pub/v/signature.svg)](https://pub.dartlang.org/packages/signature)

A Flutter plugin providing performance optimized signature canvas with ability to set custom style, boundaries and initial state.
This is native flutter implementation, so it supports all platforms.

## Why
In time of creation of this plugin, there was no available solution that had:
* required performance on wide range of devices
* ability to set canvas boundaries
* ability to initialize using previously saved state

## Usage

To use this plugin, add `signature` as a [dependency in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).

## Example

``` dart
// IMPORT PACKAGE
import 'package:signature/signature.dart';

// INITIALIZE. RESULT IS A WIDGET, SO IT CAN BE DIRECTLY USED IN BUILD METHOD 
var _signatureCanvas = Signature(
  width: 300,
  height: 300,
  backgroundColor: Colors.lightBlueAccent,
);

// CLEAR CANVAS
_signatureCanvas.clear();

// EXPORT BYTES (EXPORTING FORMAT IS PNG)
_signatureCanvas.exportBytes();

// EXPORT POINTS (2D POINTS ROUGHLY REPRESENTING WHAT IS VISIBLE ON CANVAS)
var exportedPoints = _signatureCanvas.exportPoints();

//EXPORTED POINTS CAN BE USED TO INITIALIZE PREVIOUS STATE VIA CONSTRUCTOR
var _signatureCanvas = Signature(
  points: exportedPoints,
  width: 300,
  height: 300,
  backgroundColor: Colors.lightBlueAccent,
);

```

## Contribution and Support

* Contributions are welcome!
* If you want to contribute code please create a PR
* If you find a bug or want a feature, please fill an issue