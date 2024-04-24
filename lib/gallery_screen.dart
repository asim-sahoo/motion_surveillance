import 'dart:io';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:motion_surveillance/video_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


class GalleryScreen extends StatelessWidget {
  final List<XFile> videoFiles;

  const GalleryScreen({super.key, required this.videoFiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: ListView.separated(
        separatorBuilder: (ctx, index) => const Divider(
          height: 0,
          thickness: 0,
          color: Colors.grey,
          endIndent: 46,
          indent: 46,
        ),
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
              dismissible: DismissiblePane(onDismissed: () {
                videoFiles.removeAt(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Expense ${videoFiles[index].name} removed'),
                        duration:const Duration(seconds: 2),
                      ),
                    );
              }),
              children: [
                SlidableAction(
                  padding: EdgeInsets.zero,
                  onPressed: (context) {
                    videoFiles.removeAt(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Expense ${videoFiles[index].name} removed'),
                        duration:const Duration(seconds: 2),
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
            child: ListTile(
              title: Text('$formattedDate – ${videoFiles[index].name}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPage(filePath: videoFiles[index].path),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
