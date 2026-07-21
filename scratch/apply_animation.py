import os

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add timer variable and animated states
if '_animationTimer' not in content:
    content = content.replace(
        "var isMapReady = false.obs;\n  BitmapDescriptor? carIcon;",
        "var isMapReady = false.obs;\n  BitmapDescriptor? carIcon;\n  Timer? _animationTimer;\n  LatLng? _animatedPosition;\n  double _animatedRotation = 0.0;\n  LatLng? _targetPosition;\n  double _targetRotation = 0.0;"
    )

# 2. Add polyline trimming method
if '_trimRouteToDriver' not in content:
    trim_method = """
  List<LatLng> _trimRouteToDriver(List<LatLng> route, LatLng driverLocation) {
    if (route.isEmpty) return route;
    
    int closestIndex = 0;
    double minDistance = double.infinity;
    int limit = route.length > 100 ? 100 : route.length;
    
    for (int i = 0; i < limit; i++) {
      double distance = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        route[i].latitude,
        route[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    return route.sublist(closestIndex);
  }
"""
    content = content.replace(
        "void _updatePolylines() {",
        trim_method + "\n  void _updatePolylines() {"
    )

# 3. Update _updatePolylines to use trimming
if '_trimRouteToDriver(' not in content.split('void _updatePolylines() {')[1]:
    old_poly = "points.addAll(navData.points!);\n      print('✅ Map: Using ${navData.points!.length} high-res route points');"
    new_poly = """
      if (_isValidCoordinate(driverLatitude.value, driverLongitude.value)) {
        final driverLoc = LatLng(driverLatitude.value, driverLongitude.value);
        final trimmed = _trimRouteToDriver(navData.points!, driverLoc);
        points.add(driverLoc);
        points.addAll(trimmed);
      } else {
        points.addAll(navData.points!);
      }
      print('✅ Map: Using ${points.length} high-res route points (trimmed)');
"""
    content = content.replace(old_poly, new_poly)

# 4. Implement smooth animation logic
animation_method = """
  void _startSmoothAnimation(LatLng start, LatLng end, double startRot, double endRot) {
    _animationTimer?.cancel();
    
    // Normalize rotation difference to take the shortest path
    double rotDiff = endRot - startRot;
    if (rotDiff > 180) rotDiff -= 360;
    if (rotDiff < -180) rotDiff += 360;
    
    const int durationMs = 1000; // 1 second animation (GPS update rate)
    const int frameRateMs = 16; // ~60fps
    int steps = durationMs ~/ frameRateMs;
    int currentStep = 0;
    
    _animationTimer = Timer.periodic(const Duration(milliseconds: frameRateMs), (timer) {
      currentStep++;
      if (currentStep >= steps) {
        timer.cancel();
        _animatedPosition = end;
        _animatedRotation = endRot;
      } else {
        double progress = currentStep / steps;
        // Ease-out cubic interpolation
        double easeProgress = 1 - (1 - progress) * (1 - progress) * (1 - progress);
        
        double lat = start.latitude + (end.latitude - start.latitude) * easeProgress;
        double lng = start.longitude + (end.longitude - start.longitude) * easeProgress;
        
        _animatedPosition = LatLng(lat, lng);
        _animatedRotation = startRot + (rotDiff * easeProgress);
      }
      
      // Update markers efficiently without re-rendering the whole map
      if (isMapReady.value) {
        _updateMapMarkersAndCircles();
      }
    });
  }
"""

if '_startSmoothAnimation' not in content:
    content = content.replace(
        "void _updateDriverLocationWithPosition(Position position) {",
        animation_method + "\n  void _updateDriverLocationWithPosition(Position position) {"
    )

# 5. Modify _updateDriverLocationWithPosition to call animation
old_driver_update = """
    driverLatitude.value = position.latitude;
    driverLongitude.value = position.longitude;
    driverLocationAccuracy.value = position.accuracy;
    driverHeading.value = position.heading;
    driverSpeed.value = position.speed * 3.6; // Convert m/s to km/h
    lastLocationUpdate.value = DateTime.now();

    // Update map display
    if (isMapReady.value) {
      _updateMapMarkersAndCircles();
    }
"""

new_driver_update = """
    final oldPos = _animatedPosition ?? LatLng(driverLatitude.value, driverLongitude.value);
    final oldRot = _animatedRotation;
    
    driverLatitude.value = position.latitude;
    driverLongitude.value = position.longitude;
    driverLocationAccuracy.value = position.accuracy;
    driverHeading.value = position.heading;
    driverSpeed.value = position.speed * 3.6; // Convert m/s to km/h
    lastLocationUpdate.value = DateTime.now();
    
    final newPos = LatLng(position.latitude, position.longitude);
    
    if (_animatedPosition == null) {
      _animatedPosition = newPos;
      _animatedRotation = position.heading;
      if (isMapReady.value) {
        _updateMapMarkersAndCircles();
      }
    } else {
      _startSmoothAnimation(oldPos, newPos, oldRot, position.heading);
    }
"""
content = content.replace(old_driver_update, new_driver_update)

# 6. Make _updateMapMarkersAndCircles use animated coordinates for the car
old_marker = """
      // Add driver marker with rotation based on heading
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(driverLatitude.value, driverLongitude.value),
          icon: carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: driverHeading.value,
          flat: true,
          anchor: const Offset(0.5, 0.5),
"""

new_marker = """
      // Add driver marker with rotation based on heading
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _animatedPosition ?? LatLng(driverLatitude.value, driverLongitude.value),
          icon: carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          rotation: _animatedRotation,
          flat: true,
          anchor: const Offset(0.5, 0.5),
"""
content = content.replace(old_marker, new_marker)

# 7. Don't forget to cancel the timer on close
if '_animationTimer?.cancel();' not in content:
    content = content.replace(
        "void onClose() {",
        "void onClose() {\n    _animationTimer?.cancel();"
    )

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
