import re
import os

file_path = r'lib\controllers\ongoing_ride_controller.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add cached icons
if '_pickupIcon' not in content:
    content = content.replace(
        '  double _targetDriverHeading = 0.0;',
        '  double _targetDriverHeading = 0.0;\n  \n  final BitmapDescriptor _pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);\n  final BitmapDescriptor _dropoffIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);\n  final BitmapDescriptor _driverDefaultIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);'
    )

# 2. _updateMapMarkers: replace calls
content = re.sub(
    r'icon:\s*carIcon\s*\?\?\s*BitmapDescriptor\.defaultMarkerWithHue\(\s*BitmapDescriptor\.hueBlue\s*\),',
    'icon: carIcon ?? _driverDefaultIcon,',
    content
)
content = re.sub(
    r'icon:\s*BitmapDescriptor\.defaultMarkerWithHue\(\s*BitmapDescriptor\.hueGreen\s*,\s*\),',
    'icon: _pickupIcon,',
    content
)
content = re.sub(
    r'icon:\s*BitmapDescriptor\.defaultMarkerWithHue\(\s*BitmapDescriptor\.hueGreen\s*\),',
    'icon: _pickupIcon,',
    content
)
content = re.sub(
    r'icon:\s*BitmapDescriptor\.defaultMarkerWithHue\(BitmapDescriptor\.hueRed\),',
    'icon: _dropoffIcon,',
    content
)

# 3. Remove logs in _updateMapMarkersAndCircles
content = re.sub(r"log\('[^']*Updating map markers and circles[^']*'\);\n\s*log\('[^']*Driver:[^']*'\);\n\s*log\('[^']*Pickup:[^']*'\);\n\s*log\('[^']*Dropoff:[^']*'\);", "", content)
content = re.sub(r"log\(\s*'[^']*Added driver marker and circle[^']*',\s*\);\s*\} else \{\s*log\('[^']*Skipping driver marker - invalid coordinates'\);\s*\}", "}", content)
content = re.sub(r"log\(\s*'[^']*Added pickup marker[^']*',\s*\);\s*\} else \{\s*log\(\s*'[^']*Skipping pickup marker[^']*',\s*\);\s*\}", "}", content)
content = re.sub(r"log\(\s*'[^']*Added dropoff marker[^']*',\s*\);\s*\} else \{\s*log\(\s*'[^']*Skipping dropoff marker[^']*',\s*\);\s*\}", "}", content)
content = re.sub(r"log\(\s*'[^']*Map updated with \$\{newMarkers.length\} markers[^']*',\s*\);", "", content)

# 4. _startSmoothAnimation loop
content = re.sub(
    r"(_animatedPosition = LatLng\(lat, lng\);\s*_animatedRotation = currentHeading;\s*if \(isMapReady\.value\) \{\s*)(_updateMapMarkersAndCircles\(\);\s*\})",
    r"\1_updatePolylines();\n            \2",
    content
)

# 5. _updateDriverLocationWithPosition
content = re.sub(
    r"if \(dist > 200\) \{",
    "if (dist > 2000) {",
    content
)
content = re.sub(
    r"\} else \{\s*_startSmoothAnimation\(oldPos, newPos, oldRot, position\.heading\);\s*\}",
    """} else {
        double targetHeading = position.heading;
        if (dist > 1.0) {
          targetHeading = Geolocator.bearingBetween(
            oldPos.latitude, oldPos.longitude, 
            newPos.latitude, newPos.longitude
          );
        } else if (targetHeading <= 0) {
          targetHeading = oldRot;
        }
        _startSmoothAnimation(oldPos, newPos, oldRot, targetHeading);
      }""",
    content
)

# 6. Remove logs in _updatePolylines
content = re.sub(r"print\('[^']*Map: Using \$\{points.length\} high-res route points \(trimmed\)'\);\n\s*", "", content)
content = re.sub(r"print\('[^']*Map: No high-res points, using straight line to Pickup'\);\n\s*", "", content)
content = re.sub(r"print\('[^']*Map: No high-res points, using straight line to Dropoff'\);\n\s*", "", content)
content = re.sub(r"log\('[^']*Polylines updated with \$\{points.length\} points'\);\n\s*", "", content)
content = re.sub(r"log\('[^']*Not enough points for polyline: \$\{points.length\}'\);\n\s*", "", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixes applied.")
