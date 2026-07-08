import re

file_path = "lib/modules/pages/salon_details_screen.dart"
with open(file_path, "r") as f:
    content = f.read()

# Pattern to find all the sections and what comes before/after
# We'll split the content using the section markers.

marker_offers = r"(\s*// ================= OFFERS SECTION =================\s*)"
marker_services = r"(\s*// ================= SERVICES SECTION =================\s*)"
marker_photos = r"(\s*if \(photosList\.isNotEmpty\) \.\.\.\[\s*)"
marker_opening = r"(\s*// ================= OPENING TIMES SECTION =================\s*)"
marker_slots = r"(\s*// ================= SLOTS AVAILABILITY SECTION =================\s*)"
marker_about = r"(\s*// ================= ABOUT US SECTION =================\s*)"
marker_specialist = r"(\s*// ================= TOP SPECIALIST SECTION =================\s*)"
marker_end = r"(\s*SizedBox\(height: 35 \+ mq\.padding\.bottom\),\s*)"

def get_section(start_marker, end_marker):
    pattern = start_marker + r"(.*?)" + end_marker
    match = re.search(pattern, content, re.DOTALL)
    if match:
        return match.group(1) + match.group(2) # marker + content
    return ""

def get_content_until(start_marker):
    pattern = r"^(.*?)" + start_marker
    match = re.search(pattern, content, re.DOTALL)
    if match:
        return match.group(1)
    return ""

def get_content_after(start_marker):
    pattern = start_marker + r"(.*)$"
    match = re.search(pattern, content, re.DOTALL)
    if match:
        return match.group(2)
    return ""

pre_content = get_content_until(marker_offers)
offers_sec = get_section(marker_offers, marker_services)
services_sec = get_section(marker_services, marker_photos)
photos_sec = get_section(marker_photos, marker_opening)
opening_sec = get_section(marker_opening, marker_slots)
slots_sec = get_section(marker_slots, marker_about)
about_sec = get_section(marker_about, marker_specialist)
specialist_sec = get_section(marker_specialist, marker_end)
post_content = get_content_after(marker_end)
end_marker_str = re.search(marker_end, content, re.DOTALL).group(1)

# Validation
print(f"pre_content length: {len(pre_content)}")
print(f"offers length: {len(offers_sec)}")
print(f"services length: {len(services_sec)}")
print(f"photos length: {len(photos_sec)}")
print(f"opening length: {len(opening_sec)}")
print(f"slots length: {len(slots_sec)}")
print(f"about length: {len(about_sec)}")
print(f"specialist length: {len(specialist_sec)}")

# New Order:
# 1. SERVICES
# 2. TOP SPECIALIST
# 3. OFFERS
# 4. PHOTOS
# 5. OPENING TIMES
# 6. SLOTS AVAILABILITY
# (Remove ABOUT US)

# Wait, the user said: "instead of "Offers" coming first we take "Services" then we take "Top Specialist" then "Offers" and remove "About Us""
# Does this mean Photos, Opening Times, Slots Availability stay where they were relative to Offers? Or do they come after the big 3?
# The original order was: Offers, Services, Photos, Opening, Slots, About, Specialist
# So if we move Services, Specialist, Offers to the top, then the rest stay below.
# New order: SERVICES, TOP SPECIALIST, OFFERS, PHOTOS, OPENING TIMES, SLOTS AVAILABILITY

new_content = (
    pre_content +
    services_sec +
    specialist_sec +
    offers_sec +
    photos_sec +
    opening_sec +
    slots_sec +
    end_marker_str +
    post_content
)

with open(file_path, "w") as f:
    f.write(new_content)

print("Done reordering")
