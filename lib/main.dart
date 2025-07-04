import '/constants/colors.dart';
import '/forms/common_form.dart';
import '/forms/sell_car_form.dart';
import '/forms/user_form_review.dart';
import '/provider/category_provider.dart';
import '/provider/product_provider.dart';
import '/screens/auth/email_verify_screen.dart';
import '/screens/auth/login_screen.dart';
import '/screens/auth/phone_auth_screen.dart';
import '/screens/auth/register_screen.dart';
import '/screens/category/product_by_category_screen.dart';
import '/screens/category/subcategory_screen.dart';
import '/screens/chat/user_chat_screen.dart';
import '/screens/home_screen.dart';
import '/screens/location_screen.dart';
import '/screens/main_navigatiion_screen.dart';
import '/screens/post/my_post_screen.dart';
import '/screens/product/product_details_screen.dart';
import '/screens/profile_screen.dart';
import '/screens/splash_screen.dart';
import '/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/reset_password_screen.dart';
import 'screens/category/category_list_screen.dart';
import 'screens/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        )
      ],
      child: const Main(),
    ),
  );
}

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: blackColor,
          fontFamily: 'Oswald',
          scaffoldBackgroundColor: whiteColor,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.screenId,
        routes: {
          SplashScreen.screenId: (context) => const SplashScreen(),
          LoginScreen.screenId: (context) => const LoginScreen(),
          PhoneAuthScreen.screenId: (context) => const PhoneAuthScreen(),
          LocationScreen.screenId: (context) => const LocationScreen(),
          HomeScreen.screenId: (context) => const HomeScreen(),
          WelcomeScreen.screenId: (context) => const WelcomeScreen(),
          RegisterScreen.screenId: (context) => const RegisterScreen(),
          EmailVerifyScreen.screenId: (context) => const EmailVerifyScreen(),
          ResetPasswordScreen.screenId: (context) =>
          const ResetPasswordScreen(),
          CategoryListScreen.screenId: (context) => const CategoryListScreen(),
          SubCategoryScreen.screenId: (context) => const SubCategoryScreen(),
          MainNavigationScreen.screenId: (context) =>
              const MainNavigationScreen(),
          ChatScreen.screenId: (context) => const ChatScreen(),
          MyPostScreen.screenId: (context) => const MyPostScreen(),
          ProfileScreen.screenId: (context) => const ProfileScreen(),
          SellCarForm.screenId: (context) => const SellCarForm(),
          UserFormReview.screenId: (context) => const UserFormReview(),
          CommonForm.screenId: (context) => const CommonForm(),
          ProductDetail.screenId: (context) => const ProductDetail(),
          ProductByCategory.screenId: (context) => const ProductByCategory(),
          UserChatScreen.screenId: (context) => const UserChatScreen(),
        });
  }
}
