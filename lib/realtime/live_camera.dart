import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_test/realtime/bounding_box.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:motion_test/gallery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Callback = void Function(List<dynamic>? list, int h, int w);

class CameraFeed extends StatefulWidget {
  const CameraFeed(this.cameras, {super.key});
  final List<CameraDescription> cameras;

  @override
  CameraFeedState createState() => CameraFeedState();
}

class CameraFeedState extends State<CameraFeed> {
  late CameraController controller;
  bool isDetecting = false;
  bool _isRecording = false;
  late List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  late Timer _timer;
  late List<XFile> _recordedVideos;
  bool _isCameraFeedOpen = false;

  @override
  void initState() {
    super.initState();
    _recognitions = [];
    _recordedVideos = [];
    loadTfModel();
    initCamera();
    loadSavedVideos();
  }

  Future<void> loadSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVideos = prefs.getStringList('video_paths') ?? [];
    setState(() {
      _recordedVideos = savedVideos.map((path) => XFile(path)).toList();
    });
  }

  void startTenSecondTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void initCamera() async {
    if (widget.cameras.isEmpty) return;

    // Find the back camera
    final backCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    controller = CameraController(
      backCamera,
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitDown);

    if (!mounted) return;
    startImageStream();
    setState(() {});
  }

  void startImageStream() {
    controller.startImageStream((CameraImage img) {
      if (!isDetecting) {
        isDetecting = true;
        Tflite.detectObjectOnFrame(
          bytesList: img.planes.map((plane) => plane.bytes).toList(),
          model: "SSDMobileNet",
          imageHeight: img.height,
          imageWidth: img.width,
          imageMean: 127.5,
          imageStd: 127.5,
          numResultsPerClass: 2,
          threshold: 0.1,
          asynch: true,
        ).then((recognitions) {
          setRecognitions(recognitions, img.height, img.width);
          isDetecting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.stopImageStream();
    controller.dispose();
    Tflite.close();
    _timer.cancel();
    super.dispose();
  }

  void loadTfModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  void setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;

      bool personDetected = _recognitions.any(
        (element) =>
            element['detectedClass'] == 'person' &&
            element['confidenceInClass'] > 0.65,
      );

      if (personDetected && !_isRecording && _isCameraFeedOpen) {
        _startRecording();
      }
    });
  }

  void _startRecording() async {
    await controller.prepareForVideoRecording();
    await controller.startVideoRecording();
    setState(() => _isRecording = true);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Video Recording Started")));
    startTenSecondTimer();
  }

  Future<void> saveVideoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final savedVideos = prefs.getStringList('video_paths') ?? [];
    savedVideos.add(path);
    await prefs.setStringList('video_paths', savedVideos);
  }

  void _stopRecording() async {
    final file = await controller.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _recordedVideos.add(file);
      saveVideoPath(file.path);
      //toast for video saved
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video Saved")));
      startImageStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    _isCameraFeedOpen = true;
    controller.resumePreview();

    if (!controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize!;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Motion Surveillance System"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _navigateToGallery,
            icon: const Icon(Icons.video_library),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox.expand(
                child: Transform.scale(
                  scale:
                      controller.value.aspectRatio /
                      constraints.maxWidth *
                      constraints.maxHeight,
                  child: Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()..rotateZ(
                            -math.pi / 2,
                          ), // Rotate 90 degrees counter-clockwise
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (!_isRecording)
            BoundingBox(
              _recognitions,
              math.max(_imageHeight, _imageWidth),
              math.min(_imageHeight, _imageWidth),
              screenH,
              screenW,
            ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black45,
                  Colors.black87,
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(top: screenH * 0.65),
              decoration: BoxDecoration(
                border: Border.all(width: 0, color: Colors.transparent),
              ),
              height: screenH * 0.1,
              width: screenW * 0.31,
              child: OutlinedButton(
                onPressed: () {
                  if (!_isRecording) {
                    _startRecording();
                  } else {
                    _stopRecording();
                  }
                },
                style: OutlinedButton.styleFrom(
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Colors.white, width: 4.0),
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.circle,
                  size: _isRecording ? 40 : 75,
                  color: _isRecording ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToGallery() {
    _isCameraFeedOpen = false;
    controller.pausePreview();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(videoFiles: _recordedVideos),
      ),
    );
    startImageStream();
  }
}
