import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:motion_surveillance/realtime/bounding_box.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:motion_surveillance/gallery_screen.dart';

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
  }

  void startTenSecondTimer() {
    _timer = Timer(const Duration(seconds: 10), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void initCamera() async {
    if (widget.cameras.isEmpty) return;
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
    );
    await controller.initialize();
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
          numResultsPerClass: 1,
          threshold: 0.4,
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

      bool personDetected = _recognitions.any((element) =>
          element['detectedClass'] == 'person' &&
          element['confidenceInClass'] > 0.65);

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
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video Recording Started"),
        ),
      );
    startTenSecondTimer();
  }

  void _stopRecording() async {
    final file = await controller.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _recordedVideos.add(file);
      //toast for video saved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video Saved"),
        ),
      );
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
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;

    Size screen = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Motion Surveillance System"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _navigateToGallery,
            icon: const Icon(Icons.video_library),
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          OverflowBox(
            maxHeight: screenRatio > previewRatio
                ? screenH
                : screenW / previewW * previewH,
            maxWidth: screenRatio > previewRatio
                ? screenH / previewH * previewW
                : screenW,
            child: CameraPreview(controller),
          ),
          if (!_isRecording)
            BoundingBox(
              _recognitions,
              math.max(_imageHeight, _imageWidth),
              math.min(_imageHeight, _imageWidth),
              screen.height,
              screen.width,
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
              margin: EdgeInsets.only(top: h * 0.65),
              decoration: BoxDecoration(
                border: Border.all(width: 0, color: Colors.transparent),
              ),
              height: h * 0.1,
              width: w * 0.31,
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
                    side: const BorderSide(color: Colors.white, width: 4.0)),
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
    
  }
}
