import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:motion_test/realtime/live_camera.dart';
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
      backgroundColor: const Color.fromARGB(255,63,152,250),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Expanded(
              flex: 0,
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  "SEE-curity",
                  style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 0,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Image.asset(
                  "assets/elements/camera.gif",
                  width: MediaQuery.of(context).size.width * 0.8,
                  colorBlendMode: BlendMode.overlay,
                ),
              ),
            ),
            const SizedBox(
              height: 45
              
              
              ,
            ),
            // const SizedBox(height: 5),
            Expanded(
                flex: 0,
                // padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraFeed(cameras),
                        ),
                      );
                    },
                    icon: const Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 40, 0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Color.fromARGB(255, 75, 165, 255),
                      ),
                    ),
                    label: const Padding(
                      padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
                      child: Text(
                        "Get Started",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              
            ),
            const SizedBox(height: 20),
            const Text(
              "A Personalised AI - Powered Security System",
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
