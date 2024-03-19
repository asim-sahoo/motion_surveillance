import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:motion_surveillance/realtime/bounding_box.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:motion_surveillance/video_page.dart';

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
  late Timer _timer;
  late List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;

  @override
  void initState() {
    super.initState();
    _recognitions = [];
    loadTfModel();
    initCamera();
  }

  void initCamera() async {
    if (widget.cameras.isEmpty) return;

    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
    );

    await controller.initialize();

    if (!mounted) return;

    setState(() {});

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
    controller.dispose();
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

      if (_isRecording) {
        return;
      }

      bool personDetected = _recognitions.any((element) =>
          element['detectedClass'] == 'person' &&
          element['confidenceInClass'] > 0.5); 

      if (personDetected) {
        if (!_isRecording) {
          _startRecording();
        }
      } else {
        if (_isRecording) {
          _timer.cancel();
          _stopRecording();
        }
      }
    });
  }

  void _startRecording() async {
    await controller.prepareForVideoRecording();
    await controller.startVideoRecording();
    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    final file = await controller.stopVideoRecording();
    setState(() => _isRecording = false);
    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VideoPage(filePath: file.path),
    );
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
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

    Size screen = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Motion Surveillance System"),
        actions: [
          IconButton(
            onPressed: () {
              if (!_isRecording) {
                _startRecording();
              } else {
                _stopRecording();
              }
            },
            icon: Icon(_isRecording ? Icons.stop : Icons.circle),
          ),
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
          BoundingBox(
            _recognitions,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
          ),
        ],
      ),
    );
  }
}