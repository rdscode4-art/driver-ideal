import os
import re

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
if 'import \'dart:ui\' as ui;' not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'dart:ui' as ui;\nimport 'dart:typed_data';\nimport 'package:flutter/services.dart';"
    )

# 2. Add carIcon variable
if 'BitmapDescriptor? carIcon;' not in content:
    content = content.replace(
        "var isMapReady = false.obs;",
        "var isMapReady = false.obs;\n  BitmapDescriptor? carIcon;"
    )

# 3. Add load functions and onInit
if '_loadCarIcon' not in content:
    load_func = """
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadCarIcon() async {
    try {
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/top_car.png', 60);
      carIcon = BitmapDescriptor.fromBytes(markerIcon);
      if (isMapReady.value) {
        _updateMapMarkers();
        _updateMapMarkersAndCircles();
      }
    } catch (e) {
      log('Failed to load car icon: $e');
    }
  }
"""
    content = content.replace(
        "void onInit() {\n    super.onInit();",
        "void onInit() {\n    super.onInit();\n    _loadCarIcon();"
    )
    # Add functions before onInit
    content = content.replace(
        "void onInit() {",
        load_func + "\n  void onInit() {"
    )

# 4. Update _updateMapMarkers
marker_regex = r"(markerId: const MarkerId\('driver'\),\s*position: LatLng\(driverLatitude\.value, driverLongitude\.value\),\s*icon:) BitmapDescriptor\.defaultMarkerWithHue\(BitmapDescriptor\.hueBlue\),(.*?\)\s*,)"
marker_replacement = r"\1 carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),\n            rotation: driverHeading.value,\n            flat: true,\n            anchor: const Offset(0.5, 0.5),\2"
content = re.sub(marker_regex, marker_replacement, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
