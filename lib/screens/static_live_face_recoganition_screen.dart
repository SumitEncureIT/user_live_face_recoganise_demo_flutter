import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/facenet_service.dart';
import '../services/face_matcher.dart';
import '../utils/camera_utils.dart';
import '../utils/image_utils.dart';

class StaticLiveFaceRecoganitionScreen extends StatefulWidget {
  const StaticLiveFaceRecoganitionScreen({super.key});

  @override
  State<StaticLiveFaceRecoganitionScreen> createState() =>
      _StaticLiveFaceRecoganitionScreenState();
}

class _StaticLiveFaceRecoganitionScreenState extends State<StaticLiveFaceRecoganitionScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  late FaceNetService _faceNet;
  final FaceMatcher _matcher = FaceMatcher();

  bool _processing = false;
  String _result = "Scanning...";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _faceNet = await FaceNetService.getInstance();

    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: false,
      ),
    );

    // 🔥 START LIVE LOOP (SAFE WAY)
    _startLiveRecognition();

    setState(() {});
  }
  void _startLiveRecognition() {
    Timer.periodic(const Duration(milliseconds: 700), (timer) async {
      if (!mounted || _cameraController == null) {
        timer.cancel();
        return;
      }
      await _processFrame();
    });
  }

  Future<void> _processFrame() async {
    if (_processing) return;
    _processing = true;

    try {
      final picture = await _cameraController!.takePicture();
      final file = File(picture.path);

      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector!.processImage(inputImage);

      debugPrint("Faces detected: ${faces.length}");

      if (faces.isNotEmpty) {
        final face = faces.first;

        final cropped = cropFace(file, face);
        final input = imageToFloat32(cropped);
        final embedding = _faceNet.getEmbedding(input);

        final user = _matcher.findMatch(embedding);

        setState(() {
          _result = user != null ? "Hello ${user.name}" : "Unknown";
        });
      }
    } catch (e) {
      debugPrint("Live recognition error: $e");
    }

    _processing = false;
  }



  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Live Face Recognition")),
      body: Stack(
        children: [
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

