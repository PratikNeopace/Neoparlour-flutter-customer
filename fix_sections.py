import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Change all `const SizedBox(height: 24)` inside the main sections to 8
# Wait, let's just do a string replacement for the specific ones.
# Or better, we can write a Python script that uses `re.sub` carefully.

# Let's see the exact text for Offers section
