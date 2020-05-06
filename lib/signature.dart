import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Signature canvas. Controller is required, other parameters are optional. It expands by default.
/// This behaviour can be overridden using width and/or height parameters.
class Signature extends StatefulWidget {
  Signature({
    Key key,
    @required this.controller,
    this.backgroundColor = Colors.grey,
    this.width,
    this.height,
  })  : assert(controller != null),
        super(key: key);

  final SignatureController controller;
  final double width;
  final double height;
  final Color backgroundColor;

  @override
  State createState() => SignatureState();
}

class SignatureState extends State<Signature> {
  /// Helper variable indicating that user has left the canvas so we can prevent linking next point
  /// with straight line.
  bool _isOutsideDrawField = false;

  @override
  Widget build(BuildContext context) {
    var maxWidth = widget.width ?? double.infinity;
    var maxHeight = widget.height ?? double.infinity;
    var signatureCanvas = GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //NO-OP
      },
      child: Container(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Listener(
          onPointerDown: (event) => _addPoint(event, PointType.tap),
          onPointerUp: (event) => _addPoint(event, PointType.tap),
          onPointerMove: (event) => _addPoint(event, PointType.move),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _SignaturePainter(widget.controller),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: maxWidth,
                    minHeight: maxHeight,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.width != null || widget.height != null) {
      //IF DOUNDARIES ARE DEFINED, USE LIMITED BOX
      return Center(
          child: LimitedBox(maxWidth: maxWidth, maxHeight: maxHeight, child: signatureCanvas));
    } else {
      //IF NO BOUNDARIES ARE DEFINED, USE EXPANDED
      return Expanded(child: signatureCanvas);
    }
  }

  void _addPoint(PointerEvent event, PointType type) {
    Offset o = event.localPosition;
    //SAVE POINT ONLY IF IT IS IN THE SPECIFIED BOUNDARIES
    if ((widget.width == null || o.dx > 0 && o.dx < widget.width) &&
        (widget.height == null || o.dy > 0 && o.dy < widget.height)) {
      // IF USER LEFT THE BOUNDARY AND AND ALSO RETURNED BACK
      // IN ONE MOVE, RETYPE IT AS TAP, AS WE DO NOT WANT TO
      // LINK IT WITH PREVIOUS POINT
      if (_isOutsideDrawField) {
        type = PointType.tap;
      }
      setState(() {
        //IF USER WAS OUTSIDE OF CANVAS WE WILL RESET THE HELPER VARIABLE AS HE HAS RETURNED
        _isOutsideDrawField = false;
        widget.controller.addPoint(Point(o, type));
      });
    } else {
      //NOTE: USER LEFT THE CANVAS!!! WE WILL SET HELPER VARIABLE
      //WE ARE NOT UPDATING IN setState METHOD BECAUSE WE DO NOT NEED TO RUN BUILD METHOD
      _isOutsideDrawField = true;
    }
  }
}

enum PointType { tap, move }

class Point {
  Offset offset;
  PointType type;

  Point(this.offset, this.type);
}

class _SignaturePainter extends CustomPainter {
  SignatureController _controller;
  Paint _penStyle;

  _SignaturePainter(this._controller) : super(repaint: _controller) {
    this._penStyle = Paint()
      ..color = _controller.penColor
      ..strokeWidth = _controller.penStrokeWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var points = _controller.value;
    if (points == null || points.isEmpty) return;
    for (int i = 0; i < (points.length - 1); i++) {
      if (points[i + 1].type == PointType.move) {
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          _penStyle,
        );
      } else {
        canvas.drawCircle(
          points[i].offset,
          2.0,
          _penStyle,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter other) => true;
}

class SignatureController extends ValueNotifier<List<Point>> {
  final Color penColor;
  final double penStrokeWidth;
  final Color exportBackgroundColor;

  SignatureController(
      {List<Point> points,
      this.penColor = Colors.black,
      this.penStrokeWidth = 3.0,
      this.exportBackgroundColor})
      : super(points ?? List<Point>());

  List<Point> get points => value;

  set points(List<Point> value) {
    value = value.toList();
  }

  addPoint(Point point) {
    value.add(point);
    this.notifyListeners();
  }

  bool get isEmpty {
    return value.length == 0;
  }

  bool get isNotEmpty {
    return value.length > 0;
  }

  clear() {
    value = List<Point>();
  }

  Future<ui.Image> toImage() async {
    if (isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;
    points.forEach((point) {
      if (point.offset.dx < minX) minX = point.offset.dx;
      if (point.offset.dy < minY) minY = point.offset.dy;
      if (point.offset.dx > maxX) maxX = point.offset.dx;
      if (point.offset.dy > maxY) maxY = point.offset.dy;
    });

    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.translate(-(minX - penStrokeWidth), -(minY - penStrokeWidth));
    if (exportBackgroundColor != null) {
      var paint = Paint();
      paint.color = exportBackgroundColor;
      canvas.drawPaint(paint);
    }
    _SignaturePainter(this).paint(canvas, null);
    var picture = recorder.endRecording();
    return picture.toImage(
        (maxX - minX + penStrokeWidth * 2).toInt(), (maxY - minY + penStrokeWidth * 2).toInt());
  }

  Future<Uint8List> toPngBytes() async {
    var image = await toImage();
    var bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes.buffer.asUint8List();
  }
}
