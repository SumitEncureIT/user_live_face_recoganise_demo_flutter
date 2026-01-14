import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/facenet_service.dart';
import '../services/face_matcher.dart';
import '../utils/image_utils.dart';

class LiveFaceRecognitionScreen extends StatefulWidget {
  const LiveFaceRecognitionScreen({super.key});

  @override
  State<LiveFaceRecognitionScreen> createState() =>
      _LiveFaceRecognitionScreenState();
}

class _LiveFaceRecognitionScreenState
    extends State<LiveFaceRecognitionScreen> {
  // Camera state variables
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  late FaceNetService _faceNet;
  final FaceMatcher _matcher = FaceMatcher();

  bool _processing = false;
  String _result = "Scanning...";

  // Liveness detection variables
  bool _isLive = false;
  int _blinkCount = 0;
  bool _isWinking = false;

  Timer? _timer;

  // NEW: State to prevent crash on camera switch
  bool _isChangingCamera = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _faceNet = await FaceNetService.getInstance();

    _cameras = await availableCameras();

    _cameraIndex = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front);

    if (_cameraIndex == -1) {
      _cameraIndex = 0;
    }

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );

    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      debugPrint("No cameras found.");
      return;
    }

    // Set the changing state to true
    if (mounted) {
      setState(() {
        _isChangingCamera = true;
      });
    }

    _timer?.cancel();
    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    _resetLiveness();
    _startLiveRecognition();

    // Set the changing state to false once initialization is complete
    if (mounted) {
      setState(() {
        _isChangingCamera = false;
      });
    }
  }

  void _toggleCamera() {
    // No need to await here, let it run in the background
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    debugPrint("Switching to camera index: $_cameraIndex");
    _initializeCamera();
  }

  void _startLiveRecognition() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || _cameraController == null || _isChangingCamera) {
        // Also check if we are in the middle of a camera switch
        return;
      }
      await _processFrame();
    });
  }

  Future<void> _processFrame() async {
    if (_processing || !mounted || _cameraController == null) return;

    _processing = true;

    try {
      // Use isStreamingImages to prevent processing during disposal
      if (!_cameraController!.value.isStreamingImages) {
        final picture = await _cameraController!.takePicture();
        final file = File(picture.path);
        final inputImage = InputImage.fromFilePath(file.path);
        final faces = await _faceDetector!.processImage(inputImage);

        debugPrint("Faces detected: ${faces.length}");

        if (faces.isNotEmpty) {
          final face = faces.first;
          if (_isLive) {
            final cropped = cropFace(file, face);
            final input = imageToFloat32(cropped);
            final embedding = _faceNet.getEmbedding(input);
            final user = _matcher.findMatch(embedding);
            if (mounted) {
              setState(() {
                _result = user != null ? "Hello ${user.name}" : "Unknown";
              });
            }
          } else {
            _performLivenessCheck(face);
          }
        } else {
          _resetLiveness();
        }
      }
    } catch (e) {
      debugPrint("Live recognition error: $e");
      _resetLiveness();
    }

    _processing = false;
  }

  void _performLivenessCheck(Face face) {
    final double? leftEyeOpen = face.leftEyeOpenProbability;
    final double? rightEyeOpen = face.rightEyeOpenProbability;

    if (leftEyeOpen == null || rightEyeOpen == null) return;

    if (_isWinking && leftEyeOpen > 0.7 && rightEyeOpen > 0.7) {
      _blinkCount++;
      debugPrint("Blink detected! Total blinks: $_blinkCount");
      _isWinking = false;

      if (_blinkCount >= 1) {
        if(mounted) {
          setState(() {
            _isLive = true;
            _result = "Liveness Confirmed!";
          });
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _result = "Recognizing...";
            });
          }
        });
      }
    }

    if (leftEyeOpen < 0.3 && rightEyeOpen < 0.3) {
      _isWinking = true;
    }

    if (!_isLive && mounted) {
      setState(() {
        _result = "Please Blink to Verify";
      });
    }
  }

  void _resetLiveness() {
    if (mounted) {
      setState(() {
        _isLive = false;
        _blinkCount = 0;
        _isWinking = false;
        _result = "Scanning...";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // Show a general loading indicator if the controller is null
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Face Recognition"),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_outlined),
              onPressed: _isChangingCamera ? null : _toggleCamera, // Disable button during switch
              tooltip: "Rotate Camera",
            ),
        ],
      ),
      body: Stack(
        children: [
          // This is the key change: show a loader while the camera is switching
          if (_isChangingCamera)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreview(_cameraController!),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
