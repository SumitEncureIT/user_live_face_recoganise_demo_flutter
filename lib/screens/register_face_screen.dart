import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/face_user.dart';
import '../services/face_detector_service.dart';
import '../services/facenet_service.dart';
import '../utils/image_utils.dart';
import 'package:hive/hive.dart';

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  final picker = ImagePicker();
  final detector = FaceDetectorService();
  late FaceNetService facenet; // ✅ singleton
  final nameCtrl = TextEditingController();

  File? image;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _initFaceNet();
  }

  Future<void> _initFaceNet() async {
    facenet = await FaceNetService.getInstance();
    setState(() => _modelReady = true);
  }

  Future<void> register() async {
    if (!_modelReady || image == null || nameCtrl.text.isEmpty) return;

    final face = await detector.detectFace(image!);
    if (face == null) return;

    final cropped = cropFace(image!, face);
    final input = imageToFloat32(cropped);
    final embedding = facenet.getEmbedding(input);
    debugPrint("REGISTER embedding length: ${embedding.length}");

    final user = FaceUser(
      name: nameCtrl.text,
      embedding: embedding,
      imagePath: image!.path,
    );

    Hive.box<FaceUser>('faces').add(user);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    detector.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Face")),
      body: Column(
        children: [
          if (image != null) Image.file(image!, height: 200),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(hintText: "Name"),
          ),
          ElevatedButton(
            onPressed: _modelReady
                ? () async {
              final x = await picker.pickImage(source: ImageSource.camera);
              if (x != null) setState(() => image = File(x.path));
            }
                : null,
            child: const Text("Capture"),
          ),
          ElevatedButton(
            onPressed: _modelReady ? register : null,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
