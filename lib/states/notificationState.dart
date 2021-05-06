import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/notificationModel.dart';
import 'package:streetbank/models/userModel.dart';

import 'appState.dart';

class NotificationState extends AppState {
  String fcmToken;
  NotificationType _notificationType = NotificationType.NOT_DETERMINED;
  String notificationReciverId, notificationTweetId;
  NotificationType get notificationType => _notificationType;
  set setNotificationType(NotificationType type) {
    _notificationType = type;
  }

  String notificationSenderId;
  List<UserModel> userList = [];

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  List<NotificationModel> _notificationList;

  List<NotificationModel> get notificationList => _notificationList;

  /// get user
  Future<UserModel> getuserDetail(String userId) async {
    UserModel user;

    /// if user already available in userlist then get user data from list
    /// It reduce api load
    if (userList.length > 0 && userList.any((x) => x.userId == userId)) {
      return Future.value(userList.firstWhere((x) => x.userId == userId));
    }

    /// If user data not available in userlist then fetch user data from firestore
    var snapshot =
        await kfirestore.collection(USERS_COLLECTION).doc(userId).get();

    var map = snapshot.data();
    if (map != null) {
      user = UserModel.fromJson(map);
      user.key = snapshot.id;

      /// Add user data to userlist
      /// Next time user data can be get from this list
      userList.add(user);
    }
    return user;
  }

  /// Configure notification services
  void initfirebaseService() {
    // _firebaseMessaging.configure(
    //   onMessage: (Map<String, dynamic> message) async {
    //     // print("onMessage: $message");
    //     print(message['data']);
    //     notifyListeners();
    //   },
    //   onLaunch: (Map<String, dynamic> message) async {
    //     cprint("Notification ", event: "onLaunch");
    //     var data = message['data'];
    //     // print(message['data']);
    //     notificationSenderId = data["senderId"];
    //     notificationReciverId = data["receiverId"];
    //     notificationReciverId = data["receiverId"];
    //     if (data["type"] == "NotificationType.Message") {
    //       setNotificationType = NotificationType.Message;
    //     }
    //     notifyListeners();
    //   },
    //   onResume: (Map<String, dynamic> message) async {
    //     cprint("Notification ", event: "onResume");
    //     var data = message['data'];
    //     // print(message['data']);
    //     notificationSenderId = data["senderId"];
    //     notificationReciverId = data["receiverId"];
    //     if (data["type"] == "NotificationType.Message") {
    //       setNotificationType = NotificationType.Message;
    //     }
    //     notifyListeners();
    //   },
    // );

    _firebaseMessaging.requestPermission();

    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      fcmToken = token;
      print(token);
    });
  }
}
