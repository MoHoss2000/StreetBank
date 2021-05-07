import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

// some colors used in Twitter App
// not all of them are used but they are kept for future reference (if needed)
class TwitterColor {
  static final Color bondiBlue = Color.fromRGBO(0, 132, 180, 1.0);
  static final Color cerulean = Color.fromRGBO(0, 172, 237, 1.0);
  static final Color spindle = Color.fromRGBO(192, 222, 237, 1.0);
  static final Color white = Color.fromRGBO(255, 255, 255, 1.0);
  static final Color black = Color.fromRGBO(0, 0, 0, 1.0);
  static final Color woodsmoke = Color.fromRGBO(20, 23, 2, 1.0);
  static final Color woodsmoke_50 = Color.fromRGBO(20, 23, 2, 0.5);
  static final Color mystic = Color.fromRGBO(230, 236, 240, 1.0);
  static final Color dodgetBlue = Color.fromRGBO(29, 162, 240, 1.0);
  static final Color dodgetBlue_50 = Color.fromRGBO(29, 162, 240, 0.5);
  static final Color paleSky = Color.fromRGBO(101, 119, 133, 1.0);
  static final Color ceriseRed = Color.fromRGBO(224, 36, 94, 1.0);
  static final Color paleSky50 = Color.fromRGBO(101, 118, 133, 0.5);
}

class AppThemes {
  // ---- Dark Theme ----
  static final _darkAccent = Colors.cyan;
  static final ThemeData _darkThemeData =
      ThemeData(accentColor: _darkAccent, brightness: Brightness.dark);

  static final darkTheme = AppTheme(
    data: _darkThemeData,
    id: "dark",
    description: "Dark Theme",
  );

  // ---- Purple Theme ----
  static final _purplePrimary = Colors.purple;
  static final _purpleAccent = Colors.pink;
  static final _purpleBackground = Color(0xFFFFFFFF);
  static final ThemeData _purpleThemeData = ThemeData(
      primaryColor: _purplePrimary,
      accentColor: _purpleAccent,
      backgroundColor: _purpleBackground);

  static final purpleTheme = AppTheme(
    data: _purpleThemeData,
    description: "Purple Theme",
    id: "purple",
  );

  /// ----  Blue Theme  ----
  static final _bluePrimary = Color(0xFF3F51B5);
  static final _blueAccent = Colors.grey[800];
  static final _blueBackground = Color(0xFFFFFFFF);
  static final ThemeData _blueThemeData = ThemeData(
      primaryColor: _bluePrimary,
      accentColor: _blueAccent,
      backgroundColor: _blueBackground);

  static final blueTheme = AppTheme(
    data: _blueThemeData,
    description: "Blue Theme",
    id: "blue",
  );

  /// ----  Green Theme  ----
  static final _greenPrimary = Color(0xFF4CAF50);
  static final _greenAccent = Color(0xFF631739);
  static final _greenBackground = Color(0xFFFFFFFF);
  static final _greenThemeData = ThemeData(
      primaryColor: _greenPrimary,
      accentColor: _greenAccent,
      backgroundColor: _greenBackground);

  static final greenTheme = AppTheme(
    data: _greenThemeData,
    description: "Green Theme",
    id: "green",
  );

  /// ----  Pink Theme  ----
  static final _pinkPrimary = Color(0xFFE91E63);
  static final _pinkAccent = Color(0xFF0C7D9C);
  static final _pinkBackground = Color(0xFFFFFFFF);
  static final _pinkThemeData = ThemeData(
    primaryColor: _pinkPrimary,
    accentColor: _pinkAccent,
    backgroundColor: _pinkBackground,
  );

  static final pinkTheme = AppTheme(
    data: _pinkThemeData,
    description: "Pink Theme",
    id: "pink",
  );

  /// ----  Red Theme  ----
  static final _redPrimary = Colors.red[900];
  static final _redAccent = Colors.black;
  static final _redBackground = Color(0xFFFFFFFF);
  static final _redThemeData = ThemeData(
    primaryColor: _redPrimary,
    accentColor: _redAccent,
    backgroundColor: _redBackground,
  );

  static final redTheme = AppTheme(
    data: _redThemeData,
    description: "Red Theme",
    id: "red",
  );
}
