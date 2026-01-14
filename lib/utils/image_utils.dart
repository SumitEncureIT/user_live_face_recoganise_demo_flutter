import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

img.Image cropFace(File file, Face face) {
  final image = img.decodeImage(file.readAsBytesSync())!;
  final rect = face.boundingBox;

  return img.copyCrop(
    image,
    x: rect.left.toInt(),
    y: rect.top.toInt(),
    width: rect.width.toInt(),
    height: rect.height.toInt(),
  );
}


/// Crop face from CameraImage using Face bounding box
img.Image cropCameraImage(CameraImage image, Face face) {
  final int width = image.width;
  final int height = image.height;

  // Convert YUV420 to RGB
  final img.Image converted = _convertYUV420ToImage(image);

  // Bounding box
  final Rect box = face.boundingBox;

  int x = max(box.left.toInt(), 0);
  int y = max(box.top.toInt(), 0);
  int w = min(box.width.toInt(), width - x);
  int h = min(box.height.toInt(), height - y);

  img.Image cropped = img.copyCrop(
    converted,
    x: x,
    y: y,
    width: w,
    height: h,
  );

  return img.copyResize(cropped, width: 112, height: 112);
}

/// Convert CameraImage (YUV420) → RGB image
img.Image _convertYUV420ToImage(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final img.Image imgImage = img.Image(width: width, height: height);

  final Plane planeY = image.planes[0];
  final Plane planeU = image.planes[1];
  final Plane planeV = image.planes[2];

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex =
          (y ~/ 2) * planeU.bytesPerRow + (x ~/ 2);

      final int indexY = y * planeY.bytesPerRow + x;

      final int yValue = planeY.bytes[indexY];
      final int uValue = planeU.bytes[uvIndex];
      final int vValue = planeV.bytes[uvIndex];

      int r = (yValue + 1.370705 * (vValue - 128)).round();
      int g = (yValue - 0.337633 * (uValue - 128)
          - 0.698001 * (vValue - 128)).round();
      int b = (yValue + 1.732446 * (uValue - 128)).round();

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      imgImage.setPixelRgb(x, y, r, g, b);
    }
  }
  return imgImage;
}


Float32List imageToFloat32(img.Image image) {
  final resized = img.copyResize(image, width: 112, height: 112);
  final buffer = Float32List(112 * 112 * 3);
  int i = 0;

  for (int y = 0; y < 112; y++) {
    for (int x = 0; x < 112; x++) {
      final p = resized.getPixel(x, y);
      buffer[i++] = (p.r / 255 - 0.5) * 2;
      buffer[i++] = (p.g / 255 - 0.5) * 2;
      buffer[i++] = (p.b / 255 - 0.5) * 2;
    }
  }
  return buffer;
}
