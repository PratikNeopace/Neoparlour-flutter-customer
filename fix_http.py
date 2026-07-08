import os

files = [
    'lib/modules/pages/salon_details_screen.dart',
    'lib/modules/pages/nearby_saloons.dart',
    'lib/modules/pages/salon_id_screen.dart'
]

for file_path in files:
    with open(file_path, 'r') as f:
        content = f.read()

    # The URLs are mostly fetched via variables like `salon['imageUrl']`, `img['imageUrl']`, `heroImageUrl`
    # We can just search and replace `heroImageUrl` usage and `imageUrl:` usages if they aren't already wrapped.
    
    # Actually, a simpler way is to replace the extraction point or where `CachedNetworkImage` is used.
    # Let's replace `imageUrl: ` inside CachedNetworkImage with a `.toString().replaceFirst('http://', 'https://')`
    
    # Let's do a regex for `imageUrl:\s*([^,]+),` inside CachedNetworkImage
    import re
    
    def replacer(match):
        expr = match.group(1).strip()
        if 'replaceFirst' not in expr:
            return f"imageUrl: {expr}.toString().replaceFirst('http://', 'https://'),"
        return match.group(0)

    # We need to make sure we only match inside CachedNetworkImage.
    # A simpler global approach:
    # Look for all assignments of `heroImageUrl = ` and replace.
    content = re.sub(r"(final String heroImageUrl = [^;]+;)", r"\1\n    heroImageUrl = heroImageUrl.replaceFirst('http://', 'https://');", content)
    
    # Or just replace `imageUrl: <something>,` inside CachedNetworkImage
    # CachedNetworkImage(\s*imageUrl:\s*)([^,]+),
    content = re.sub(r"(CachedNetworkImage\([^)]*imageUrl:\s*)([^,]+)(,)", lambda m: m.group(1) + m.group(2) + ".toString().replaceFirst('http://', 'https://')" + m.group(3), content, flags=re.DOTALL)
    
    with open(file_path, 'w') as f:
        f.write(content)

print("Fixed")
