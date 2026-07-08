import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Add imports if not present
if "package_provider.dart" not in content:
    imports = """
import '../../provider/customer/package_provider.dart';
import '../../core/domain/models/package_model.dart';
"""
    content = re.sub(r"(import 'package:provider/provider.dart';)", r"\1\n" + imports.strip(), content)

# Add fetchPackages to initState if not present
if "context.read<PackageProvider>().fetchPackages();" not in content:
    content = re.sub(
        r"(context\.read<StaffProvider>\(\)\.fetchStaff\(\);\n\s*}\);)",
        r"\1\n    Future.microtask(() {\n      if (mounted) {\n        context.read<PackageProvider>().fetchPackages();\n      }\n    });",
        content
    )

# Add the package methods at the end of the state class if not present
if "_buildBestSellingPackages" not in content:
    with open('/tmp/packages_code.dart', 'r') as f:
        pkg_code = f.read()
    
    # Need to find the end of the _SalonDetailsScreenState class
    # We can match the end of the file or the last closing brace
    content = re.sub(r"}\s*$", f"\n{pkg_code}\n}}", content)

# Insert the UI section after slots and before photos if not present
if "BEST SELLING PACKAGES" not in content:
    # Use re.sub to inject the UI code between the end of Slots and the beginning of Photos
    # Look for the space between slots and photos
    target = r"(const SizedBox\(height: 24\);\n\n\s+if \(photosList\.isNotEmpty\))"
    
    ui_code = """
                  // ================= BEST SELLING PACKAGES SECTION =================
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
                          onTap: () {
                            // Navigate to package list if needed
                          },
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
                  
                  // Use LayoutBuilder to get width
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double sw = MediaQuery.of(context).size.width;
                      double scale = sw / 375.0; // scale reference
                      return _buildBestSellingPackages(sw, scale);
                    }
                  ),
                  const SizedBox(height: 24),
"""
    content = re.sub(target, ui_code.replace('\\', '\\\\') + r"\1", content)

with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)
print("Done")
