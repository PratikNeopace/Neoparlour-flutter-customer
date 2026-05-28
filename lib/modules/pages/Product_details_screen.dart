import 'package:flutter/material.dart';
import '../../core/utils/flushbar_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../provider/customer/product_provider.dart';
import '../../provider/customer/cart_provider.dart';
import '../../widgets/custom_nav_bar.dart';
import 'dart:convert';
import 'add_to_cart.dart';
import 'home_screen.dart';
import '../../provider/customer/auth_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;
  String selectedSize = "50ml";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProductById(widget.productId);
    });
  }

  void _showOrderConfirmedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
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
            "🎉 Your order has been placed successfully!\n\n"
            "Please visit the salon to claim your product. Show your booking confirmation at the counter.\n\n"
            "Thank you for shopping with Neo Parlour ❤️",
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final product = provider.selectedProduct;
          if (product == null) {
            return const Center(child: Text("Product not found"));
          }

          return Stack(
            children: [
              SingleChildScrollView(
                key: const PageStorageKey('product_details_scroll'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER IMAGE SECTION =================
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipPath(
                          clipper: ProductDetailsHeaderClipper(),
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: product.imageBase64 != null
                                  ? DecorationImage(
                                      image: MemoryImage(base64Decode(product.imageBase64!)),
                                      fit: BoxFit.cover,
                                    )
                                  : const DecorationImage(
                                      image: AssetImage("assets/Images/AddToCartScreen/background_add_to_cart.jpg"),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.1),
                                    Colors.transparent,
                                    const Color(0XFFFF3502).withOpacity(0.6),
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
                              backgroundColor: Colors.white.withOpacity(0.8),
                              child: const Icon(Icons.chevron_left, color: Colors.black),
                            ),
                          ),
                        ),
                        // Thumbnails
                        Positioned(
                          bottom: -15,
                          left: 20,
                          child: Row(
                            children: [
                              if (product.imageBase64 != null)
                                _buildThumbnailFromBase64(product.imageBase64!),
                              ...product.additionalImagesBase64.take(2).map((img) => _buildThumbnailFromBase64(img)),
                            ],
                          ),
                        ),
                        // Floating Cart Button - Navigate to Cart Screen
                        Positioned(
                          bottom: -5,
                          right: 22,
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
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                              ),
                              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ================= PRODUCT INFO SECTION =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name.toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text("₹ ${product.discountPrice.toInt()}",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 10),
                              if (product.price > product.discountPrice)
                                Text("₹ ${product.price.toInt()}",
                                    style: const TextStyle(fontSize: 16, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                              const Spacer(),
                              _buildQuantitySelector(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                            ],
                          ),
                          const SizedBox(height: 25),

                          const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            product.description,
                            style: const TextStyle(color: Colors.black87, height: 1.5),
                          ),

                          const SizedBox(height: 30),

                          // Action Buttons (Add to Cart & Buy Now)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      // Add to Cart Button
                                      Expanded(
                                        child: SizedBox(
                                          height: 55,
                                          child: OutlinedButton(
                                            onPressed: cartProvider.isLoading ? null : () async {
                                              final success = await cartProvider.addToCart(product.id, quantity);
                                              if (success) {                                                FlushbarHelper.show(context, "Added to cart successfully");

                                              } else {                                                FlushbarHelper.show(context, "Failed to add to cart");

                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red, width: 2),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: cartProvider.isLoading 
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                                              : const Text("ADD TO CART",
                                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Buy Now Button
                                      Expanded(
                                        child: SizedBox(
                                          height: 55,
                                          child: ElevatedButton(
                                            onPressed: cartProvider.isLoading ? null : () async {
                                              final authProvider = context.read<AuthProvider>();
                                              final customerId = authProvider.userId ?? 1;
                                              
                                              final success = await cartProvider.placeOrder(
                                                customerId: customerId,
                                                salonId: product.salonId,
                                                totalAmount: product.discountPrice * quantity,
                                                items: [
                                                  {
                                                    "productId": product.id,
                                                    "productName": product.name,
                                                    "quantity": quantity,
                                                    "price": product.discountPrice,
                                                  }
                                                ],
                                              );
                                              if (success) {
                                                _showOrderConfirmedDialog(context);
                                              } else {                                                FlushbarHelper.show(context, "Failed to process Buy Now");

                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 5,
                                            ),
                                            child: cartProvider.isLoading 
                                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Text("BUY NOW",
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const AddToCartScreen()),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shopping_cart_outlined, color: Colors.grey.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            "VIEW CART",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 200), // Space for bottom navigation bar visibility
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnailFromBase64(String base64) {
    return Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(6),
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Image.memory(base64Decode(base64), fit: BoxFit.contain)
    );
  }

  Widget _buildThumbnail(String path) {
    return Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(6),
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Image.asset("assets/Images/AddToCartScreen/product_one.jpg",fit: BoxFit.contain)
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (quantity > 1) {
                setState(() {
                  quantity--;
                });
              }
            },
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () {
              setState(() {
                quantity++;
              });
            },
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

//   Widget _buildSizeOption(String size) {
//     bool isSelected = selectedSize == size;
//     return GestureDetector(
//       onTap: () => setState(() => selectedSize = size),
//       child: Container(
//         width: 100,
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.red : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           size,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
}

// ================= CLIPPER =================
class ProductDetailsHeaderClipper extends CustomClipper<Path> {
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