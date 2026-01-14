import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:user_face_recoganise/screens/static_live_face_recoganition_screen.dart';

import '../model/face_user.dart';
import 'live_face_recognition_screen.dart';
import 'register_face_screen.dart';
import 'recognize_face_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<FaceUser>('faces');

    return Scaffold(
      appBar: AppBar(title: const Text("Face Recognition App")),
      body: Column(
        children: [
          const SizedBox(height: 10),

          ElevatedButton(
            child: const Text("Register Face"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterFaceScreen()),
            ),
          ),

          ElevatedButton(
            child: const Text("Recognize Face"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecognizeFaceScreen()),
            ),
          ),

          // 🔥 LIVE FACE BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text("Live Face Recognition"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LiveFaceRecognitionScreen(),
              ),
            ),
          ),

          // 🔥 LIVE FACE BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text("Static Live Face Recognition"),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StaticLiveFaceRecoganitionScreen(),
              ),
            ),
          ),

          const Divider(),

          const Divider(),

          const Text(
            "Registered Users",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<FaceUser> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text("No users registered"));
                }

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (_, i) {
                    final user = box.getAt(i)!;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: FileImage(File(user.imagePath)),
                      ),
                      title: Text(user.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => box.deleteAt(i),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
