import 'package:flutter/material.dart';
import 'package:streetbank/screens/authentication/login.dart';
import 'package:streetbank/screens/authentication/signup.dart';
import 'package:streetbank/screens/chat/chat_screen_page.dart';
import 'package:streetbank/screens/chat/chats_list_page.dart';
import 'package:streetbank/screens/mainscreen.dart';
import 'package:streetbank/screens/products/products_screen.dart';
import 'package:streetbank/screens/splash.dart';
import '../widgets/customWidgets.dart';
import 'customRoute.dart';

class Routes {
  static const String chatScreen = "ChatScreenPage";
  static const String chatListScreen = "ChatList";
  static const String signupScreen = "signup";
  static const String loginScreen = "login";
  static const String mainScreen = "main";
  static const String productsScreen = "products";
  static const String favoritesScreen = "favorites";

  static dynamic route() {
    return {
      'SplashPage': (BuildContext context) => SplashPage(),
    };
  }

  static Route onGenerateRoute(RouteSettings settings) {
    final List<String> pathElements = settings.name.split('/');
    if (pathElements[0] != '' || pathElements.length == 1) {
      return null;
    }
    switch (pathElements[1]) {
      case chatScreen:
        return CustomRoute<bool>(
            builder: (BuildContext context) => ChatScreenPage());
      case chatListScreen:
        return CustomRoute<bool>(
            builder: (BuildContext context) => ChatListPage());
      case signupScreen:
        return CustomRoute<bool>(builder: (BuildContext context) => Signup());
      case loginScreen:
        return CustomRoute<bool>(builder: (BuildContext context) => Login());
      case mainScreen:
        return CustomRoute<bool>(
            builder: (BuildContext context) => MainScreen());
      case favoritesScreen:
        return CustomRoute<bool>(
            builder: (BuildContext context) => ProductsScreen(
                  favoritesOnly: true,
                ));
      case productsScreen:
        String productType;
        if (pathElements.length > 2) {
          productType = pathElements[2];
        }
        return CustomRoute<bool>(
            builder: (BuildContext context) =>
                ProductsScreen(productType: productType));
      default:
        return onUnknownRoute(RouteSettings(name: '/Feature'));
    }
  }

  static Route onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: customTitleText(settings.name.split('/')[1]),
          centerTitle: true,
        ),
        body: Center(
          child: Text('${settings.name.split('/')[1]} Comming soon..'),
        ),
      ),
    );
  }
}
