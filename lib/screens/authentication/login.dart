import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:streetbank/helper/routes.dart';
import 'package:streetbank/helper/theme.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/screens/authentication/signup.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/customLoader.dart';
import 'package:streetbank/widgets/newWidget/title_text.dart';
import 'package:theme_provider/theme_provider.dart';

class Login extends StatefulWidget {
  final VoidCallback loginCallback;

  const Login({Key key, this.loginCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _emailController;
  TextEditingController _passwordController;
  TextEditingController _resetPasswordController;
  CustomLoader loader;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _emailController = TextEditingController();
    _resetPasswordController = TextEditingController();
    _passwordController = TextEditingController();
    loader = CustomLoader();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetPasswordController.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 30),
            Image.asset(
              "assets/images/logo.png",
              height: 200,
            ),
            SizedBox(height: 30),
            _entryField(
              getTranslation(context, "enter_email"),
              controller: _emailController,
            ),
            _entryField(
              getTranslation(context, "enter_password"),
              controller: _passwordController,
              isPassword: true,
            ),
            _emailLoginButton(context),
            _labelButton(
              getTranslation(context, "forgot_password"),
              onPressed: () =>
                  _showResetPassword, // opens dialog to reset password
            ),
            FlatButton(
              child: Text(getTranslation(context, "no_account")),
              onPressed: () {
                var state = Provider.of<AuthState>(context, listen: false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Signup(loginCallback: state.getCurrentUser),
                  ),
                  (route) => false,
                );
              },
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  // form text field with custom style
  Widget _entryField(String hint,
      {TextEditingController controller, bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).accentColor,
          width: 1.5,
        ),
        color: ThemeProvider.controllerOf(context).currentThemeId == "dark"
            ? Colors.grey[0]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
        ),
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Theme.of(context).accentColor)),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _labelButton(String title, {Function onPressed}) {
    return FlatButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        }
      },
      splashColor: Colors.grey.shade200,
      child: Text(
        title,
        style: TextStyle(
            color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emailLoginButton(BuildContext context) {
    return Container(
      width: fullWidth(context),
      margin: EdgeInsets.symmetric(vertical: 20),
      child: FlatButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        color: Theme.of(context).primaryColor,
        onPressed: _emailLogin,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: TitleText(
          getTranslation(context, "submit"),
          color: Colors.white,
        ),
      ),
    );
  }

  void _emailLogin() {
    var state = Provider.of<AuthState>(context, listen: false);
    if (state.isbusy) {
      return;
    }
    loader.showLoader(context);
    var isValid = validateCredentials(_scaffoldKey, _emailController.text,
        _passwordController.text); // check if entries are valid
    if (isValid) {
      state
          .signIn(_emailController.text, _passwordController.text,
              scaffoldKey: _scaffoldKey)
          .then((status) {
        if (state.user != null) {
          loader.hideLoader();
          Navigator.pushNamedAndRemoveUntil(
              context, "/${Routes.mainScreen}", (route) => false);
          widget.loginCallback();
        } else {
          cprint('Unable to login', errorIn: '_emailLoginButton');
          loader.hideLoader();
        }
      });
    } else {
      loader.hideLoader();
    }
  }

  _showResetPassword() {
    var state = Provider.of<AuthState>(context, listen: false);
    TextEditingController controller = new TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                  color: TwitterColor.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 5,
                      spreadRadius: 0.1,
                    )
                  ]),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        getTranslation(context, "reset_password_title"),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      getTranslation(context, "reset_password_content"),
                      style: TextStyle(fontSize: 14),
                    ),
                    _entryField(getTranslation(context, "email"),
                        controller: controller),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _labelButton(getTranslation(context, "cancel"),
                            onPressed: () => Navigator.pop(context)),
                        _labelButton(
                          getTranslation(context, "submit"),
                          onPressed: () {
                            String email = controller.text;
                            var isValidEmail = validateEmail(email);

                            if (isValidEmail) {
                              state.forgetPassword(controller.text,
                                  context: context);
                            } else {
                              displayToastMessage("Enter valid email", context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: customText(getTranslation(context, "signin"),
            context: context, style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: _body(context),
    );
  }
}
