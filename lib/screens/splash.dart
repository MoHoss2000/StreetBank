import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/helper/theme.dart';
import 'package:streetbank/main.dart';
import 'package:streetbank/screens/authentication/login.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/title_text.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      timer();
    });
    super.initState();
  }

  void timer() {
    /// shows splash for 1 sec then initializes app
    Future.delayed(Duration(seconds: 1)).then((_) async {
      var state = Provider.of<AuthState>(context, listen: false);
      Locale locale = await state.getLocale();

      /// fetch user's prefered language
      MyApp.setLocale(context, locale);
      await state.getCurrentUser();
      AuthStatus authStatus = state.authStatus;
      if (authStatus == AuthStatus.NOT_LOGGED_IN) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Login(
              loginCallback: state.getCurrentUser,
            ),
          ),
          (route) => false,
        );
      }
      if (authStatus == AuthStatus.LOGGED_IN) {
        Navigator.pushReplacementNamed(context, "/main");
      }
    });
  }

  Widget _body() {
    return Container(
      height: fullHeight(context),
      width: fullWidth(context),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: TwitterColor.mystic,
                    // color: Theme.of(context).primaryColor,
                    blurRadius: 20,
                    spreadRadius: 5),
              ],
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: Image.asset(
                'assets/images/logo.png',
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            child: Column(
              children: [
                TitleText(
                  "StreetBank",
                  color: Colors.white,
                  fontSize: 35,
                ),
                TitleText(
                  "Share things with friends.",
                  fontSize: 15,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: _body(),
    );
  }
}
