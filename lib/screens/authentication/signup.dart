import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/helper/routes.dart';
import 'package:streetbank/helper/theme.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/userModel.dart';
import 'package:streetbank/screens/authentication/login.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/customLoader.dart';
import 'package:theme_provider/theme_provider.dart';

class Signup extends StatefulWidget {
  final VoidCallback loginCallback;

  const Signup({Key key, this.loginCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController _firstNameController;
  TextEditingController _lastNameController;
  TextEditingController _emailController;
  TextEditingController _passwordController;
  TextEditingController _confirmController;
  TextEditingController _phoneController;
  CustomLoader loader;
  final _formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    loader = CustomLoader();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
    _phoneController = TextEditingController();
    super.initState();
  }

  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _body(BuildContext context) {
    return Container(
      height: fullHeight(context) - 88,
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                    child: _entryField(getTranslation(context, "first_name"),
                        controller: _firstNameController)),
                SizedBox(width: 5),
                Expanded(
                    child: _entryField(getTranslation(context, "last_name"),
                        controller: _lastNameController)),
              ],
            ),
            _entryField(getTranslation(context, "enter_email"),
                controller: _emailController, isEmail: true),
            _entryField(getTranslation(context, "enter_phone"),
                controller: _phoneController),
            _entryField(getTranslation(context, "enter_password"),
                controller: _passwordController, isPassword: true),
            _entryField(getTranslation(context, "confirm_password"),
                controller: _confirmController, isPassword: true),
            _submitButton(context),
            Divider(height: 5),
            FlatButton(
              child: Text(getTranslation(context, "have_account")),
              onPressed: () {
                var state = Provider.of<AuthState>(context, listen: false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Login(loginCallback: state.getCurrentUser),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryField(String hint,
      {TextEditingController controller,
      bool isPassword = false,
      bool isEmail = false}) {
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
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: TextStyle(
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
        ),
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30.0),
            ),
            borderSide: BorderSide(color: Theme.of(context).accentColor),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      width: MediaQuery.of(context).size.width,
      child: FlatButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        color: Theme.of(context).primaryColor,
        onPressed: _submitForm,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Text(getTranslation(context, "signup"),
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _submitForm() {
    if (_firstNameController.text.length < 3) {
      return customSnackBar(
          _scaffoldKey, 'First name must be at least 3 characters');
    } else if (_lastNameController.text.length < 3) {
      return customSnackBar(
          _scaffoldKey, 'Last name must be at least 3 characters');
    } else if (!validateEmail(_emailController.text)) {
      return customSnackBar(_scaffoldKey, 'Enter valid email');
    } else if (!validatePhone(_phoneController.text)) {
      return customSnackBar(_scaffoldKey,
          'Enter valid phone number without country code (Ex: 01234567890)');
    } else if (_passwordController.text.length < 8) {
      return customSnackBar(
          _scaffoldKey, 'Password must be at least 8 characters');
    } else if (_passwordController.text != _confirmController.text) {
      return customSnackBar(_scaffoldKey, 'Passwords are not matching');
    }

    loader.showLoader(context);
    var state = Provider.of<AuthState>(context, listen: false);

    UserModel user = UserModel(
      email: _emailController.text.toLowerCase(),
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      favoritesList: [],
    );
    state
        .signUp(
      user,
      password: _passwordController.text,
      scaffoldKey: _scaffoldKey,
    )
        .then((status) {
      print(status);
    }).whenComplete(
      () {
        loader.hideLoader();
        if (state.authStatus == AuthStatus.LOGGED_IN) {
          Navigator.pushNamedAndRemoveUntil(context, "/${Routes.mainScreen}",
              (Route<dynamic> route) => false);
          widget.loginCallback();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          children: [
            SizedBox(height: 20),
            customText(
              getTranslation(context, "signup"),
              context: context,
              style: TextStyle(fontSize: 35),
            ),
            SizedBox(height: 20),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(child: _body(context)),
    );
  }
}
