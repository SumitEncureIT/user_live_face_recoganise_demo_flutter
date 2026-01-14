import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';

InputImage cameraImageToInputImage(CameraImage image) {
  final WriteBuffer buffer = WriteBuffer();
  for (final plane in image.planes) {
    buffer.putUint8List(plane.bytes);
  }

  final bytes = buffer.done().buffer.asUint8List();

  final Size imageSize =
  Size(image.width.toDouble(), image.height.toDouble());

  final InputImageRotation rotation =
      InputImageRotation.rotation270deg; // 🔥 REQUIRED for front camera

  final InputImageFormat format =
      InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

  final metadata = InputImageMetadata(
    size: imageSize,
    rotation: rotation,
    format: format,
    bytesPerRow: image.planes.first.bytesPerRow,
  );

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: metadata,
  );
}
