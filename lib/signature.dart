import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// signature canvas. Controller is required, other parameters are optional.
/// widget/canvas expands to maximum by default.
/// this behaviour can be overridden using width and/or height parameters.
class Signature extends StatefulWidget {
  /// constructor
  const Signature({
    required this.controller,
    Key? key,
    this.backgroundColor = Colors.grey,
    this.dynamicPressureSupported = false,
    this.width,
    this.height,
  }) : super(key: key);

  /// signature widget controller
  final SignatureController controller;

  /// signature widget width
  final double? width;

  /// signature widget height
  final double? height;

  /// signature widget background color
  final Color backgroundColor;

  /// support dynamic pressure for width (if has support for it)
  final bool dynamicPressureSupported;

  @override
  State createState() => SignatureState();
}

/// signature widget state
class SignatureState extends State<Signature> {
  /// Helper variable indicating that user has left the canvas so we can prevent linking next point
  /// with straight line.
  bool _isOutsideDrawField = false;

  /// Active pointer to prevent multitouch drawing
  int? activePointerId;

  /// Real widget size
  Size? screenSize;

  /// Max width of canvas
  late double maxWidth;

  /// Max height of canvas
  late double maxHeight;

  @override
  void initState() {
    super.initState();

    maxWidth = widget.width ?? double.infinity;
    maxHeight = widget.height ?? double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final GestureDetector signatureCanvas = GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //NO-OP
      },
      child: Container(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Listener(
            onPointerDown: (PointerDownEvent event) {
              if (activePointerId == null || activePointerId == event.pointer) {
                activePointerId = event.pointer;
                widget.controller.onDrawStart?.call();
                _addPoint(event, PointType.tap);
              }
            },
            onPointerUp: (PointerUpEvent event) {
              if (activePointerId == event.pointer) {
                _addPoint(event, PointType.tap);
                widget.controller.pushCurrentStateToUndoStack();
                widget.controller.onDrawEnd?.call();
                activePointerId = null;
              }
            },
            onPointerCancel: (PointerCancelEvent event) {
              if (activePointerId == event.pointer) {
                _addPoint(event, PointType.tap);
                widget.controller.pushCurrentStateToUndoStack();
                widget.controller.onDrawEnd?.call();
                activePointerId = null;
              }
            },
            onPointerMove: (PointerMoveEvent event) {
              if (activePointerId == event.pointer) {
                _addPoint(event, PointType.move);
                widget.controller.onDrawMove?.call();
              }
            },
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
            )),
      ),
    );

    if (widget.width != null || widget.height != null) {
      //IF DOUNDARIES ARE DEFINED, USE LIMITED BOX
      return Center(
        child: LimitedBox(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          child: signatureCanvas,
        ),
      );
    } else {
      //IF NO BOUNDARIES ARE DEFINED, RETURN THE WIDGET AS IS
      return signatureCanvas;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
  }

  void _addPoint(PointerEvent event, PointType type) {
    final Offset o = event.localPosition;

    // IF WIDGET IS USED WITHOUT DIMENSIONS, WE WILL FALLBACK TO SCREENSIZE
    // DIMENSIONS
    final double _maxSafeWidth =
        maxWidth == double.infinity ? screenSize!.width : maxWidth;
    final double _maxSafeHeight =
        maxHeight == double.infinity ? screenSize!.height : maxHeight;

    //SAVE POINT ONLY IF IT IS IN THE SPECIFIED BOUNDARIES
    if ((screenSize?.width == null || o.dx > 0 && o.dx < _maxSafeWidth) &&
        (screenSize?.height == null || o.dy > 0 && o.dy < _maxSafeHeight)) {
      // IF USER LEFT THE BOUNDARY AND ALSO RETURNED BACK
      // IN ONE MOVE, RETYPE IT AS TAP, AS WE DO NOT WANT TO
      // LINK IT WITH PREVIOUS POINT
      PointType t = type;
      if (_isOutsideDrawField) {
        t = PointType.tap;
      }
      setState(() {
        //IF USER WAS OUTSIDE OF CANVAS WE WILL RESET THE HELPER VARIABLE AS HE HAS RETURNED
        _isOutsideDrawField = false;
        widget.controller.addPoint(Point(
          o,
          t,
          widget.dynamicPressureSupported ? event.pressure : 1.0,
        ));
      });
    } else {
      //NOTE: USER LEFT THE CANVAS!!! WE WILL SET HELPER VARIABLE
      //WE ARE NOT UPDATING IN setState METHOD BECAUSE WE DO NOT NEED TO RUN BUILD METHOD
      _isOutsideDrawField = true;
    }
  }
}

