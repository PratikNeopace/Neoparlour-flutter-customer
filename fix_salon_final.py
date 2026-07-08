import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# First, remove everything from 'Widget _buildBestSellingPackages' to the end of the file
# BUT WAIT, we might have inserted it multiple times or randomly.
# Let's locate the last correct closing brace of the file.
# The file ends with the `_BusySlotLinePainter` class.
painter_start = content.find('class _BusySlotLinePainter')
if painter_start != -1:
    # Find the end of the _BusySlotLinePainter class
    brace_count = 0
    in_class = False
    class_end = -1
    for i in range(painter_start, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_class = True
        elif content[i] == '}':
            brace_count -= 1
            if in_class and brace_count == 0:
                class_end = i
                break
    
    if class_end != -1:
        # Keep everything up to the end of the painter class
        content = content[:class_end + 1] + "\n"

# Now, we need to insert `_buildBestSellingPackages` and `_packageCard` inside the `_SalonDetailsScreenState` class.
# The state class is `class _SalonDetailsScreenState extends State<SalonDetailsScreen>`.
# It ends right before `class _BusySlotLinePainter`.
# Let's find the closing brace of the state class.
state_class_end = content.rfind('}', 0, painter_start)

with open('/tmp/packages_code_full.dart', 'r') as f:
    pkg_code = f.read()

if state_class_end != -1:
    content = content[:state_class_end] + "\n" + pkg_code + "\n" + content[state_class_end:]

with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)

print("Done")
