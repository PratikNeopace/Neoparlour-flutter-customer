import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo_parlour/modules/pages/splash_screen.dart';
import 'package:neo_parlour/firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:neo_parlour/provider/customer/auth_provider.dart';
import 'package:neo_parlour/provider/customer/service_provider.dart';
import 'package:neo_parlour/provider/customer/staff_provider.dart';
import 'package:neo_parlour/provider/customer/offer_provider.dart';
import 'package:neo_parlour/provider/customer/booking_provider.dart';
import 'package:neo_parlour/provider/customer/package_provider.dart';
import 'package:neo_parlour/provider/customer/product_provider.dart';
import 'package:neo_parlour/provider/customer/feedback_provider.dart';
import 'package:neo_parlour/provider/customer/cart_provider.dart';
import 'package:neo_parlour/provider/customer/order_provider.dart';


Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.notification?.title}");
}

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   
   if (kIsWeb) {
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
   } else {
     await Firebase.initializeApp();
   }

  // REGISTER BACKGROUND HANDLER HERE
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget { 
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: SplashScreen()
      // home:OTPScreen()
    );
  }
}


