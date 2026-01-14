import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../model/face_user.dart';


class FaceMatcher {
  FaceUser? findMatch(List<double> embedding) {
    final box = Hive.box<FaceUser>('faces');
    double bestScore = 0.0;
    FaceUser? bestUser;

    for (final user in box.values) {
      final score = _cosine(embedding, user.embedding);

      debugPrint(
        "Comparing with ${user.name} → score: ${score.toStringAsFixed(3)}",
      );

      if (score > bestScore) {
        bestScore = score;
        bestUser = user;
      }
    }

    debugPrint("BEST SCORE: $bestScore");

    if (bestScore > 0.75) {
      return bestUser;
    }
    return null;
  }

  double _cosine(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    return dot / (sqrt(na) * sqrt(nb));
  }
}