/// type of user display finger movement
enum PointType {
  /// one touch on specific place - tap
  tap,

  /// finger touching the display and moving around
  move,
}

/// one point on canvas represented by offset and type
class Point {
  /// constructor
  Point(this.offset, this.type, this.pressure);

  /// x and y value on 2D canvas
  Offset offset;

  /// pressure that user applied
  double pressure;

  /// type of user display finger movement
  PointType type;
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this._controller, {Color? penColor})
      : _penStyle = Paint(),
        super(repaint: _controller) {
    _penStyle
      ..color = penColor != null ? penColor : _controller.penColor
      ..strokeWidth = _controller.penStrokeWidth;
  }

  final SignatureController _controller;
  final Paint _penStyle;

  @override
  void paint(Canvas canvas, _) {
    final List<Point> points = _controller.value;
    if (points.isEmpty) {
      return;
    }
    for (int i = 0; i < (points.length - 1); i++) {
      if (points[i + 1].type == PointType.move) {
        _penStyle.strokeWidth *= points[i].pressure;
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          _penStyle,
        );
      } else {
        canvas.drawCircle(
          points[i].offset,
          (_penStyle.strokeWidth / 2) * points[i].pressure,
          _penStyle,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter other) => true;
}

/// class for interaction with signature widget
/// manages points representing signature on canvas
/// provides signature manipulation functions (export, clear)
class SignatureController extends ValueNotifier<List<Point>> {
  /// constructor
  SignatureController({
    List<Point>? points,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.exportBackgroundColor,
    this.exportPenColor,
    this.onDrawStart,
    this.onDrawMove,
    this.onDrawEnd,
  }) : super(points ?? <Point>[]);

  /// color of a signature line
  final Color penColor;

  /// boldness of a signature line
  final double penStrokeWidth;

  /// background color to be used in exported png image
  final Color? exportBackgroundColor;

  /// color of a ginature line to be used in exported png image
  final Color? exportPenColor;

  /// callback to notify when drawing has started
  VoidCallback? onDrawStart;

  /// callback to notify when the pointer was moved while drawing.
  VoidCallback? onDrawMove;

  /// callback to notify when drawing has stopped
  VoidCallback? onDrawEnd;

  /// getter for points representing signature on 2D canvas
  List<Point> get points => value;

  /// stack-like list of point to save user's latest action
  final List<List<Point>> _latestActions = <List<Point>>[];

  /// stack-like list that use to save points when user undo the signature
  final List<List<Point>> _revertedActions = <List<Point>>[];

  /// setter for points representing signature on 2D canvas
  set points(List<Point> points) {
    value = points;
  }

  /// add point to point collection
  void addPoint(Point point) {
    value.add(point);
    notifyListeners();
  }

  /// REMEMBERS CURRENT CANVAS STATE IN UNDO STACK
  void pushCurrentStateToUndoStack() {
    _latestActions.add(<Point>[...points]);
    //CLEAR ANY UNDO-ED ACTIONS. IF USER UNDO-ED ANYTHING HE ALREADY MADE
    // ANOTHER CHANGE AND LEFT THAT OLD PATH.
    _revertedActions.clear();
  }

  /// check if canvas is empty (opposite of isNotEmpty method for convenience)
  bool get isEmpty {
    return value.isEmpty;
  }

  /// check if canvas is not empty (opposite of isEmpty method for convenience)
  bool get isNotEmpty {
    return value.isNotEmpty;
  }

  /// clear the canvas
  void clear() {
    value = <Point>[];
    _latestActions.clear();
    _revertedActions.clear();
  }

  /// It will remove last action from [_latestActions].
  /// The last action will be saved to [_revertedActions]
  /// that will be used to do redo-ing.
  /// Then, it will modify the real points with the last action.
  void undo() {
    if (_latestActions.isNotEmpty) {
      final List<Point> lastAction = _latestActions.removeLast();
      _revertedActions.add(<Point>[...lastAction]);
      if (_latestActions.isNotEmpty) {
        points = <Point>[..._latestActions.last];
        return;
      }
      points = <Point>[];
      notifyListeners();
    }
  }

  /// It will remove last reverted actions and add it into [_latestActions]
  /// Then, it will modify the real points with the last reverted action.
  void redo() {
    if (_revertedActions.isNotEmpty) {
      final List<Point> lastRevertedAction = _revertedActions.removeLast();
      _latestActions.add(<Point>[...lastRevertedAction]);
      points = <Point>[...lastRevertedAction];
      notifyListeners();
      return;
    }
  }

  /// convert to
  Future<ui.Image?> toImage({int width = 0, int height = 0}) async {
    if (isEmpty) {
      return null;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;
    for (Point point in points) {
      if (point.offset.dx < minX) {
        minX = point.offset.dx;
      }
      if (point.offset.dy < minY) {
        minY = point.offset.dy;
      }
      if (point.offset.dx > maxX) {
        maxX = point.offset.dx;
      }
      if (point.offset.dy > maxY) {
        maxY = point.offset.dy;
      }
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder)
      ..translate(-(minX - penStrokeWidth), -(minY - penStrokeWidth));
    if (exportBackgroundColor != null) {
      final ui.Paint paint = Paint()..color = exportBackgroundColor!;
      canvas.drawPaint(paint);
    }
    _SignaturePainter(this, penColor: exportPenColor).paint(
      canvas,
      Size.infinite,
    );
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(
        width == 0 ? (maxX - minX + penStrokeWidth * 2).toInt() : width,
        height == 0 ? (maxY - minY + penStrokeWidth * 2).toInt() : height);
  }

  /// convert canvas to dart:ui Image and then to PNG represented in Uint8List
  Future<Uint8List?> toPngBytes() async {
    if (!kIsWeb) {
      final ui.Image? image = await toImage();
      if (image == null) {
        return null;
      }
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return bytes?.buffer.asUint8List();
    } else {
      return _toPngBytesForWeb();
    }
  }

  // 'image.toByteData' is not available for web. So we are using the package
  // 'image' to create an image which works on web too
  Uint8List? _toPngBytesForWeb() {
    if (isEmpty) {
      return null;
    }
    final int pColor = img.getColor(
      exportPenColor != null ? exportPenColor!.red : penColor.red,
      exportPenColor != null ? exportPenColor!.green : penColor.green,
      exportPenColor != null ? exportPenColor!.blue : penColor.blue,
    );

    final Color backgroundColor = exportBackgroundColor ?? Colors.transparent;
    final int bColor = img.getColor(backgroundColor.red, backgroundColor.green,
        backgroundColor.blue, backgroundColor.alpha.toInt());

    double minX = double.infinity;
    double maxX = 0;
    double minY = double.infinity;
    double maxY = 0;

    for (Point point in points) {
      minX = min(point.offset.dx, minX);
      maxX = max(point.offset.dx, maxX);
      minY = min(point.offset.dy, minY);
      maxY = max(point.offset.dy, maxY);
    }

    //point translation
    final List<Point> translatedPoints = <Point>[];
    for (Point point in points) {
      translatedPoints.add(Point(
          Offset(
            point.offset.dx - minX + penStrokeWidth,
            point.offset.dy - minY + penStrokeWidth,
          ),
          point.type,
          point.pressure));
    }

    final int width = (maxX - minX + penStrokeWidth * 2).toInt();
    final int height = (maxY - minY + penStrokeWidth * 2).toInt();

    // create the image with the given size
    final img.Image signatureImage = img.Image(width, height);
    // set the image background color
    img.fill(signatureImage, bColor);

    // read the drawing points list and draw the image
    // it uses the same logic as the CustomPainter Paint function
    for (int i = 0; i < translatedPoints.length - 1; i++) {
      if (translatedPoints[i + 1].type == PointType.move) {
        img.drawLine(
            signatureImage,
            translatedPoints[i].offset.dx.toInt(),
            translatedPoints[i].offset.dy.toInt(),
            translatedPoints[i + 1].offset.dx.toInt(),
            translatedPoints[i + 1].offset.dy.toInt(),
            pColor,
            thickness: penStrokeWidth);
      } else {
        // draw the point to the image
        img.fillCircle(
          signatureImage,
          translatedPoints[i].offset.dx.toInt(),
          translatedPoints[i].offset.dy.toInt(),
          penStrokeWidth.toInt(),
          pColor,
        );
      }
    }
    // encode the image to PNG
    return Uint8List.fromList(img.encodePng(signatureImage));
  }
}
