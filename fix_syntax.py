import os

files_to_update = [
    "lib/modules/pages/appointment_booked_screen.dart",
    "lib/modules/pages/manual_date_time_screen.dart",
    "lib/modules/pages/notification_screen.dart",
    "lib/modules/pages/services_screen.dart",
    "lib/modules/pages/top_experts_screen.dart",
]

bad_str = "() => final authProvider = Provider.of<AuthProvider>(context, listen: false);"
good_str = "() {\n              final authProvider = Provider.of<AuthProvider>(context, listen: false);"

bad_end = """              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SalonIDScreen()),
                (route) => false,
              );
            }"""

good_end = """              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SalonIDScreen()),
                (route) => false,
              );
            }\n            }"""

for file_path in files_to_update:
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            content = f.read()
        
        if bad_str in content:
            content = content.replace(bad_str, good_str)
            content = content.replace(bad_end, good_end)
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed {file_path}")
        else:
            print(f"No error found in {file_path}")
