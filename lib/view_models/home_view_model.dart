import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:object_detection_app/app/base/bas_view_model.dart';
import 'package:object_detection_app/services/tensorflow_service.dart';
import 'package:object_detection_app/services/tts_service.dart';
import 'package:object_detection_app/view_states/home_view_state.dart';

import '/models/recognition.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  bool _isLoadModel = false;
  bool _isDetecting = false;
  List<String>? _labels;
  // String? _selectedObject;
  bool _navigatedToCapture = false;
  final Map<String, double> _previousAreas = {};
  double _screenWidth = 0;
  double _screenHeight = 0;
  int _lastWarningTime = 0;
  static const int _warningCooldownMs = 3000; // 3 giây

  late final TensorFlowService _tensorFlowService;
  late final TtsService _ttsService = TtsService();

  HomeViewModel(BuildContext context, this._tensorFlowService)
      : super(context, HomeViewState());

  // void setSelectedObject(String value) {
  //   _selectedObject = value;
  //   state.selectedObject = value;
  //   notifyListeners();
  // }
  void setScreenSize(double width, double height) {
    _screenWidth = width;
    _screenHeight = height;
  }

  void setNavigatedToCapture(bool value) {
    _navigatedToCapture = value;
    state.navigatedToCapture = value;

    notifyListeners();
  }

  Future<void> loadModel() async {
    await _tensorFlowService.loadModel();

    _isLoadModel = true;
  }

  Future<void> loadLabels() async {
    log('Loading labels...');

    _labels = await _tensorFlowService.loadLabels();
    state.labels = _labels;
    notifyListeners();
  }

  Future<void> runModel(BuildContext context, CameraImage cameraImage) async {
    try {
      if (_isLoadModel && mounted) {
        if (!_isDetecting && mounted) {
          if (!_navigatedToCapture) {
            _isDetecting = true;
            int startTime = DateTime.now().millisecondsSinceEpoch;
            var recognitions =
                await _tensorFlowService.runModelOnFrame(cameraImage);
            int endTime = DateTime.now().millisecondsSinceEpoch;

            log('Time detection: ${endTime - startTime}');

            if (recognitions != null && mounted) {
              // state.recognitions = findHighestConfidenceRecognition(
              //     List<Recognition>.from(
              //         recognitions.map((model) => Recognition.fromJson(model))),
              //     _selectedObject ?? "");
              state.recognitions = List<Recognition>.from(
                recognitions.map((model) => Recognition.fromJson(model)),
              );
              for (final r in state.recognitions) {
                if (_isCollisionRisk(r, _screenWidth, _screenHeight)) {
                  _triggerCollisionWarning(r.detectedClass!);
                  break;
                }
              }

              state.widthImage = cameraImage.width;
              state.heightImage = cameraImage.height;
              notifyListeners();
            }
            _isDetecting = false;
          }
        }
      } else {
        log('Please run `loadModel(type)` before running `runModel(cameraImage)`');
      }
    } catch (e) {
      log("$e");
    }
  }

  void _triggerCollisionWarning(String label) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (now - _lastWarningTime < _warningCooldownMs) {
      return;
    }

    _lastWarningTime = now;

    final String message = _buildWarningMessage(label);

    debugPrint("WARNING: $message");
    _ttsService.speak(message);
  }

  String _buildWarningMessage(String label) {
    switch (label.toLowerCase()) {
      case 'person':
        return 'Cẩn thận, có người phía trước';
      case 'car':
      case 'motorbike':
      case 'bus':
        return 'Cẩn thận, có xe phía trước';
      default:
        return 'Cẩn thận, có vật cản phía trước';
    }
  }

  // List<Recognition> findHighestConfidenceRecognition(
  //     List<Recognition> recognitions, String selectedObject) {
  //   final filteredRecognitions = recognitions
  //       .where((recognition) => recognition.detectedClass == selectedObject)
  //       .toList();
  //   if (filteredRecognitions.isEmpty) {
  //     return [];
  //   }
  //   Recognition? highestConfidenceRecognition;
  //   double highestConfidence = 0;

  //   for (final recognition in filteredRecognitions) {
  //     if (recognition.confidenceInClass! > highestConfidence) {
  //       highestConfidence = recognition.confidenceInClass!;
  //       highestConfidenceRecognition = recognition;
  //     }
  //   }
  //   return highestConfidenceRecognition == null
  //       ? []
  //       : [highestConfidenceRecognition];
  // }

  bool _isCollisionRisk(
    Recognition current,
    double screenWidth,
    double screenHeight,
  ) {
    // 1. confidence (null-safe)
    final double confidence = current.confidenceInClass ?? 0.0;
    if (confidence < 0.5) return false;

    // 2. rect null check
    final rect = current.rect;
    if (rect == null) return false;

    // 3. label null check
    final String? label = current.detectedClass;
    if (label == null) return false;

    // 4. bounding box size (YOLO rect)
    final double boxWidth = rect.w * screenWidth;
    final double boxHeight = rect.h * screenHeight;
    final double currentArea = boxWidth * boxHeight;

    // 5. so sánh diện tích
    final double? previousArea = _previousAreas[label];
    _previousAreas[label] = currentArea;

    if (previousArea == null) return false;
    if (currentArea / previousArea < 1.3) return false;

    // 6. vị trí trung tâm bounding box
    final double centerX = rect.x + rect.w / 2;
    final double centerY = rect.y + rect.h / 2;

    final double dx = (centerX - 0.5).abs();
    final double dy = (centerY - 0.5).abs();

    if (dx > 0.25 || dy > 0.25) return false;

    return true;
  }

  Uint8List convertCameraImageToFile(CameraImage cameraImage) {
    try {
      // Step 1: Convert YUV data to RGB
      final img.Image? image = _convertYUV420ToImage(cameraImage);
      if (image == null) {
        throw Exception('Failed to convert CameraImage to RGB.');
      }

      // Step 2: Encode the image as JPEG
      final Uint8List jpegData = Uint8List.fromList(img.encodeJpg(image));

      return jpegData;
    } catch (e) {
      print('Error converting CameraImage to file: $e');
      rethrow;
    }
  }

  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      // Plane data from CameraImage
      final Uint8List yPlane = cameraImage.planes[0].bytes;
      final Uint8List uPlane = cameraImage.planes[1].bytes;
      final Uint8List vPlane = cameraImage.planes[2].bytes;

      // Calculate pixel strides
      final int yRowStride = cameraImage.planes[0].bytesPerRow;
      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

      // Create an empty image buffer
      final img.Image image = img.Image(width: width, height: height);

      // Convert YUV to RGB
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          final int yValue = yPlane[yIndex];
          final int uValue = uPlane[uvIndex] - 128;
          final int vValue = vPlane[uvIndex] - 128;

          // Convert YUV to RGB
          final int r = (yValue + 1.402 * vValue).clamp(0, 255).toInt();
          final int g =
              (yValue - 0.344 * uValue - 0.714 * vValue).clamp(0, 255).toInt();
          final int b = (yValue + 1.772 * uValue).clamp(0, 255).toInt();
          final color = img.ColorRgb8(r, g, b);

          // Set the pixel color in the image buffer
          image.setPixel(x, y, color);
        }
      }

      return image;
    } catch (e) {
      print('Error converting YUV420 to RGB: $e');
      return null;
    }
  }

  Future<void> close() async {
    await _tensorFlowService.close();
  }
}
