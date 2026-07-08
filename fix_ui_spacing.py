import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# 1. Update OFFERS section to be fully wrapped and have 8px padding
offers_pattern = r"(const SizedBox\(height: 24\);\s*// ================= OFFERS SECTION =================.*?)(?=\s*// ================= AVAILABLE SLOTS)"
offers_match = re.search(offers_pattern, content, flags=re.DOTALL)
if offers_match:
    offers_block = offers_match.group(1)
    # We want to replace `const SizedBox(height: 24);` with `if (_offers.isNotEmpty) const SizedBox(height: 8),`
    # and wrap the whole block (except the `const SizedBox(height: 24);`) in `if (_offers.isNotEmpty) ...[` and `],`
    
    # Actually, simpler:
    new_offers_block = offers_block.replace("const SizedBox(height: 24);", "if (_offers.isNotEmpty) const SizedBox(height: 8),")
    new_offers_block = new_offers_block.replace("if (_offers.isNotEmpty)\n                          GestureDetector", "GestureDetector")
    # Wait, the `if (_offers.isNotEmpty)` is currently inside the Row for "See More". If we hide the whole section, we don't need it.
    
    # Wrap the padding and list view in `if (_offers.isNotEmpty) ...[`
    new_offers_block = re.sub(
        r"(// ================= OFFERS SECTION =================\s*)(Padding)",
        r"\1if (_offers.isNotEmpty) ...[\n                  \2",
        new_offers_block
    )
    new_offers_block = new_offers_block.rstrip() + "\n                  ],\n"
    content = content.replace(offers_block, new_offers_block + "\n")

# 2. Update PACKAGES section to move title into _buildBestSellingPackages and fix spacing
packages_pattern = r"(// ================= BEST SELLING PACKAGES SECTION =================.*?)(?=\s*if \(photosList\.isNotEmpty\))"
packages_match = re.search(packages_pattern, content, flags=re.DOTALL)
if packages_match:
    packages_block = packages_match.group(1)
    
    # We remove the title and spacing from the main build method
    # and just leave the LayoutBuilder
    new_packages_block = """// ================= BEST SELLING PACKAGES SECTION =================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double sw = MediaQuery.of(context).size.width;
                      double scale = sw / 375.0; // scale reference
                      return _buildBestSellingPackages(sw, scale);
                    }
                  ),
"""
    content = content.replace(packages_block, new_packages_block)

# Now update _buildBestSellingPackages to include the title and 8px spacing
build_packages_pattern = r"(Widget _buildBestSellingPackages\(double sw, double scale\) \{.*?)(?=\s*Widget _packageCard)"
build_packages_match = re.search(build_packages_pattern, content, flags=re.DOTALL)
if build_packages_match:
    bp_block = build_packages_match.group(1)
    
    # We want to replace the `return Consumer...` with one that returns a Column containing the title + list, OR SizedBox.shrink()
    
    new_bp_block = """Widget _buildBestSellingPackages(double sw, double scale) {
    return Consumer<PackageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0XFFFF0B01)),
          );
        }

        final packages = provider.packages;
        if (packages.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PACKAGES",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "See More",
                      style: GoogleFonts.poppins(
                        color: const Color(0XFFFF0B01),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160 * scale,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  return _packageCard(packages[index], scale);
                },
              ),
            ),
          ],
        );
      },
    );
  }
"""
    content = content.replace(bp_block, new_bp_block)

# 3. Fix other spacing: 24 -> 8
content = content.replace('const SizedBox(height: 24),', 'const SizedBox(height: 8),')

with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)

print("Fixed spacing and logic")
