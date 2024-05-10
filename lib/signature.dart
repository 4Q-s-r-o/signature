import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
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
    _updateWidgetSize();
  }

  @override
  Widget build(BuildContext context) {
    final GestureDetector signatureCanvas = GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //NO-OP
      },
      child: LayoutBuilder(
        builder: (BuildContext buildContext, BoxConstraints boxConstraints) {
          // WE NEED TO UPDATE SIGNATURE PAD CONSTRINATS USING LAYOUT BUILDER
          // MEDIA QUERY DOES NOT WORK BECAUSE IT RETURNS SCREEN SIZE, NOT
          // PARENT WIDGET SIZE
          screenSize = boxConstraints.biggest;
          return Container(
            decoration: BoxDecoration(color: widget.backgroundColor),
            child: Listener(
                onPointerDown: (PointerDownEvent event) {
                  if (!widget.controller.disabled &&
                      (activePointerId == null ||
                          activePointerId == event.pointer)) {
                    activePointerId = event.pointer;
                    widget.controller.onDrawStart?.call();
                    _addPoint(event, PointType.tap);
                  }
                },
                onPointerUp: (PointerUpEvent event) {
                  _ensurePointerCleanup();
                  if (activePointerId == event.pointer) {
                    _addPoint(event, PointType.tap);
                    widget.controller.pushCurrentStateToUndoStack();
                    widget.controller.onDrawEnd?.call();
                    activePointerId = null;
                  }
                },
                onPointerCancel: (PointerCancelEvent event) {
                  _ensurePointerCleanup();
                  if (activePointerId == event.pointer) {
                    _addPoint(event, PointType.tap);
                    widget.controller.pushCurrentStateToUndoStack();
                    widget.controller.onDrawEnd?.call();
                    activePointerId = null;
                  }
                },
                onPointerMove: (PointerMoveEvent event) {
                  _ensurePointerCleanup();
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
          );
        },
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
  void didUpdateWidget(covariant Signature oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateWidgetSize();
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

  void _updateWidgetSize() {
    maxWidth = widget.width ?? double.infinity;
    maxHeight = widget.height ?? double.infinity;
  }

  /// METHOD THAT WILL CLEANUP ANY REMNANT POINTER AFTER DISABLING
  /// WIDGET
  void _ensurePointerCleanup() {
    if (widget.controller.disabled && activePointerId != null) {
      // WIDGET HAS BEEN DISABLED DURING DRAWING.
      // CANCEL CURRENT DRAW
      activePointerId = null;
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
      ..strokeWidth = _controller.penStrokeWidth
      ..strokeCap = _controller.strokeCap
      ..strokeJoin = _controller.strokeJoin;
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
    this.disabled = false,
    this.penColor = Colors.black,
    this.strokeCap = StrokeCap.butt,
    this.strokeJoin = StrokeJoin.miter,
    this.penStrokeWidth = 3.0,
    this.exportBackgroundColor,
    this.exportPenColor,
    this.onDrawStart,
    this.onDrawMove,
    this.onDrawEnd,
  }) : super(points ?? <Point>[]);

  /// If set to true canvas writting will be disabled.
  bool disabled;

  /// color of a signature line
  final Color penColor;

  /// boldness of a signature line
  final double penStrokeWidth;

  /// shape of line ends
  final StrokeCap strokeCap;

  /// shape of line joins
  final StrokeJoin strokeJoin;

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
  bool get isEmpty => value.isEmpty;

  /// check if canvas is not empty (opposite of isEmpty method for convenience)
  bool get isNotEmpty => value.isNotEmpty;

  /// The biggest x value for all points.
  /// Will return `null` if there are no points.
  double? get maxXValue =>
      isEmpty ? null : points.map((Point p) => p.offset.dx).reduce(max);

  /// The biggest y value for all points.
  /// Will return `null` if there are no points.
  double? get maxYValue =>
      isEmpty ? null : points.map((Point p) => p.offset.dy).reduce(max);

  /// The smallest x value for all points.
  /// Will return `null` if there are no points.
  double? get minXValue =>
      isEmpty ? null : points.map((Point p) => p.offset.dx).reduce(min);

  /// The smallest y value for all points.
  /// Will return `null` if there are no points.
  double? get minYValue =>
      isEmpty ? null : points.map((Point p) => p.offset.dy).reduce(min);

  /// Calculates a default height based on existing points.
  /// Will return `null` if there are no points.
  int? get defaultHeight =>
      isEmpty ? null : (maxYValue! - minYValue! + penStrokeWidth * 2).toInt();

  /// Calculates a default width based on existing points.
  /// Will return `null` if there are no points.
  int? get defaultWidth =>
      isEmpty ? null : (maxXValue! - minXValue! + penStrokeWidth * 2).toInt();

  /// Calculates a default width based on existing points.
  /// Will return `null` if there are no points.
  List<Point>? _translatePoints(List<Point> points) => isEmpty
      ? null
      : points
          .map((Point p) => Point(
              Offset(
                p.offset.dx - minXValue! + penStrokeWidth,
                p.offset.dy - minYValue! + penStrokeWidth,
              ),
              p.type,
              p.pressure))
          .toList();

  /// Clear the canvas
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

  /// Convert to an [ui.Image].
  /// Will return `null` if there are no points.
  Future<ui.Image?> toImage({int? width, int? height}) async {
    if (isEmpty) {
      return null;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder)
      ..translate(
          -(minXValue! - penStrokeWidth), -(minYValue! - penStrokeWidth));
    if (exportBackgroundColor != null) {
      final ui.Paint paint = Paint()..color = exportBackgroundColor!;
      canvas.drawPaint(paint);
    }
    if (width != null || height != null) {
      assert(
        ((width ?? defaultWidth!) - defaultWidth!) >= 0.0,
        'Exported width cannot be smaller than actual width',
      );
      assert(
        ((height ?? defaultHeight!) - defaultHeight!) >= 0.0,
        'Exported height cannot be smaller than actual height',
      );
      //IF WIDTH OR HEIGHT IS SPECIFIED WE NEED TO CENTER DRAWING
      //WE WILL MOVE THE DRAWING BY HALF OF THE REMAINING SPACE IF
      //IF DIMENSION IS NOT SPECIFIED WE WILL DEFAULT TO ACTUAL
      //SIZE OF THE DRAWING HENCE THE DIFFERENCE WILL BE ZERO
      //AND DRAWING WILL NOT MOVE IN THAT DIRECTION
      canvas.translate(
        ((width ?? defaultWidth!) - defaultWidth!).toDouble() / 2,
        ((height ?? defaultHeight!) - defaultHeight!).toDouble() / 2,
      );
    }
    _SignaturePainter(this, penColor: exportPenColor).paint(
      canvas,
      Size.infinite,
    );
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(width ?? defaultWidth!, height ?? defaultHeight!);
  }

  /// convert canvas to dart:ui [ui.Image] and then to PNG represented in [Uint8List]
  /// height and width should be at least as big as the drawings size
  /// Will return `null` if there are no points.
  Future<Uint8List?> toPngBytes({int? height, int? width}) async {
    if (kIsWeb) {
      return _toPngBytesForWeb(height: height, width: width);
    }
    final ui.Image? image = await toImage(height: height, width: width);

    if (image == null) {
      return null;
    }

    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return bytes?.buffer.asUint8List();
  }

  /// 'image.toByteData' is not available for web. So we are using the package
  /// 'image' to create an image which works on web too.
  /// Will return `null` if there are no points.
  Uint8List? _toPngBytesForWeb({int? height, int? width}) {
    if (isEmpty) {
      return null;
    }

    if (width != null || height != null) {
      assert(
        ((width ?? defaultWidth!) - defaultWidth!) >= 0.0,
        'Exported width cannot be smaller than actual width',
      );
      assert(
        ((height ?? defaultHeight!) - defaultHeight!) >= 0.0,
        'Exported height cannot be smaller than actual height',
      );
    }

    final img.Color pColor = img.ColorRgb8(
      exportPenColor?.red ?? penColor.red,
      exportPenColor?.green ?? penColor.green,
      exportPenColor?.blue ?? penColor.blue,
    );

    final Color backgroundColor = exportBackgroundColor ?? Colors.transparent;
    final img.Color bColor = img.ColorRgba8(
      backgroundColor.red,
      backgroundColor.green,
      backgroundColor.blue,
      backgroundColor.alpha.toInt(),
    );

    final List<Point> translatedPoints = _translatePoints(points)!;

    final int canvasWidth = width ?? defaultWidth!;
    final int canvasHeight = height ?? defaultHeight!;

    // create the image with the given size
    final img.Image signatureImage =
        img.Image(width: canvasWidth, height: canvasHeight, numChannels: 4);
    // set the image background color
    img.fill(signatureImage, color: bColor);

    final double xOffset =
        ((width ?? defaultWidth!) - defaultWidth!).toDouble() / 2;
    final double yOffset =
        ((height ?? defaultHeight!) - defaultHeight!).toDouble() / 2;

    // read the drawing points list and draw the image
    // it uses the same logic as the CustomPainter Paint function
    for (int i = 0; i < translatedPoints.length - 1; i++) {
      if (translatedPoints[i + 1].type == PointType.move) {
        img.drawLine(signatureImage,
            x1: (translatedPoints[i].offset.dx + xOffset).toInt(),
            y1: (translatedPoints[i].offset.dy + yOffset).toInt(),
            x2: (translatedPoints[i + 1].offset.dx + xOffset).toInt(),
            y2: (translatedPoints[i + 1].offset.dy + yOffset).toInt(),
            color: pColor,
            thickness: penStrokeWidth);
      } else {
        // draw the point to the image
        img.fillCircle(
          signatureImage,
          x: (translatedPoints[i].offset.dx + xOffset).toInt(),
          y: (translatedPoints[i].offset.dy + yOffset).toInt(),
          radius: penStrokeWidth.toInt(),
          color: pColor,
        );
      }
    }
    // encode the image to PNG
    return Uint8List.fromList(img.encodePng(signatureImage));
  }

  /// Export the current content to a raw SVG string.
  /// Will return `null` if there are no points.
  String? toRawSVG({int? width, int? height}) {
    if (isEmpty) {
      return null;
    }

    String formatPoint(Point p) =>
        '${p.offset.dx.toStringAsFixed(2)},${p.offset.dy.toStringAsFixed(2)}';

    final List<String> latestActionList = List<List<Point>>.from(_latestActions)
        .map((List<Point> value) {
          return _translatePoints(value)!.map(formatPoint).join(' ');
        })
        .toList()
        .reversed
        .toList();
    final List<String> strokes = latestActionList
        .asMap()
        .map((int index, String value) {
          String stroke = value;
          if (index + 1 < latestActionList.length) {
            stroke = stroke.replaceAll('${latestActionList[index + 1]} ', '');
          }
          return MapEntry<int, String>(
              index,
              '<polyline '
              'fill="none" '
              'stroke="${_colorToHex(exportPenColor ?? penColor)}" '
              'stroke-opacity="${_colorToOpacity(exportPenColor ?? penColor)}" '
              'points="$stroke" '
              'stroke-linecap="round" '
              'stroke-width="$penStrokeWidth" '
              '/>');
        })
        .values
        .toList();
    final String polylines = strokes.join('\n');

    width ??= defaultWidth;
    height ??= defaultHeight;

    return '<svg '
        'viewBox="0 0 $width $height" '
        'xmlns="http://www.w3.org/2000/svg"'
        '>\n$polylines\n</svg>';
  }

  /// Converts color to its hex representation without alpha
  String _colorToHex(Color c) => '#${c.red.toRadixString(16).padLeft(2, '0')}'
      '${c.green.toRadixString(16).padLeft(2, '0')}'
      '${c.blue.toRadixString(16).padLeft(2, '0')}';

  /// Extracts alpha from color
  double _colorToOpacity(Color c) => c.opacity;

  /// Export the current content to a SVG graphic.
  /// Will return `null` if there are no points.
  svg.SvgPicture? toSVG({int? width, int? height}) => isEmpty
      ? null
      : svg.SvgPicture.string(toRawSVG(width: width, height: height)!);
}
