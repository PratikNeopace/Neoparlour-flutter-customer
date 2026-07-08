import re

file_path = "lib/modules/pages/salon_details_screen.dart"
with open(file_path, "r") as f:
    content = f.read()

# Marker definitions
marker_services = r"(\s*// ================= SERVICES SECTION =================\s*)"
marker_specialist = r"(\s*// ================= TOP SPECIALIST SECTION =================\s*)"
marker_offers = r"(\s*// ================= OFFERS SECTION =================\s*)"
marker_photos = r"(\s*if \(photosList\.isNotEmpty\) \.\.\.\[\s*)"
marker_opening = r"(\s*// ================= OPENING TIMES SECTION =================\s*)"
marker_slots = r"(\s*// ================= SLOTS AVAILABILITY SECTION =================\s*)"
marker_end = r"(\s*SizedBox\(height: 35 \+ mq\.padding\.bottom\),\s*)"

def get_content_until(start_marker):
    pattern = r"^(.*?)" + start_marker
    match = re.search(pattern, content, re.DOTALL)
    if match: return match.group(1)
    return ""

def get_section(start_marker, end_marker):
    pattern = start_marker + r"(.*?)" + end_marker
    match = re.search(pattern, content, re.DOTALL)
    if match: return match.group(1) + match.group(2)
    return ""

def get_content_after(start_marker):
    pattern = start_marker + r"(.*)$"
    match = re.search(pattern, content, re.DOTALL)
    if match: return match.group(2)
    return ""

pre_content = get_content_until(marker_services)
services_sec = get_section(marker_services, marker_specialist)
specialist_sec = get_section(marker_specialist, marker_offers)
offers_sec = get_section(marker_offers, marker_photos)
photos_sec = get_section(marker_photos, marker_opening)
opening_sec = get_section(marker_opening, marker_slots)
slots_sec = get_section(marker_slots, marker_end)
end_marker_str = re.search(marker_end, content, re.DOTALL).group(1)
post_content = get_content_after(marker_end)

# Validation
print(f"pre_content length: {len(pre_content)}")
print(f"services length: {len(services_sec)}")
print(f"specialist length: {len(specialist_sec)}")
print(f"offers length: {len(offers_sec)}")
print(f"photos length: {len(photos_sec)}")
print(f"opening length: {len(opening_sec)}")
print(f"slots length: {len(slots_sec)}")

# New Order:
# 1. Services
# 2. Top Specialist
# 3. Offers
# 4. Slots Availability
# 5. Photos
# 6. Opening Times

new_content = (
    pre_content +
    services_sec +
    specialist_sec +
    offers_sec +
    slots_sec +
    photos_sec +
    opening_sec +
    end_marker_str +
    post_content
)

with open(file_path, "w") as f:
    f.write(new_content)

print("Done reordering")
