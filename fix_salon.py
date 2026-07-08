import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Remove the broken _buildBestSellingPackages at the end of the file
# It starts around Widget _buildBestSellingPackages(double sw, double scale) {
content = re.sub(r"\s+Widget _buildBestSellingPackages.*?$", "", content, flags=re.DOTALL)

with open('/tmp/packages_code_full.dart', 'r') as f:
    pkg_code = f.read()

# Insert the pkg_code before class _BusySlotLinePainter
content = content.replace("class _BusySlotLinePainter", f"{pkg_code}\n\nclass _BusySlotLinePainter")

# Since we stripped the end of the file which might have included the closing brace of the file or something else after the painter... wait!
# If I stripped from `Widget _buildBestSellingPackages` to the end of the file, I also stripped `class _BusySlotLinePainter` if it was AFTER it.
# Let's check if the broken code was before or after `class _BusySlotLinePainter`.
