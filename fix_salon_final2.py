import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Strip everything after 'bool shouldRepaint(covariant CustomPainter oldDelegate) => false;'
idx = content.find('bool shouldRepaint(covariant CustomPainter oldDelegate) => false;')
if idx != -1:
    idx += len('bool shouldRepaint(covariant CustomPainter oldDelegate) => false;')
    content = content[:idx] + '\n}\n'

# Now content ends with `class _BusySlotLinePainter` completed.
# We need to insert the packages code right BEFORE `class _BusySlotLinePainter {`
painter_idx = content.rfind('class _BusySlotLinePainter extends CustomPainter {')

with open('/tmp/packages_code_full.dart', 'r') as f:
    pkg_code = f.read()

# Replace any stray "\n" logic in pkg_code string interpolations
pkg_code = pkg_code.replace('"${package.name}\n${package.services.map((s) => s.name).join("\\n")}"', 
                           '"${package.name}\\n${package.services.map((s) => s.name).join(\\"\\\\n\\")}"')

if painter_idx != -1:
    # We find the closing brace of the state class which is right before painter_idx
    state_end_idx = content.rfind('}', 0, painter_idx)
    if state_end_idx != -1:
        content = content[:state_end_idx] + "\n" + pkg_code + "\n" + content[state_end_idx:]

with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)

print("Done")
