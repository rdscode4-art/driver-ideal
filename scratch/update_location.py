import os
import re

file_path = r'd:\flutter projects\rideal_driver4\lib\controllers\ongoing_ride_controller.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Using regex to catch any indentation
pattern = r"const LocationSettings locationSettings = LocationSettings\(\s*accuracy: LocationAccuracy\.high,\s*distanceFilter: 3,.*?Removed timeLimit.*?\);"
replacement = r"""const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // Update continuously without waiting for distance
    );"""

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
