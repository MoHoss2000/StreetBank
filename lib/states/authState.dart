import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/userModel.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'appState.dart';

class AuthState extends AppState {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  User user;
  String userId;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Query _profileQuery;
  List<UserModel> _profileUserModelList;
  UserModel _userModel;
  Locale locale;

  UserModel get userModel => _userModel;

  static final CollectionReference _userCollection =
      kfirestore.collection(USERS_COLLECTION);

  /// Logout from device
  logoutCallback() async {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    _userModel = null;
    user = null;
    _profileUserModelList = null;
    await _firebaseAuth.signOut();
    notifyListeners();
  }

  databaseInit() {
    try {
      if (_profileQuery == null) {
        _userCollection.doc(user.uid).snapshots().listen(_onProfileChanged);
      }
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
    }
  }

  /// Verify user's credentials for login
  Future<String> signIn(String email, String password,
      {GlobalKey<ScaffoldState> scaffoldKey}) async {
    try {
      loading = true;
      var result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      user = result.user;
      userId = user.uid;
      loading = false;
      return user.uid;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signIn');
      customSnackBar(scaffoldKey, error.message);
      return null;
    }
  }

  /// Signing up (new account)
  Future<String> signUp(UserModel userModel,
      {GlobalKey<ScaffoldState> scaffoldKey, String password}) async {
    try {
      loading = true;
      var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );
      user = result.user;
      authStatus = AuthStatus.LOGGED_IN;
      result.user.updateProfile(
          displayName: "${userModel.firstName} ${userModel.lastName}");

      _userModel = userModel;
      _userModel.key = user.uid;
      _userModel.userId = user.uid;
      createUser(_userModel, newUser: true);
      return user.uid;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signUp');
      customSnackBar(scaffoldKey, error.message);
      return null;
    }
  }

  /// stores user data in DB
  /// `Create` and `Update` user
  /// IF `newUser` is true new user is created
  /// Else existing user will update with new values
  createUser(UserModel user, {bool newUser = false}) {
    if (newUser) {
      // Time at which user is created
      user.createdAt = DateTime.now().toUtc().toString();
    }

    kfirestore.collection(USERS_COLLECTION).doc(user.userId).set(user.toJson());
    _userModel = user;

    if (_profileUserModelList != null) {
      _profileUserModelList.add(_userModel);
    }
    loading = false;
  }

  // get the user's prefered language from the device storage (sharedprefs)
  Future<Locale> getLocale() async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    String languageCode = _preferences.getString("lang") ?? "en";

    /// if no preference found then set to `English`
    locale = locale;
    return Locale(languageCode, "");
  }

  /// Fetch current user profile
  Future<User> getCurrentUser() async {
    try {
      loading = true;
      logEvent('get_currentUSer');

      user = _firebaseAuth.currentUser;
      if (user != null) {
        authStatus = AuthStatus.LOGGED_IN;
        userId = user.uid;
        getProfileUser();
      } else {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      }
      loading = false;
      return user;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getCurrentUser');
      authStatus = AuthStatus.NOT_LOGGED_IN;
      return null;
    }
  }

  /// Send password reset link to email
  Future<void> forgetPassword(String email, {BuildContext context}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      Navigator.pop(context);
      displayToastMessage(
          'A reset password link is sent your your mail. You can reset your password from there',
          context);
    } on FirebaseAuthException catch (error) {
      displayToastMessage(error.message, context);
      return Future.value(false);
    }
  }

  /// Fetch user profile
  /// If `userProfileId` is null then logged in user's profile will fetched
  getProfileUser({String userProfileId}) async {
    try {
      loading = true;
      if (_profileUserModelList == null) {
        _profileUserModelList = [];
      }
      userProfileId = userProfileId == null ? user.uid : userProfileId;
      DocumentSnapshot documentSnapshot =
          await _userCollection.doc(userProfileId).get();
      print(_userModel);
      if (documentSnapshot.data() != null) {
        _profileUserModelList.add(UserModel.fromJson(documentSnapshot.data()));

        print("USER TOKEN " + _userModel.fcmToken);
        if (_userModel.fcmToken == null) {
          updateFCMToken();
        }

        logEvent('get_profile');
      }

      loading = false;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getProfileUser');
    }
  }

  /// if firebase token not available in profile
  /// Then get token from firebase and save it to profile
  /// When someone sends you a message FCM token is used
  void updateFCMToken() {
    if (_userModel == null) {
      return;
    }
    getProfileUser();
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      _userModel.fcmToken = token;
      createUser(_userModel);
    });
  }

  /// Trigger when logged-in user's profile change or updated
  /// Firebase event callback for profile update
  void _onProfileChanged(DocumentSnapshot event) {
    if (event.data() != null) {
      final updatedUser = UserModel.fromJson(event.data());
      if (updatedUser.userId == user.uid) {
        _userModel = updatedUser;
      }
      cprint('User Updated');
      notifyListeners();
    }
  }
}
