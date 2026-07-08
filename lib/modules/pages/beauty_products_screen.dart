import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/modules/pages/salon_details_screen.dart';
import 'package:neo_parlour/modules/pages/salon_id_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../provider/customer/product_provider.dart';
import '../../core/domain/models/product.dart';
import '../../widgets/custom_nav_bar.dart';
import '../../widgets/premium_image.dart';
import 'product_details_screen.dart';
import 'add_to_cart.dart';

class BeautyProductsScreen extends StatefulWidget {
  const BeautyProductsScreen({super.key});

  @override
  State<BeautyProductsScreen> createState() => _BeautyProductsScreenState();
}

class _BeautyProductsScreenState extends State<BeautyProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchGroupedProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().fetchGroupedProducts(refresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final scale = sw / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
            }
        },
        backgroundColor: Colors.red,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          "assets/Images/BottomNavigationBar/home_icon.svg",
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(scale),
                SizedBox(height: 24 * scale),
                Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF0B01),
                          ),
                        ),
                      );
                    }

                    if (provider.groupedProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0 * scale),
                          child: Text(
                            "No products found",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...provider.groupedProducts.entries.map((entry) {
                          return CategorySectionWidget(
                            category: entry.key,
                            products: entry.value,
                            scale: scale,
                          );
                        }),
                        if (provider.isLoadingMoreGrouped)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF0B01),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 100 * scale), // Space for nav bar
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildHeader(double scale) {
    return Stack(
      children: [
        Container(
          width: 375 * scale,
          height: 225 * scale,
          decoration: const BoxDecoration(
            color: Color(0xFFFF0B01),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(150)),
            image: DecorationImage(
              image: AssetImage(
                "assets/Images/SelectProfessionalScreen/select_professional_background_img.jpeg",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          width: 375 * scale,
          height: 225 * scale,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(150),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                const Color(0xFFFF0B01).withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              child: const Icon(Icons.chevron_left, color: Colors.black),
            ),
          ),
        ),

        // Floating Cart Icon on the curve
        Positioned(
          bottom: 20,
          right: 30,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddToCartScreen()),
              );
            },
            child: Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 28)
            ),
          ),
        ),
      ],
    );
  }

}

class CategorySectionWidget extends StatefulWidget {
  final String category;
  final List<Product> products;
  final double scale;

  const CategorySectionWidget({
    super.key,
    required this.category,
    required this.products,
    required this.scale,
  });

  @override
  State<CategorySectionWidget> createState() => _CategorySectionWidgetState();
}

class _CategorySectionWidgetState extends State<CategorySectionWidget> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_horizontalScrollController.position.pixels >=
        _horizontalScrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().fetchMoreProductsForCategory(widget.category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isLoadingMore = provider.getCategoryLoadingMore(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * widget.scale,
            vertical: 16 * widget.scale,
          ),
          child: Text(
            "${widget.category.toUpperCase()} PRODUCTS",
            style: GoogleFonts.poppins(
              fontSize: 15 * widget.scale,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(
          height: 320 * widget.scale,
          child: ListView.builder(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 24 * widget.scale),
            itemCount: widget.products.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < widget.products.length) {
                return _buildProductCard(widget.products[index], widget.scale);
              } else {
                return _buildHorizontalLoader(widget.scale);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLoader(double scale) {
    return Container(
      width: 137 * scale,
      margin: EdgeInsets.only(right: 16 * scale),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Color(0xFFFF0B01),
      ),
    );
  }

  Widget _buildProductCard(Product product, double scale) {
    return Container(
      width: 137 * scale,
      margin: EdgeInsets.only(right: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 137 * scale,
            height: 165 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFFF0B01).withValues(alpha: 0.7),
                  const Color(0xFFFFEEED).withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: PremiumImageWidget(
              imageUrl: product.imageUrl ?? product.imageBase64,
              width: 137 * scale,
              height: 165 * scale,
              borderRadius: BorderRadius.circular(16 * scale),
              fallbackWidget: Image.asset(
                "assets/Images/TopExpertsScreen/staff_placeholder.jpeg",
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹ ${product.price.toInt()}",
                style: GoogleFonts.poppins(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              Text(
                "100ml",
                style: GoogleFonts.poppins(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(productId: product.id),
                ),
              );
            },
            child: Container(
              width: 137 * scale,
              height: 27 * scale,
              decoration: BoxDecoration(
                color: product.stock == 0 ? Colors.grey : const Color(0xFFFF0B01),
                borderRadius: BorderRadius.circular(9 * scale),
              ),
              alignment: Alignment.center,
              child: Text(
                product.stock == 0 ? "Out of stock" : "Show Details",
                style: GoogleFonts.poppins(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}