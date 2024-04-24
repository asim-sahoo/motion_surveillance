import 'package:flutter/material.dart';
import 'dart:math' as math;

class BoundingBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;

  const BoundingBox(
      this.results, this.previewH, this.previewW, this.screenH, this.screenW,
      {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> renderBox() {
      return results.map((re) {
        var x0 = re["rect"]["x"];
        var w0 = re["rect"]["w"];
        var y0 = re["rect"]["y"];
        var h0 = re["rect"]["h"];
        dynamic scaleW, scaleH, x, y, w, h;

        if (screenH / screenW > previewH / previewW) {
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          var difW = (scaleW - screenW) / scaleW;
          x = (x0 - difW / 2) * scaleW;
          w = w0 * scaleW;
          if (x0 < difW / 2) w -= (difW / 2 - x0) * scaleW;
          y = y0 * scaleH;
          h = h0 * scaleH;
        } else {
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          var difH = (scaleH - screenH) / scaleH;
          x = x0 * scaleW;
          w = w0 * scaleW;
          y = (y0 - difH / 2) * scaleH;
          h = h0 * scaleH;
          if (y0 < difH / 2) h -= (difH / 2 - y0) * scaleH;
        }

        final bool isPersonDetected =
            re["detectedClass"] == "person" && re["confidenceInClass"] > 0.45;

        if (re["confidenceInClass"] < 0.5) {
          return Container();
        }

        return Positioned(
          left: math.max(0, x),
          top: math.max(0, y),
          child: Column(
            children: [
              Text(
                "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: isPersonDetected
                      ? Colors.green
                      : Colors.red,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: w,
                height: h,
                padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isPersonDetected
                        ? const Color.fromARGB(150, 76, 175, 79)
                        : const Color.fromARGB(100, 244, 67, 54),
                    width: 1.5,
                  ),
                  color: isPersonDetected
                      ? const Color.fromARGB(25, 76, 175, 79)
                      : const Color.fromARGB(25, 244, 67, 54),
                  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    return Stack(
      children: renderBox(),
    );
  }
}
