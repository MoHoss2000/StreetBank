import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/customLoader.dart';

class UpdateUser extends StatelessWidget {
  final String type; // password, email
  final TextEditingController _updateTextEditingController =
      TextEditingController();

  /// contains new email if type is email
  /// or new password if type is password
  final TextEditingController _oldPasswordTextEditingController =
      TextEditingController(); // only used if password

  final TextEditingController _confirmPasswordTextEditingController =
      TextEditingController(); // only used if password

  UpdateUser({
    Key key,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPassword = type == "password";

    return Dialog(
      elevation: 25,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPassword
                    ? getTranslation(context, "change_password")
                    : getTranslation(context, "change_email"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  // color: TwitterColor.bondiBlue,
                  fontSize: 20,
                ),
              ),
              isPassword
                  // shows old password field else shows no thing
                  ? TextField(
                      controller: _oldPasswordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: getTranslation(context, "old_password")),
                    )
                  : SizedBox(),
              TextField(
                controller: _updateTextEditingController,
                keyboardType: isPassword
                    ? TextInputType.text
                    : TextInputType.emailAddress,
                obscureText: isPassword,
                decoration: InputDecoration(
                    labelText: isPassword
                        ? getTranslation(context, "new_password")
                        : getTranslation(context, "email")),
              ),
              isPassword
                  // shows comfirm password field else shows no thing
                  ? TextField(
                      controller: _confirmPasswordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText:
                              getTranslation(context, "confirm_password")),
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RaisedButton(
                    // color: TwitterColor.bondiBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      getTranslation(context, "cancel"),
                      style: TextStyle(
                        // color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // exit dialog and cancel changes
                      Navigator.pop(context);
                    },
                  ),
                  RaisedButton(
                    // color: TwitterColor.bondiBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      getTranslation(context, "update"),
                      style: TextStyle(
                        // color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      // update password or email
                      if (isPassword) {
                        await updatePassword(context);
                      } else {
                        await updateEmail(context);
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
  }

  updatePassword(context) async {
    User _currentUser = FirebaseAuth.instance.currentUser;
    String oldPassword = _oldPasswordTextEditingController.text;
    String userEmail = _currentUser.email;

    if (oldPassword.length < 6 ||
        _updateTextEditingController.text.length < 6) {
      displayToastMessage("Password must be at least 6 characters", context);
    } else if (_updateTextEditingController.text !=
        _confirmPasswordTextEditingController.text) {
      displayToastMessage("Passwords are not matching", context);
    } else {
      try {
        CustomLoader loader = CustomLoader();
        loader.showLoader(context);
        AuthCredential credential = EmailAuthProvider.credential(
            email: userEmail, password: oldPassword);

        await _currentUser.reauthenticateWithCredential(credential);
        // to check if old password is correct
        // if not correct exception will be thrown
        /// and catched in the catch statment
        /// and toast message is shown

        await _currentUser.updatePassword(_updateTextEditingController.text);
        // if correct then change password

        loader.hideLoader();
        Navigator.pop(context);
        displayToastMessage("Password updated succesfully", context);
      } on FirebaseAuthException catch (e) {
        displayToastMessage(e.message, context);
      }
    }
  }

  updateEmail(context) async {
    User _currentUser = FirebaseAuth.instance.currentUser;
    if (!validateEmail(_updateTextEditingController.text))
      displayToastMessage("Email is not valid", context);
    else {
      try {
        CustomLoader loader = CustomLoader();
        loader.showLoader(context);
        await _currentUser.updateEmail(_updateTextEditingController.text);
        loader.hideLoader();
        Navigator.pop(context);
        displayToastMessage("Email updated succesfully", context);
      } on FirebaseAuthException catch (e) {
        displayToastMessage(e.message, context);
      }
    }
  }
}
