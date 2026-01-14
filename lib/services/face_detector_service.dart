import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
      enableContours: false,
    ),
  );

  Future<Face?> detectFace(File image) async {
    final input = InputImage.fromFile(image);
    final faces = await _detector.processImage(input);
    return faces.isNotEmpty ? faces.first : null;
  }

  void dispose() => _detector.close();
}
