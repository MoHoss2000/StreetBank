import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/customLoader.dart';
import 'dart:developer' as developer;

import '../app_localization.dart';

final FirebaseFirestore kfirestore = FirebaseFirestore.instance;
final kScreenloader = CustomLoader();

/// returns formatted `sent at` time to bo displayed in the chat
String getChatTime(String date) {
  if (date == null || date.isEmpty) {
    return '';
  }
  String msg = '';
  var dt = DateTime.parse(date).toLocal();

  if (DateTime.now().toLocal().isBefore(dt)) {
    return DateFormat.jm().format(DateTime.parse(date).toLocal()).toString();
  }

  var dur = DateTime.now().toLocal().difference(dt);
  if (dur.inDays > 0) {
    msg = '${dur.inDays} d';
    return dur.inDays == 1 ? '1d' : DateFormat("dd MMM").format(dt);
  } else if (dur.inHours > 0) {
    msg = '${dur.inHours} h';
  } else if (dur.inMinutes > 0) {
    msg = '${dur.inMinutes} m';
  } else if (dur.inSeconds > 0) {
    msg = '${dur.inSeconds} s';
  } else {
    msg = 'now';
  }
  return msg;
}

// get a specific string in the current app language (used in app localization)
// key must exist in /lib/helper/lang/ar.json and .../en.json
String getTranslation(BuildContext context, String key) {
  return AppLocalization.of(context).translate(key);
}

// prints the error in a nice format to the console (for debugging purposes only)
void cprint(dynamic data, {String errorIn, String event}) {
  if (errorIn != null) {
    print(
        '****************************** error ******************************');
    developer.log('[Error]', time: DateTime.now(), error: data, name: errorIn);
    print(
        '****************************** error ******************************');
  } else if (data != null) {
    developer.log(
      data,
      time: DateTime.now(),
    );
  }
  if (event != null) {
    // logEvent(event);
  }
}

// for debugging
void logEvent(String event, {Map<String, dynamic> parameter}) {
  print("[EVENT]: $event");
}

// for debugging
void debugLog(String log, {dynamic param = ""}) {
  final String time = DateFormat("mm:ss:mmm").format(DateTime.now());
  print("[$time][Log]: $log, $param");
}

bool validateCredentials(
    GlobalKey<ScaffoldState> _scaffoldKey, String email, String password) {
  if (email == null || email.isEmpty) {
    customSnackBar(_scaffoldKey, 'Please enter email');
    return false;
  } else if (password == null || password.isEmpty) {
    customSnackBar(_scaffoldKey, 'Please enter password');
    return false;
  } else if (password.length < 8) {
    customSnackBar(_scaffoldKey, 'Password must be 8 character long');
    return false;
  }

  var status = validateEmail(email);
  if (!status) {
    customSnackBar(_scaffoldKey, 'Please enter valid email');
    return false;
  }
  return true;
}

// checks if email is in correct format
bool validateEmail(String email) {
  String p =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

  RegExp regExp = new RegExp(p);

  var status = regExp.hasMatch(email);
  return status;
}

/// phone number must be 11 characters only
/// must start with `01`
bool validatePhone(String phone) {
  if (phone.length != 11) return false;
  if (!phone.startsWith("01")) return false;

  String p = "^[0-9]{11}"; // to check if it only contains valid digits

  RegExp regExp = new RegExp(p);

  var status = regExp.hasMatch(phone);
  return status;
}
