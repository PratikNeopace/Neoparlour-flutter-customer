import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Wrap Offers
offers_pattern = r"(// ================= OFFERS SECTION =================.*?)(?=\s*const SizedBox\(height: 8\);\s*// ================= AVAILABLE SLOTS TODAY)"
offers_match = re.search(offers_pattern, content, flags=re.DOTALL)
if offers_match:
    offers_block = offers_match.group(1)
    
    # We want to replace the `_offers.isNotEmpty ? ... : const SizedBox.shrink(),` 
    # Let's extract the block and wrap it manually
    
    # Actually, simpler way: Let's just find the `Padding` for "OFFER AVAILABLE FOR YOU" and wrap it
    
    new_offers_block = "if (_offers.isNotEmpty) ...[\n" + offers_block.replace("\n                  _offers.isNotEmpty\n                      ? SizedBox(", "\n                  SizedBox(").replace(" : const SizedBox.shrink(),", "") + "\n                  ],"
    
    content = content.replace(offers_block, new_offers_block)
    
with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)

print("Fixed offers")
