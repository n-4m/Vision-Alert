import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_detection_app/app/base/bas_view_model.dart';
import 'package:object_detection_app/services/tensorflow_service.dart';
import 'package:object_detection_app/services/tts_service.dart';
import 'package:object_detection_app/view_states/home_view_state.dart';
import '/models/recognition.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  bool _isLoadModel = false;
  bool _isDetecting = false;
  List<String>? _labels;
  final Map<String, double> _previousAreas = {};
  static const double _minDangerAreaRatio = 0.2; // 12% màn hình
  double _screenWidth = 0;
  double _screenHeight = 0;
  int _lastWarningTime = 0;
  static const int _warningCooldownMs = 3000; // 3 giây
  static const Set<String> _dangerousObjects = {
    'person',
    'bicycle',
    'car',
    'motorbike',
    'bus',
    'train',
    'truck',
    'boat',
    'fire hydrant',
    'bench',
    'chair',
    'diningtable',
    'sofa',
    'bed',
    'refrigerator',
  };

  late final TensorFlowService _tensorFlowService;
  late final TtsService _ttsService = TtsService();

  HomeViewModel(BuildContext context, this._tensorFlowService)
      : super(context, HomeViewState());

  void setScreenSize(double width, double height) {
    _screenWidth = width;
    _screenHeight = height;
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
          _isDetecting = true;
          int startTime = DateTime.now().millisecondsSinceEpoch;
          var recognitions =
              await _tensorFlowService.runModelOnFrame(cameraImage);
          int endTime = DateTime.now().millisecondsSinceEpoch;

          log('Time detection: ${endTime - startTime}');

          if (recognitions != null && mounted) {
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
      } else {
        log('Please run `loadModel(type)` before running `runModel(cameraImage)`');
      }
    } catch (e) {
      log("$e");
    }
  }

  Future<void> _strongVibration() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _triggerCollisionWarning(String label) async {
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (now - _lastWarningTime < _warningCooldownMs) return;

    _lastWarningTime = now;

    final String message = _buildWarningMessage(label);

    _ttsService.speak(message);

    await _strongVibration();
  }

  String _buildWarningMessage(String label) {
    switch (label.toLowerCase()) {
      case 'person':
        return 'Cẩn thận, có người phía trước';
      case 'car':
      case 'motorbike':
      case 'bus':
      case 'truck':
      case 'bicycle':
      case 'train':
        return 'Cẩn thận, có xe phía trước';
      case 'bench':
      case 'chair':
      case 'diningtable':
      case 'sofa':
        return 'Cẩn thận, có bàn ghế phía trước';
      default:
        return 'Cẩn thận, có vật cản phía trước';
    }
  }

  bool _isCollisionRisk(
    Recognition current,
    double screenWidth,
    double screenHeight,
  ) {
    // confidence (null-safe)
    final double confidence = current.confidenceInClass ?? 0.0;
    if (confidence < 0.5) return false;

    // rect null check
    final rect = current.rect;
    if (rect == null) return false;

    // label null check
    final String? label = current.detectedClass;
    if (label == null) return false;

    if (!_dangerousObjects.contains(label.toLowerCase())) {
      return false;
    }

    // bounding box size (YOLO rect)
    final double boxWidth = rect.w * screenWidth;
    final double boxHeight = rect.h * screenHeight;
    final double currentArea = boxWidth * boxHeight;

    // so sánh diện tích
    final double? previousArea = _previousAreas[label];
    _previousAreas[label] = currentArea;

    if (previousArea == null) return false;
    final double screenArea = screenWidth * screenHeight;
    final double areaRatio = currentArea / screenArea;

    if (currentArea / previousArea < 2) return false;
    if (areaRatio < _minDangerAreaRatio) return false;

    // vị trí trung tâm bounding box
    final double centerX = rect.x + rect.w / 2;
    final double centerY = rect.y + rect.h / 2;

    final double dx = (centerX - 0.5).abs();
    final double dy = (centerY - 0.5).abs();

    if (dx > 0.25 || dy > 0.25) return false;

    return true;
  }

  void resetCollisionState() {
    _previousAreas.clear();
    _lastWarningTime = 0;
  }

  Future<void> close() async {
    await _tensorFlowService.close();
  }
}
