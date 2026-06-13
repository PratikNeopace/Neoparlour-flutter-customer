import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:neo_parlour/modules/pages/home_screen.dart';
import 'package:neo_parlour/widgets/custom_nav_bar.dart';
import '../../provider/customer/cart_provider.dart';
import '../../core/domain/models/cart_item.dart';
import '../../widgets/premium_image.dart';

class AddToCartScreen extends StatefulWidget {
  const AddToCartScreen({super.key});

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  final double deliveryCharge = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
        backgroundColor: Colors.red,
        shape: const CircleBorder(),
        child: SvgPicture.asset(
          "assets/Images/BottomNavigationBar/home_icon.svg",
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.cartItems.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final cartItems = cartProvider.cartItems;
          final isCartEmpty = cartItems.isEmpty;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => cartProvider.fetchCart(),
                color: Colors.red,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ================= HEADER WITH CUSTOM CLIPPER =================
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipPath(
                            clipper: HeaderCurveClipper(),
                            child: Container(
                              height: 225,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    "assets/Images/AddToCartScreen/background_add_to_cart.jpg",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.1),
                                      Colors.transparent,
                                      const Color(0XFFFF3502).withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Back Button
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
                          // Title
                          const Positioned(
                            bottom: 60,
                            left: 30,
                            child: Text(
                              "CART",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Clear Cart Button
                          if (!isCartEmpty)
                            Positioned(
                              bottom: -5,
                              right: 22,
                              child: GestureDetector(
                                onTap: () async {
                                  final success = await cartProvider.clearCart();
                                  if (!context.mounted) return;
                                  if (success) {
                                    FlushbarHelper.show(context, "Cart cleared", isSuccess: true);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                                  ),
                                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      isCartEmpty 
                        ? Container(
                            height: 400,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 20),
                                const Text("Your cart is empty", style: TextStyle(color: Colors.grey, fontSize: 18)),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Go Back", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // ================= CART ITEMS LIST =================
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cartItems.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                                  itemBuilder: (context, index) => _buildCartItem(cartItems[index]),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ================= SUMMARY SECTION =================
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                child: Column(
                                  children: [
                                    _summaryRow("Subtotal", "₹${cartProvider.subtotal.toInt()}"),
                                    const SizedBox(height: 12),
                                    _summaryRow("Delivery", "₹${deliveryCharge.toInt()}"),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(thickness: 1, color: Colors.grey),
                                    ),
                                    _summaryRow(
                                      "Total",
                                      "₹${(cartProvider.subtotal + deliveryCharge).toInt()}",
                                      isTotal: true,
                                    ),
                                    const SizedBox(height: 30),

                                    // Proceed to Checkout Button
                                    if (!isCartEmpty)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 55,
                                        child: ElevatedButton(
                                          onPressed: cartProvider.isLoading ? null : () async {
                                            final success = await cartProvider.checkout();
                                            if (!context.mounted) return;
                                            if (success) {
                                              _showClaimDialog(context);
                                            } else {
                                              FlushbarHelper.show(context, "Failed to place order");
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 5,
                                          ),
                                          child: cartProvider.isLoading 
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text("PROCEED TO CHECKOUT",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ),
                                    const SizedBox(height: 200), // Space for bottom navigation bar
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Row( 
            children: [
              Icon(Icons.store, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Order Confirmed",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const Text(
            "🎉 Your order has been successfully placed!\n\n"
            "Please visit the salon to claim your products.\n"
            "Show your booking confirmation at the counter.\n\n"
            "Thank you for shopping with Neo Parlour ❤️",
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Product Image
          PremiumImageWidget(
            imageUrl: item.productImageUrl ?? item.productImageBase64,
            width: 60,
            height: 80,
            borderRadius: BorderRadius.circular(8),
            fallbackWidget: Image.asset(
              "assets/Images/AddToCartScreen/product_one.jpg",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 15),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<CartProvider>().removeFromCart(item.productId),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹ ${item.price.toInt()}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    // Quantity Control
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _qtyIcon(Icons.remove, () {
                            final cartProvider = context.read<CartProvider>();
                            if (cartProvider.isLoading) return;
                            if (item.quantity > 1) {
                              cartProvider.addToCart(item.productId, -1);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _qtyIcon(Icons.add, () {
                            final cartProvider = context.read<CartProvider>();
                            if (cartProvider.isLoading) return;
                            cartProvider.addToCart(item.productId, 1);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.w400),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isTotal ? Colors.red : Colors.black),
        ),
      ],
    );
  }
}

// ================= CLIPPER =================

class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.55, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}