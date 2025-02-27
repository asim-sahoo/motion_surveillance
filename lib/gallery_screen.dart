import 'dart:io';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:motion_test/video_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:shared_preferences/shared_preferences.dart';

class GalleryScreen extends StatelessWidget {
  final List<XFile> videoFiles;

  const GalleryScreen({super.key, required this.videoFiles});

  Future<void> removeVideoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final savedVideos = prefs.getStringList('video_paths') ?? [];
    savedVideos.remove(path);
    await prefs.setStringList('video_paths', savedVideos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 240, 255),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text(
          'RECORDED VIDEOS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView.builder(
        itemCount: videoFiles.length,
        itemBuilder: (context, index) {
          final formatter = DateFormat('yyyy-MM-dd – kk:mm');
          final DateTime date = File(videoFiles[index].path).lastModifiedSync();
          final formattedDate = formatter.format(date);
          return Slidable(
            key: UniqueKey(),
            endActionPane: ActionPane(
              extentRatio: 0.25,
              motion: const ScrollMotion(),
              dismissible: DismissiblePane(
                onDismissed: () async {
                  final path = videoFiles[index].path;
                  videoFiles.removeAt(index);
                  await removeVideoPath(path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video ${path.split('/').last} removed'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              children: [
                SlidableAction(
                  padding: EdgeInsets.zero,
                  onPressed: (context) async {
                    final path = videoFiles[index].path;
                    videoFiles.removeAt(index);
                    await removeVideoPath(path);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Video ${path.split('/').last} removed'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFFFE4A49),
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Image.asset(
                  'assets/static_image.png', // Replace with your static image path
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoFiles[index].name,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 17, 17, 17),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 17, 17, 17),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 106, 96),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Activity Detected',
                        style: TextStyle(
                          fontSize: 8,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPage(
                        filePath: videoFiles[index].path,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
