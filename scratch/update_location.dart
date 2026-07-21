import os

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_settings = """      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update every 3 meters for smoother tracking
        // Removed timeLimit to make it truly continuous and limitless
      );"""

new_settings = """      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Force GPS to update at maximum frequency (typically 1Hz)
      );"""

if old_settings in content:
    content = content.replace(old_settings, new_settings)
else:
    print("Could not find the exact string to replace.")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
