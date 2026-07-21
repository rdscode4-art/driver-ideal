import os

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Update markers and circles assignment
old_markers_assign = """    markers.assignAll(newMarkers);
    circles.assignAll(newCircles);"""
new_markers_assign = """    markers.value = newMarkers;
    markers.refresh();
    circles.value = newCircles;
    circles.refresh();"""
if old_markers_assign in content:
    content = content.replace(old_markers_assign, new_markers_assign)

# Update polylines assignment
old_polylines_assign = """      polylines.assignAll({
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue[600]!,
          width: 8,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      });"""
new_polylines_assign = """      polylines.value = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue[600]!,
          width: 8,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
      polylines.refresh();"""
if old_polylines_assign in content:
    content = content.replace(old_polylines_assign, new_polylines_assign)

old_polylines_clear = "      polylines.clear();"
new_polylines_clear = "      polylines.value = {};\n      polylines.refresh();"
if old_polylines_clear in content:
    content = content.replace(old_polylines_clear, new_polylines_clear)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
