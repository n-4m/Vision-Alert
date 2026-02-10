import 'dart:math';

import 'package:flutter/material.dart';
import 'package:object_detection_app/app/app_resources.dart';

import '../../models/recognition.dart';

class ConfidenceWidget extends StatelessWidget {
  final List<Recognition> entities;
  final String selectedObject;
  final int previewWidth;
  final int previewHeight;
  final double screenWidth;
  final double screenHeight;

  final double heightAppBar;

  const ConfidenceWidget({
    super.key,
    required this.heightAppBar,
    required this.entities,
    required this.previewWidth,
    required this.previewHeight,
    required this.screenWidth,
    required this.screenHeight,
    required this.selectedObject,
  });

  List<Widget> _renderHeightLineEntities() {
    List<Widget> results = <Widget>[];
    // if (entities.isEmpty) {
    //   results.add(
    //     Center(
    //       child: Padding(
    //         padding: const EdgeInsets.all(8.0),
    //         child: Text(
    //           'Detecting $selectedObject',
    //           style: AppTextStyles.regularTextStyle(
    //               color: Colors.red,
    //               fontSize: AppFontSizes.medium,
    //               backgroundColor: AppColors.white),
    //         ),
    //       ),
    //     ),
    //   );
    // } else {
    results = entities.map((entity) {
      var x0 = entity.rect!.x;
      var y0 = entity.rect!.y;
      var w0 = entity.rect!.w;
      var h0 = entity.rect!.h;

      var screenRatio = screenHeight / screenWidth;
      var previewRatio = previewHeight / previewWidth;

      var scaleWidth, scaleHeight, x, y, w, h;
      if (screenRatio > previewRatio) {
        scaleHeight = screenHeight;
        scaleWidth = screenHeight / previewRatio;
        var difW = (scaleWidth - screenWidth) / scaleWidth;
        x = (x0 - difW / 2) * scaleWidth;
        w = w0 * scaleWidth;
        if (x0 < difW / 2) {
          w -= (difW / 2 - x0) * scaleWidth;
        }
        y = y0 * scaleHeight;
        h = h0 * scaleHeight;
      } else {
        scaleHeight = screenWidth * previewRatio;
        scaleWidth = screenWidth;
        var difH = (scaleHeight - screenHeight) / scaleHeight;
        x = x0 * scaleWidth;
        w = w0 * scaleWidth;
        y = (y0 - difH / 2) * scaleHeight;
        h = h0 * scaleHeight;
        if (y0 < difH / 2) {
          h -= (difH / 2 - y0) * scaleHeight;
        }
      }
      return Positioned(
        left: max(0, x),
        top: max(0, y),
        width: w,
        height: h,
        child: Container(
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Detecting ${entity.detectedClass ?? ''} ${((entity.confidenceInClass ?? 0) * 100).toStringAsFixed(0)}%',
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 2,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.regularTextStyle(
                      color: Colors.red,
                      fontSize: AppFontSizes.medium,
                      backgroundColor: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
    // }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childes = [];
    childes = _renderHeightLineEntities();
    return Stack(
      children: childes,
    );
  }
}
