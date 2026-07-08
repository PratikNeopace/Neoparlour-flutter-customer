import os
import re

files_to_update = [
    "lib/modules/pages/appointment_booked_screen.dart",
    "lib/modules/pages/manual_date_time_screen.dart",
    "lib/modules/pages/notification_screen.dart",
    "lib/modules/pages/services_screen.dart",
    "lib/modules/pages/top_experts_screen.dart",
]

replacement = """final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final salonId = authProvider.salonId;
            if (salonId != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SalonDetailsScreen(salonId: salonId)),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SalonIDScreen()),
                (route) => false,
              );
            }"""

nav_push_remove = r"Navigator\.of\(context\)\.pushAndRemoveUntil\(\s*MaterialPageRoute\(builder:\s*\(context\)\s*=>\s*const\s*HomeScreen\(\)\),\s*\(route\)\s*=>\s*false,?\s*\)"

import_statement = "import 'package:provider/provider.dart';\nimport 'package:neo_parlour/provider/customer/auth_provider.dart';\nimport 'package:neo_parlour/modules/pages/salon_details_screen.dart';\nimport 'package:neo_parlour/modules/pages/salon_id_screen.dart';\n"

for file_path in files_to_update:
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content

        content = re.sub(nav_push_remove, replacement, content)

        if content != original_content:
            if "package:neo_parlour/modules/pages/salon_details_screen.dart" not in content:
                content = import_statement + content
            
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Updated {file_path}")
        else:
            print(f"No changes in {file_path}")
    else:
        print(f"File not found: {file_path}")
