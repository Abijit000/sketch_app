import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:file_saver/file_saver.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sketch_app/widgets/canvas_side_bar.dart';
import 'package:sketch_app/widgets/drawing_canvas.dart';

import '../models/drawing_mode.dart';
import '../models/sketch.dart';

class SketchPage extends HookWidget {
  const SketchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(10);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);
    final polygonSides = useState<int>(3);
    final backgroundImage = useState<Image?>(null);

    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);

    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
      ),
    );

    Future<void> saveImage(Uint8List imageBytes,String fileType) async {
      try {
        // Get the document directory on the device
        final directory = await getDownloadsDirectory();

        // Generate a unique file name (e.g., timestamp +.png)
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileType';

        final file = File("${directory?.path}/$fileName");

        // Write the image data to the file
        await file.writeAsBytes(imageBytes);

        // Show a confirmation message or perform other perform other actions as needed
        print('Image saved to: ${file.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image Saved : ${file.path}'),
          ),
        );
      } catch (error) {
        print('Error saving image: $error');
      }
    }
    Future<Uint8List?> getBytes() async {
      RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();
      return pngBytes;
    }

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 1,
    );
    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            Container(
              color: Colors.black87,
              width: MediaQuery.of(context).size.width * 0.09,
              height: double.maxFinite,
              child: CanvasSideBar(
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                polygonSides: polygonSides,
                backgroundImage: backgroundImage,
              ),
            ),
            Container(
              color: Colors.grey.shade300,
              width: MediaQuery.of(context).size.width * 0.9,
              height: double.maxFinite,
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(FontAwesomeIcons.arrowRotateLeft,
                              size: 15, color: Colors.grey.shade300),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                          ),
                          onPressed: allSketches.value.isNotEmpty
                              ? () => undoRedoStack.value.undo()
                              : null,
                          label: Text('Undo',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                              )),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: undoRedoStack.value._canRedo,
                          builder: (_, canRedo, __) {
                            return ElevatedButton.icon(
                              icon: Icon(FontAwesomeIcons.arrowRotateRight,
                                  size: 15, color: Colors.grey.shade300),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                              ),
                              onPressed: canRedo
                                  ? () => undoRedoStack.value.redo()
                                  : null,
                              label: Text('Redo',
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                  )),
                            );
                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete,
                              size: 15, color: Colors.grey.shade300),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                          ),
                          label: Text('Clear',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                              )),
                          onPressed: () => undoRedoStack.value.clear(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: ElevatedButton.icon(
                            icon: Icon(FontAwesomeIcons.download,
                                size: 15, color: Colors.grey.shade300),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                            ),
                            label: Text('Export PNG',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                )),
                            onPressed: () async {
                              // getImage();
                              Uint8List? pngBytes = await getBytes();
                              if (pngBytes != null) saveImage(pngBytes,"png");
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 140,
                          child: ElevatedButton.icon(
                            icon: Icon(FontAwesomeIcons.download,
                                size: 15, color: Colors.grey.shade300),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                            ),
                            label: Text('Export JPEG',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                )),
                            onPressed: () async {
                              Uint8List? pngBytes = await getBytes();
                              if (pngBytes != null) saveImage(pngBytes,"jpeg");
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                DrawingCanvas(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.75,
                  drawingMode: drawingMode,
                  selectedColor: selectedColor,
                  strokeSize: strokeSize,
                  eraserSize: eraserSize,
                  sideBarController: animationController,
                  currentSketch: currentSketch,
                  allSketches: allSketches,
                  canvasGlobalKey: canvasGlobalKey,
                  filled: filled,
                  polygonSides: polygonSides,
                  backgroundImage: backgroundImage,
                ),
              ]),
            ),
          ],
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
