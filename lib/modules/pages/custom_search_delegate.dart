import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/domain/models/neo_service.dart';
import '../../provider/customer/service_provider.dart';
import '../../provider/customer/staff_provider.dart';
import '../../provider/customer/offer_provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../provider/customer/package_provider.dart';
import '../../provider/customer/booking_provider.dart';
import 'select_date_time_screen.dart';
import 'product_details_screen.dart';
import 'select_services_screen.dart';

import '../../widgets/staff_image_widgets.dart';
import '../../widgets/premium_image.dart';

class CustomSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search services, experts, products...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.black),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Search for something...',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final serviceProvider = context.read<ServiceProvider>();
    final staffProvider = context.read<StaffProvider>();
    final offerProvider = context.read<OfferProvider>();
    final productProvider = context.read<ProductProvider>();
    final packageProvider = context.read<PackageProvider>();

    final services = serviceProvider.services
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final staff = staffProvider.staffList
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final offers = offerProvider.offers
        .where((o) => o.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final products = productProvider.products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final packages = packageProvider.packages
        .where((pk) => pk.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (services.isEmpty &&
        staff.isEmpty &&
        offers.isEmpty &&
        products.isEmpty &&
        packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (services.isNotEmpty) ...[
            _buildCategoryHeader('SERVICES'),
            ...services.map((s) => _buildResultItem(
                  context,
                  title: s.name,
                  subtitle: 'Starting from \$${s.price}',
                  leading: _buildServiceLeading(s),
                  onTap: () {
                    final bookingProvider = context.read<BookingProvider>();
                    staffProvider.resetStaffState();
                    bookingProvider.setPreSelectedStaff(null);
                    serviceProvider.preselectServices([s.id]);
                    bookingProvider.applyOffer(null);
                    bookingProvider.setSelectedPackage(null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()),
                    );
                  },
                )),
          ],
          if (staff.isNotEmpty) ...[
            _buildCategoryHeader('TOP SPECIALISTS'),
            ...staff.map((st) => _buildResultItem(
                  context,
                  title: st.name,
                  subtitle: st.staffStatus,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: StaffAvatar(
                        imageAsBase64: st.imageAsBase64,
                        imageUrl: st.image,
                        gender: st.gender,
                        borderRadius: 8,
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),
                  onTap: () {
                    final bookingProvider = context.read<BookingProvider>();
                    staffProvider.selectStaff(st);
                    bookingProvider.applyOffer(null);
                    bookingProvider.setSelectedPackage(null);
                    bookingProvider.setPreSelectedStaff(st.id, durationMinutes: 45);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectDateTimeScreen()),
                    );
                  },
                )),
          ],
          if (products.isNotEmpty) ...[
            _buildCategoryHeader('POPULAR PRODUCTS'),
            ...products.map((p) => _buildResultItem(
                  context,
                  title: p.name,
                  subtitle: '\$${p.price}',
                  leading: PremiumImageWidget(
                    imageUrl: p.imageUrl ?? p.imageBase64,
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(8),
                    fallbackWidget: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailsScreen(productId: p.id)),
                    );
                  },
                )),
          ],
          if (offers.isNotEmpty) ...[
            _buildCategoryHeader('OFFERS'),
            ...offers.map((o) => _buildResultItem(
                  context,
                  title: o.name,
                  subtitle: o.description,
                  leading: _buildIconLeading(Icons.local_offer_outlined),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectServicesScreen(initialCategory: "Offers"),
                      ),
                    );
                  },
                )),
          ],
          if (packages.isNotEmpty) ...[
            _buildCategoryHeader('BEST SELLING PACKAGES'),
            ...packages.map((pk) => _buildResultItem(
                  context,
                  title: pk.name,
                  subtitle: 'Package Price: \$${pk.packagePrice}',
                  leading: _buildIconLeading(Icons.inventory_2_outlined),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectServicesScreen(initialCategory: "Best Selling Packages"),
                      ),
                    );
                  },
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFF3502),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: leading,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildServiceLeading(NeoService s) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBE6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.spa_outlined, color: Color(0xFFFF3502), size: 24),
    );
  }

  Widget _buildIconLeading(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.grey[700], size: 24),
    );
  }
}
