import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Find the first `Widget _buildBestSellingPackages`
idx_pkg = content.find('Widget _buildBestSellingPackages')

# Find the start of `_BusySlotLinePainter`
idx_painter = content.find('/// Custom painter that draws a diagonal line across busy slot chips')
if idx_painter == -1:
    idx_painter = content.find('class _BusySlotLinePainter')

if idx_pkg != -1 and idx_painter != -1:
    # We want to replace everything between idx_pkg and idx_painter with a clean copy of the packages code.
    # And we also need to make sure we close the `_SalonDetailsScreenState` class properly right before the painter.
    
    # Read the clean package code
    with open('/tmp/packages_code_full.dart', 'r') as f:
        pkg_code = f.read()

    # The clean package code needs to be properly escaped for literal strings if we do any replacing, but since we are just appending strings it's fine.
    
    new_content = content[:idx_pkg] + pkg_code + "\n}\n\n" + content[idx_painter:]
    
    with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
        f.write(new_content)
    print("Cleaned!")
else:
    print("Could not find the sections!")
