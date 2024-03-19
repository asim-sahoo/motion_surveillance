import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:motion_surveillance/realtime/live_camera.dart';
import 'package:permission_handler/permission_handler.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  cameras = await availableCameras();
  runApp(
    MaterialApp(
      home: const MyApp(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    ),
  );
}

Future<void> _requestPermissions() async {
  PermissionStatus cameraPermissionStatus = await Permission.camera.request();

  PermissionStatus storagePermissionStatus = await Permission.storage.request();

  if (cameraPermissionStatus != PermissionStatus.granted ||
      storagePermissionStatus != PermissionStatus.granted) {}
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Motion Surveillance System"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonTheme(
              minWidth: 160,
              child: ElevatedButton(
                child: const Text("Start"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraFeed(cameras),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
