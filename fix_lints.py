import os
import re

# Fix home_screen.dart
with open("lib/modules/pages/home_screen.dart", "r") as f:
    content = f.read()

content = content.replace("final authProv = context.read<AuthProvider>();", "if (!mounted) return;\n    final authProv = context.read<AuthProvider>();")
with open("lib/modules/pages/home_screen.dart", "w") as f:
    f.write(content)


# Fix neabySaloons.dart
with open("lib/modules/pages/neabySaloons.dart", "r") as f:
    content = f.read()

old_str = """      if (salonId != null) {
        Navigator.pop(context); // Close the location picker modal
        _onSalonTap({'id': salonId.toString(), 'name': salonName});"""
new_str = """      if (salonId != null) {
        if (!mounted) return;
        Navigator.pop(context); // Close the location picker modal
        _onSalonTap({'id': salonId.toString(), 'name': salonName});"""

content = content.replace(old_str, new_str)
with open("lib/modules/pages/neabySaloons.dart", "w") as f:
    f.write(content)

# Rename neabySaloons.dart to nearby_saloons.dart
os.rename("lib/modules/pages/neabySaloons.dart", "lib/modules/pages/nearby_saloons.dart")

# Fix imports in salon_id_screen.dart
with open("lib/modules/pages/salon_id_screen.dart", "r") as f:
    content = f.read()
content = content.replace("neabySaloons.dart", "nearby_saloons.dart")
with open("lib/modules/pages/salon_id_screen.dart", "w") as f:
    f.write(content)
