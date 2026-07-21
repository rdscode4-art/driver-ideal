import os
import re

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _startSmoothAnimation parameters
old_anim_func = """  void _startSmoothAnimation(LatLng start, LatLng end, double startRot, double endRot) {
    _animationTimer?.cancel();
    
    // Normalize rotation difference to take the shortest path
    double rotDiff = endRot - startRot;
    if (rotDiff > 180) rotDiff -= 360;
    if (rotDiff < -180) rotDiff += 360;
    
    const int durationMs = 1000; // 1 second animation (GPS update rate)
    const int frameRateMs = 16; // ~60fps"""

new_anim_func = """  void _startSmoothAnimation(LatLng start, LatLng end, double startRot, double endRot) {
    _animationTimer?.cancel();
    
    // Normalize rotation difference to take the shortest path
    double rotDiff = endRot - startRot;
    if (rotDiff > 180) rotDiff -= 360;
    if (rotDiff < -180) rotDiff += 360;
    
    const int durationMs = 1000; // 1 second animation (GPS update rate)
    const int frameRateMs = 40; // ~25fps (safer for Google Maps MethodChannel)"""

content = content.replace(old_anim_func, new_anim_func)

# 2. Update _updateDriverLocationWithPosition for jump snapping
old_driver_update = """    if (_animatedPosition == null) {
      _animatedPosition = newPos;
      _animatedRotation = position.heading;
      if (isMapReady.value) {
        _updateMapMarkersAndCircles();
      }
    } else {
      _startSmoothAnimation(oldPos, newPos, oldRot, position.heading);
    }"""

new_driver_update = """    if (_animatedPosition == null) {
      _animatedPosition = newPos;
      _animatedRotation = position.heading;
      if (isMapReady.value) {
        _updateMapMarkersAndCircles();
      }
    } else {
      double dist = Geolocator.distanceBetween(
        oldPos.latitude, oldPos.longitude, 
        newPos.latitude, newPos.longitude
      );
      if (dist > 50) {
        // If the jump is larger than 50 meters, snap instantly (Mock location or GPS fix)
        _animatedPosition = newPos;
        _animatedRotation = position.heading;
        _animationTimer?.cancel();
        if (isMapReady.value) {
          _updateMapMarkersAndCircles();
        }
      } else {
        _startSmoothAnimation(oldPos, newPos, oldRot, position.heading);
      }
    }"""

content = content.replace(old_driver_update, new_driver_update)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
