import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  static FaceNetService? _instance;
  late Interpreter _interpreter;

  FaceNetService._internal();

  /// Load model ONCE (Singleton)
  static Future<FaceNetService> getInstance() async {
    if (_instance == null) {
      final service = FaceNetService._internal();
      service._interpreter =
      await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
      _instance = service;
    }
    return _instance!;
  }

  /// Returns 192-D face embedding
  List<double> getEmbedding(Float32List inputImage) {
    // Convert Float32List -> [2,112,112,3]
    final input = _buildInputTensor(inputImage);

    // Output tensor [2,192]
    final output = List.generate(2, (_) => List.filled(192, 0.0));

    _interpreter.run(input, output);

    // Use first embedding
    return output[0];
  }

  /// Builds tensor with batch size = 2
  List<List<List<List<double>>>> _buildInputTensor(Float32List input) {
    int index = 0;

    // Create single image [112,112,3]
    final image = List.generate(
      112,
          (_) => List.generate(
        112,
            (_) => List.generate(
          3,
              (_) => input[index++],
        ),
      ),
    );

    // Duplicate to satisfy batch size = 2
    return [image, image];
  }
}
