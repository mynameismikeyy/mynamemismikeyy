import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ClassificationPage extends StatefulWidget {
  final String targetClass;
  const ClassificationPage({super.key, required this.targetClass});

  @override
  State<ClassificationPage> createState() => _ClassificationPageState();
}

class _ClassificationPageState extends State<ClassificationPage> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  List<String> _labels = [];

  bool _isModelLoaded = false;
  bool _isProcessing = false;

  String _result = 'No result yet';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  // ---------------- CAMERA ----------------
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  // ---------------- LOAD MODEL ----------------
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('models/model_unquant.tflite');

      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );

      _labels = labelsData
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint('Model load error: $e');
    }
  }

  // ---------------- PROCESS CAMERA FRAME ----------------
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isModelLoaded || _isProcessing) return;
    _isProcessing = true;

    try {
      // Convert YUV → RGB Image
      final img.Image rgbImage = _convertYUV420ToImage(image);

      // Resize to 224x224
      final img.Image resized = img.copyResize(
        rgbImage,
        width: 224,
        height: 224,
      );

      // Prepare input tensor
      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(224, (_) => List.filled(3, 0.0)),
        ),
      );

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);

          input[0][y][x][0] = (pixel.r - 127.5) / 127.5;
          input[0][y][x][1] = (pixel.g - 127.5) / 127.5;
          input[0][y][x][2] = (pixel.b - 127.5) / 127.5;
        }
      }

      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);

      int maxIndex = 0;
      double maxValue = output[0][0];

      for (int i = 1; i < _labels.length; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          maxIndex = i;
        }
      }

      setState(() {
        _result = _labels[maxIndex];
        _confidence = maxValue;
      });

      if (_confidence > 0.70) {
        _logToFirestore(_result, _confidence);
      }
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // ---------------- YUV → IMAGE ----------------
  img.Image _convertYUV420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    int uvIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yValue = yPlane[y * width + x];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        final r = (yValue + 1.403 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.770 * (uValue - 128)).clamp(0, 255).toInt();

        imgBuffer.setPixelRgb(x, y, r, g, b);

        if (x % 2 == 1) uvIndex++;
      }
      if (y % 2 == 0) uvIndex -= width ~/ 2;
    }

    return imgBuffer;
  }

  // ---------------- FIRESTORE ----------------
  Future<void> _logToFirestore(String label, double confidence) async {
    await FirebaseFirestore.instance.collection('classifications').add({
      'class': label,
      'confidence': confidence,
      'targetClass': widget.targetClass,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Classify ${widget.targetClass}')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child:
                _cameraController != null &&
                    _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Result: $_result',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
