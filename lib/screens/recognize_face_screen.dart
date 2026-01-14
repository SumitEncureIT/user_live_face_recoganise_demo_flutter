import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_detector_service.dart';
import '../services/face_matcher.dart';
import '../services/facenet_service.dart';
import '../utils/image_utils.dart';

class RecognizeFaceScreen extends StatefulWidget {
  const RecognizeFaceScreen({super.key});

  @override
  State<RecognizeFaceScreen> createState() => _RecognizeFaceScreenState();
}

class _RecognizeFaceScreenState extends State<RecognizeFaceScreen> {
  final picker = ImagePicker();
  final detector = FaceDetectorService();
  final matcher = FaceMatcher();

  late FaceNetService facenet; // ✅ singleton
  bool _modelReady = false;

  String result = "No Face";
  File? _capturedImage; // ✅ store clicked image

  @override
  void initState() {
    super.initState();
    _initFaceNet();
  }

  Future<void> _initFaceNet() async {
    facenet = await FaceNetService.getInstance();
    setState(() => _modelReady = true);
  }

  Future<void> recognize() async {
    if (!_modelReady) return;

    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return;

    final file = File(x.path);
    setState(() => _capturedImage = file);
    final face = await detector.detectFace(file);
    if (face == null) {
      setState(() => result = "No Face Detected");
      return;
    }

    final cropped = cropFace(file, face);
    final input = imageToFloat32(cropped);
    final embedding = facenet.getEmbedding(input);
    final user = matcher.findMatch(embedding);

    setState(() {
      result = user != null ? "Hello ${user.name}" : "Unknown Face";
    });
  }

  @override
  void dispose() {
    detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recognize Face")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 📸 Captured Image
            if (_capturedImage != null)
              CircleAvatar(
                radius: 80,
                backgroundImage: FileImage(_capturedImage!),
              ),

            const SizedBox(height: 20),

            /// 👤 Result text
            Text(result, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _modelReady ? recognize : null,
              child: const Text("Scan Face"),
            ),
          ],
        ),
      ),
    );
  }
}
