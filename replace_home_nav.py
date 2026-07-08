import os
import re

files_to_update = [
    "lib/modules/pages/add_to_cart.dart",
    "lib/modules/pages/appointment_booked_screen.dart",
    "lib/modules/pages/beauty_products_screen.dart",
    "lib/modules/pages/manual_date_time_screen.dart",
    "lib/modules/pages/notification_screen.dart",
    "lib/modules/pages/product_details_screen.dart",
    "lib/modules/pages/services_screen.dart",
    "lib/modules/pages/splash_screen.dart",
    "lib/modules/pages/tnc_acceptance_screen.dart",
    "lib/modules/pages/top_experts_screen.dart",
    "lib/widgets/custom_nav_bar.dart"
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

nav_push_remove = r"Navigator\.pushAndRemoveUntil\(\s*context,\s*MaterialPageRoute\(builder:\s*\(context\)\s*=>\s*const\s*HomeScreen\(\)\),\s*\(route\)\s*=>\s*false,\s*\);"

nav_push_replace = r"Navigator\.pushReplacement\(\s*context,\s*MaterialPageRoute\(builder:\s*\(context\)\s*=>\s*const\s*HomeScreen\(\)\),?\s*\);"

nav_push = r"Navigator\.push\(\s*context,\s*MaterialPageRoute\(builder:\s*\(context\)\s*=>\s*const\s*HomeScreen\(\)\),?\s*\);"

import_statement = "import 'package:provider/provider.dart';\nimport 'package:neo_parlour/provider/customer/auth_provider.dart';\nimport 'package:neo_parlour/modules/pages/salon_details_screen.dart';\nimport 'package:neo_parlour/modules/pages/salon_id_screen.dart';\n"

for file_path in files_to_update:
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            content = f.read()
        
        updated = False
        
        # We need to make sure Provider and AuthProvider are imported.
        if "AuthProvider" not in content and "SalonDetailsScreen" not in content:
            # naive insert at top
            pass # handled manually below for robustness

        original_content = content

        content = re.sub(nav_push_remove, replacement, content)
        content = re.sub(nav_push_replace, replacement, content)
        content = re.sub(nav_push, replacement, content)

        if content != original_content:
            # Needs imports
            if "package:neo_parlour/modules/pages/salon_details_screen.dart" not in content:
                content = import_statement + content
            
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Updated {file_path}")
        else:
            print(f"No changes in {file_path}")
    else:
        print(f"File not found: {file_path}")
