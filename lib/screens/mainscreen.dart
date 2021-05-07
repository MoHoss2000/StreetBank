import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animated_icon/simple_animated_icon.dart';

import 'package:streetbank/Screens/profile.dart';
import 'package:streetbank/Screens/update_user.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/helper/routes.dart';
import 'package:streetbank/helper/theme.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/languageModel.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/states/chat/chatState.dart';
import 'package:streetbank/states/notificationState.dart';
import 'package:streetbank/states/searchState.dart';
import 'package:streetbank/widgets/themeDialog.dart';
import 'package:theme_provider/theme_provider.dart';

import '../main.dart';
import 'authentication/login.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  DocumentSnapshot currentUserData;

  bool _isDarkMode = false;
  AnimationController _animationController;
  Animation<double> _progress;
  Animation<Color> _color;

  void getUserData() async {
    currentUserData = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser.uid)
        .get();
  }

  @override
  void initState() {
    getUserData();

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            // call `build` on animation progress
            setState(() {});
          });

    var curve = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 1.0, curve: Curves.easeOut),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _color = ColorTween(begin: Colors.black, end: Colors.white).animate(curve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initProfile();
      initSearch();
      initNotificaiton();
      initChat();

      Future.delayed(Duration(seconds: 1)).then((_) {
        if (ThemeProvider.controllerOf(context).currentThemeId == "dark") {
          setState(() {
            _isDarkMode = true;
            _animationController.forward();
          });
        }
      });
    });
    super.initState();
  }

  void initProfile() {
    var state = Provider.of<AuthState>(context, listen: false);
    state.databaseInit();
  }

  void initSearch() {
    var searchState = Provider.of<SearchState>(context, listen: false);
    searchState.getDataFromDatabase();
  }

  void initNotificaiton() {
    var state = Provider.of<NotificationState>(context, listen: false);
    state.initfirebaseService();
  }

  void initChat() {
    print("token updated");
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.databaseInit(state.userId, state.userId);

    /// It will update fcm token in database
    /// fcm token is required to send firebase notification
    state.updateFCMToken();

    /// It get fcm server key
    /// Server key is required to configure firebase notification
    /// Without fcm server notification can not be sent
    chatState.getFCMServerKey();
  }

  /// On app launch it checks if app is launch by tapping on notification from notification tray
  /// If yes, it checks for  which type of notification is recieve
  /// If notification type is `NotificationType.Message` then chat screen will open

  void _checkNotification() {
    final authstate = Provider.of<AuthState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var state = Provider.of<NotificationState>(context, listen: false);

      /// Check if user recieve chat notification from firebase
      /// Redirect to chat screen
      /// `notificationSenderId` is a user id who sends you a message
      /// `notificationReciverId` is a your user id.
      if (state.notificationType == NotificationType.Message &&
          state.notificationReciverId == authstate.userModel.userId) {
        state.setNotificationType = null;
        state.getuserDetail(state.notificationSenderId).then((user) {
          cprint("Opening user chat screen");
          final chatState = Provider.of<ChatState>(context, listen: false);
          chatState.setChatUser = user;
          Navigator.pushNamed(context, '/ChatScreenPage');
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void animate() {
    if (_isDarkMode) {
      _animationController.reverse();
      ThemeProvider.controllerOf(context).setTheme("red");
    } else {
      _animationController.forward();
      ThemeProvider.controllerOf(context).setTheme("dark");
    }

    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkNotification();
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        centerTitle: true,
        title: Text("StreetBank"),
      ),
      drawer: Drawer(
        elevation: 5,
        child: ListView(
          children: [
            SizedBox(height: 20),
            _buildDarkModeSwitch(),
            SizedBox(height: 10),
            _buildDrawerListTile(
              getTranslation(context, "profile"),
              Icons.person,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                            currentUserData: currentUserData,
                          ))),
            ),
            _buildDrawerListTile(
                getTranslation(context, "favorites"),
                Icons.favorite,
                () =>
                    Navigator.pushNamed(context, "/${Routes.favoritesScreen}")),
            _buildDrawerListTile(
                getTranslation(context, "chats"),
                Icons.chat,
                () =>
                    Navigator.pushNamed(context, "/${Routes.chatListScreen}")),
            _buildDrawerListTile(
                getTranslation(context, "settings"), Icons.settings, () {
              Navigator.pop(context);
              showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  builder: (context) => _modalBottomSheet(),
                  context: context);
            }),
            _buildLanguageMenu(),
            ThemeProvider.controllerOf(context).currentThemeId != "dark"
                ? _buildDrawerListTile(
                    getTranslation(context, "theme"),
                    Icons.color_lens,
                    () {
                      showDialog(
                        context: context,
                        builder: (_) => ThemeConsumer(
                          child: CustomThemeDialog(
                            hasDescription: false,
                            title: Text(
                              getTranslation(
                                context,
                                "select_theme",
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(),
            _buildDrawerListTile(
                getTranslation(context, "logout"), Icons.logout, () async {
              final state = Provider.of<AuthState>(context, listen: false);
              await state.logoutCallback();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Login(loginCallback: state.getCurrentUser),
                ),
                (route) => false,
              );
            }),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildListButton(
                getTranslation(context, "for_free"), "/products/free"),
            _buildListButton(
                getTranslation(context, "for_exchange"), "/products/exchange"),
            _buildListButton(getTranslation(context, "for_metaphore"),
                "/products/metaphore"),
          ],
        ),
      ),
    );
  }

  Future<Locale> setLocale(String languageCode) async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    await _preferences.setString("lang", languageCode);

    /// save preference to device local storage
    /// for future app launch
    return Locale(languageCode, "");
  }

  void _changeLanguage(Language lang) async {
    Locale _temp = await setLocale(lang.languageCode);
    MyApp.setLocale(context, _temp);

    /// call setLocale method in MyApp class
  }

  Widget _buildDarkModeSwitch() {
    return Center(
      child: IconButton(
        splashColor: Colors.grey,
        onPressed: animate,
        iconSize: 48.0,
        icon: SimpleAnimatedIcon(
          color: _color.value,
          // customize icon color
          size: 48.0,
          // customize icon size
          startIcon: Icons.wb_sunny,
          endIcon: Icons.brightness_2,
          progress: _progress,

          // Multiple transitions are applied from left to right.
          // The order is important especially `slide_in_*` transitions are involved.
          // In this example, if `slide_in_left` is applied before `zoom_in`,
          // the slide in effect will be scaled by zoom_in as well, leading to unexpected effect.
          // transitions: [Transitions.zoom_in, Transitions.slide_in_left],
          transitions: [
            Transitions.zoom_in,
            Transitions.rotate_cw,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerListTile(String title, IconData icon, Function onPressed) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          // color: Theme.of(context).mode
          // color: Theme.of(context).brightness == Brightness.dark
          color: ThemeProvider.themeOf(context).id == 'dark'
              ? Theme.of(context).accentColor
              : Theme.of(context).primaryColor,
        ),
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).accentColor,
      ),
      onTap: onPressed,
    );
  }

  Widget _buildLanguageMenu() {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: Theme.of(context).accentColor,
      ),
      title: DropdownButton(
          hint: Text(
            getTranslation(context, "language"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeProvider.themeOf(context).id == 'dark'
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
            ),
          ),
          onChanged: (Language lang) => _changeLanguage(lang),
          underline: SizedBox(),
          items: Language.languageList()
              .map<DropdownMenuItem<Language>>(
                (lang) => DropdownMenuItem(
                  value: lang,
                  child: Row(
                    children: [
                      Text(lang.flag),
                      SizedBox(width: 5),
                      Text(lang.name),
                    ],
                  ),
                ),
              )
              .toList()),
    );
  }

  /// to change password and email
  Widget _modalBottomSheet() {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 5,
              spreadRadius: 0.1,
            )
          ]),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 5,
          left: 5,
          right: 5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(
                Icons.email,
              ),
              title: Text(
                getTranslation(context, "change_email"),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return UpdateUser(type: "email");

                      /// dialog to change email
                    });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.lock,
              ),
              title: Text(
                getTranslation(context, "change_password"),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return UpdateUser(type: "password");

                      /// dialog to change password
                    });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListButton(String text, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(route);
      },
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).accentColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              offset: Offset(3, 4),
              color: Colors.black,
              // color: Theme.of(context).accentColor,
              blurRadius: 5.0,
              spreadRadius: 0.5,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              // TwitterColor.paleSky,
              Theme.of(context).accentColor

              // TwitterColor.white
            ],
            // colors: [TwitterColor.bondiBlue, TwitterColor.paleSky],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,

            stops: [1, 1],
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(30.0),
          ),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.left,
            style: GoogleFonts.muli(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
