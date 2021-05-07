import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:streetbank/states/appState.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/states/chat/chatState.dart';
import 'package:streetbank/states/notificationState.dart';
import 'package:streetbank/states/searchState.dart';
import 'package:theme_provider/theme_provider.dart';

import 'app_localization.dart';
import 'helper/routes.dart';
import 'helper/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

CollectionReference usersCol = FirebaseFirestore.instance.collection("users");

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>();
    state.setLocale(locale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ThemeProvider(
      saveThemesOnChange: true,
      onInitCallback: (controller, previouslySavedThemeFuture) async {
        String savedTheme = await previouslySavedThemeFuture;
        if (savedTheme != null) {
          controller.setTheme(savedTheme);
        } else {
          Brightness platformBrightness =
              SchedulerBinding.instance?.window.platformBrightness ??
                  Brightness.light;
          if (platformBrightness == Brightness.dark) {
            controller.setTheme('dark');
          } else {
            controller.setTheme('red');
          }
          controller.forgetSavedTheme();
        }
      },
      onThemeChanged: (old, newtheme) {
        print(newtheme.id);
      },
      themes: [
        AppThemes.darkTheme,
        AppThemes.blueTheme,
        AppThemes.pinkTheme,
        AppThemes.greenTheme,
        AppThemes.redTheme,
        AppThemes.purpleTheme,
      ],
      child: ThemeConsumer(
        child: Builder(
          builder: (themeContext) => MultiProvider(
            providers: [
              ChangeNotifierProvider<AppState>(create: (_) => AppState()),
              ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
              ChangeNotifierProvider<SearchState>(create: (_) => SearchState()),
              ChangeNotifierProvider<ChatState>(create: (_) => ChatState()),
              ChangeNotifierProvider<NotificationState>(
                  create: (_) => NotificationState()),
            ],
            child: MaterialApp(
              supportedLocales: [
                Locale("en", ""),
                Locale("ar", ""),
              ],
              localizationsDelegates: [
                AppLocalization.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              locale: _locale,
              debugShowCheckedModeBanner: false,
              title: 'StreetBank',
              theme: ThemeProvider.themeOf(themeContext).data,
              routes: Routes.route(),
              onGenerateRoute: (settings) => Routes.onGenerateRoute(settings),
              onUnknownRoute: (settings) => Routes.onUnknownRoute(settings),
              initialRoute: "SplashPage",
            ),
          ),
        ),
      ),
    );
  }
}
