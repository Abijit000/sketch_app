import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../models/drawing_mode.dart';
import '../models/sketch.dart';
import 'color_palette.dart';

class CanvasSideBar extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<ui.Image?> backgroundImage;

  const CanvasSideBar({
    Key? key,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
      ),
    );
    final scrollController = useScrollController();
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height < 680 ? 450 : 610,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 3,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          controller: scrollController,
          children: [
            const SizedBox(height: 20),

            _IconBox(
              iconData: FontAwesomeIcons.pencil,
              selected: drawingMode.value == DrawingMode.pencil,
              onTap: () => drawingMode.value = DrawingMode.pencil,
              tooltip: 'Pencil',
            ),
            const SizedBox(height: 2),
            _IconBox(
              iconData: FontAwesomeIcons.eraser,
              selected: drawingMode.value == DrawingMode.eraser,
              onTap: () => drawingMode.value = DrawingMode.eraser,
              tooltip: 'Eraser',
            ),

            const SizedBox(height: 10),
            Column(
              children: [
                Text(
                  'Size: (${strokeSize.value.toInt()})',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(

                      hoverColor: Colors.grey.shade900,
                      onTap: () {
                        if (strokeSize.value > 1) {
                          strokeSize.value--;
                          eraserSize.value--;
                        }
                      },
                      child: Icon(
                        FontAwesomeIcons.minus,
                        color: Colors.grey.shade300,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      hoverColor: Colors.grey.shade900,
                      onTap: () {
                        if (strokeSize.value < 10) {
                          eraserSize.value++;
                        }
                      },
                      child: Icon(
                        FontAwesomeIcons.plus,
                        color: Colors.grey.shade300,
                        size: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Colors:',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,fontWeight: FontWeight.bold,color: Colors.white),
            ),
            const Divider(),
            ColorPalette(
              selectedColor: selectedColor,
            ),
            const Text(
              'Stroke type:',
              textAlign: TextAlign.center,
              style:
                  TextStyle(
                      fontSize: 12,fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Divider(),
            _IconBox(
              selected: drawingMode.value == DrawingMode.line,
              onTap: () => drawingMode.value = DrawingMode.line,
              tooltip: 'Line',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 2,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            _IconBox(
              iconData: FontAwesomeIcons.circle,
              selected: drawingMode.value == DrawingMode.circle,
              onTap: () => drawingMode.value = DrawingMode.circle,
              tooltip: 'Circle',
            ),
            const SizedBox(height: 2),

            _IconBox(
              iconData: FontAwesomeIcons.square,
              selected: drawingMode.value == DrawingMode.square,
              onTap: () => drawingMode.value = DrawingMode.square,
              tooltip: 'Square',
            ),
            const SizedBox(height: 2),
            _IconBox(
              iconData: CupertinoIcons.arrowtriangle_up,
              selected: drawingMode.value == DrawingMode.triangle,
              onTap: () => drawingMode.value = DrawingMode.triangle,
              tooltip: 'Triangle',
            ),
            const SizedBox(height: 2),
            _IconBox(
              iconData: Icons.hexagon_outlined,
              selected: drawingMode.value == DrawingMode.polygon,
              onTap: () => drawingMode.value = DrawingMode.polygon,
              tooltip: 'Polygon',
            ),
          ],
        ),
      ),
    );
  }

  void saveFile(Uint8List bytes, String extension) async {
    if (kIsWeb) {
      html.AnchorElement()
        ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
        ..download =
            'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$extension'
        ..style.display = 'none'
        ..click();
    } else {
      await FileSaver.instance.saveFile(
        name: 'FlutterLetsDraw-${DateTime.now().toIso8601String()}.$extension',
        bytes: bytes,
        ext: extension,
        mimeType: extension == 'png' ? MimeType.png : MimeType.jpeg,
      );
    }
  }

  Future<ui.Image> get _getImage async {
    final completer = Completer<ui.Image>();
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null
            ? file.files.first.bytes
            : File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('No image selected');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('No image selected');
      }
    }

    return completer.future;
  }

  Future<void> _launchUrl(String url) async {
    if (kIsWeb) {
      html.window.open(
        url,
        url,
      );
    } else {
      if (!await launchUrl(Uri.parse(url))) {
        throw 'Could not launch $url';
      }
    }
  }

  Future<Uint8List?> getBytes() async {
    RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: 35,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(
            color: selected ? const Color(0xff6e51c6) : Colors.black87,
            width: 2.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        child: Tooltip(
          message: tooltip,
          preferBelow: false,
          child: child ??
              Icon(
                iconData,
                color: Colors.grey.shade300,
                size: 20,
              ),
        ),
      ),
    );
  }
}

class _UndoRedoStack {
  _UndoRedoStack({
    required this.sketchesNotifier,
    required this.currentSketchNotifier,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  late final List<Sketch> _redoStack = [];

  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}
