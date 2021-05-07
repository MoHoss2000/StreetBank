import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/enum.dart';
import 'package:streetbank/models/chatModel.dart';
import 'package:streetbank/models/userModel.dart';

import '../../helper/utility.dart';
import '../appState.dart';

class ChatState extends AppState {
  bool setIsChatScreenOpen;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  List<ChatMessage> _messageList;
  UserModel _chatUser;
  List<ChatMessage> _chatUserList;
  String serverToken = "<FCM SERVER KEY>";

  StreamSubscription<QuerySnapshot> _messageSubscription;
  static final CollectionReference _messageCollection =
      kfirestore.collection(MESSAGES_COLLECTION);

  static final CollectionReference _userCollection =
      kfirestore.collection(USERS_COLLECTION);

  UserModel get chatUser => _chatUser;
  set setChatUser(UserModel model) {
    _chatUser = model;
  }

  String _channelName;

  /// gets list of messags sorted by time they were sent
  List<ChatMessage> get messageList {
    if (_messageList == null) {
      return null;
    } else {
      _messageList.sort((x, y) => DateTime.parse(x.createdAt)
          .toLocal()
          .compareTo(DateTime.parse(y.createdAt).toLocal()));
      _messageList.reversed;
      _messageList = _messageList.reversed.toList();
      return List.from(_messageList);
    }
  }

  List<ChatMessage> get chatUserList {
    if (_chatUserList == null) {
      return null;
    } else {
      return List.from(_chatUserList);
    }
  }

  void databaseInit(String userId, String myId) async {
    _messageList = null;

    getChannelName(userId, myId);

    _messageSubscription = _messageCollection
        .doc(_channelName)
        .collection(MESSAGES_COLLECTION)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docChanges.isEmpty) {
        return;
      }
      if (snapshot.docChanges.first.type == DocumentChangeType.added) {
        _onMessageAdded(snapshot.docChanges.first.doc);
      }
    });
  }

  /// Fetch FCM server key from firebase Remote config
  /// FCM server key is stored in firebase remote config
  /// you have to add server key in firebase remote config
  /// To fetch this key go to project setting in firebase
  /// Click on `cloud messaging` tab
  /// Copy server key from `Project credentials`
  /// Now goto `Remote Congig` section in fireabse
  /// Add [FcmServerKey]  as paramerter key and below json in Default vslue
  ///  ``` json
  ///  {
  ///    "key": "FCM server key here"
  ///  } ```
  /// For package detail check:-  https://pub.dev/packages/firebase_remote_config#-readme-tab-
  void getFCMServerKey() async {
    final RemoteConfig remoteConfig = RemoteConfig.instance;

    await remoteConfig.fetch();
    await remoteConfig.activate();
    var data = remoteConfig.getString('FcmServerKey');
    if (data != null && data.isNotEmpty) {
      serverToken = jsonDecode(data)["key"];
    } else {
      cprint("Please configure Remote config in firebase",
          errorIn: "getFCMServerKey");
    }
  }

  /// Fetch users list to who have ever engaged in chat message with logged-in user
  void getUserchatList(String userId) {
    try {
      _userCollection
          .doc(userId)
          .collection(CHAT_USER_LIST_COLLECTION)
          .get()
          .then((QuerySnapshot snapshot) {
        _chatUserList = [];
        if (snapshot != null && snapshot.docs.isNotEmpty) {
          for (var i = 0; i < snapshot.docs.length; i++) {
            final model =
                ChatMessage.fromJson(snapshot.docs[i].data()["lastMessage"]);
            model.key = snapshot.docs[i].id;
            _chatUserList.add(model);
          }

          _chatUserList.sort((x, y) {
            if (x.createdAt != null && y.createdAt != null) {
              return DateTime.parse(y.createdAt)
                  .compareTo(DateTime.parse(x.createdAt));
            } else {
              if (x.createdAt != null) {
                return 0;
              } else {
                return 1;
              }
            }
          });
        } else {
          _chatUserList = null;
        }
        notifyListeners();
      });
    } catch (error) {
      cprint(error);
    }
  }

  /// Fetch chat  all chat messages
  /// `_channelName` is used as primary key for chat message table
  /// `_channelName` is created from  by combining first 5 letters from user ids of two users
  void getchatDetailAsync() async {
    try {
      // _messageList.clear();
      if (_messageList == null) {
        _messageList = [];
      }
      _messageCollection
          .doc(_channelName)
          .collection(MESSAGES_COLLECTION)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
          for (var i = 0; i < querySnapshot.docs.length; i++) {
            final model = ChatMessage.fromJson(querySnapshot.docs[i].data());
            model.key = querySnapshot.docs[i].id;
            _messageList.add(model);
          }

          notifyListeners();
        } else {
          _messageList = null;
        }
      });
    } catch (error) {
      cprint(error);
    }
  }

  // sending a text message
  void onMessageSubmitted(ChatMessage message,
      {UserModel myUser, UserModel secondUser}) {
    print("sender" + myUser.userId);
    print("reciever" + secondUser.userId);
    print(_channelName);
    try {
      if (message.message != null &&
          message.message.length > 0 &&
          message.message.length < 400) {
        Map messageJson = message.toJson();

        /// updates `lastMessage` in the sender's doc
        _userCollection
            .doc(message.senderId)
            .collection(CHAT_USER_LIST_COLLECTION)
            .doc(message.receiverId)
            .set({"lastMessage": messageJson});

        /// updates `lastMessage` in the receiver's doc
        _userCollection
            .doc(message.receiverId)
            .collection(CHAT_USER_LIST_COLLECTION)
            .doc(message.senderId)
            .set({"lastMessage": messageJson});

        /// saves the message in the `messages` collection
        kfirestore
            .collection(MESSAGES_COLLECTION)
            .doc(_channelName)
            .collection(MESSAGES_COLLECTION)
            .doc()
            .set(messageJson);
        sendAndRetrieveMessage(message);
        logEvent('send_message');
      }
    } catch (error) {
      cprint(error);
    }
  }

  /// gets a unique channel id by taking first chars from both users' IDs
  /// adding a `-` between them
  String getChannelName(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    _channelName = '${list[0]}-${list[1]}';
    print("list " + list[0] + list[1]);
    return _channelName;
  }

  // / Method will trigger every time when you send/recieve  from/to someone messgae.
  void _onMessageAdded(DocumentSnapshot snapshot) {
    if (_messageList == null) {
      _messageList = [];
    }
    if (snapshot.data() != null) {
      var map = snapshot.data();
      if (map != null) {
        var model = ChatMessage.fromJson(map);
        model.key = snapshot.id;
        if (_messageList.length > 0 &&
            _messageList.any((x) => x.key == model.key)) {
          return;
        }
        _messageList.add(model);
      }
    } else {
      _messageList = null;
    }
    notifyListeners();
  }

  void onChatScreenClosed() {
    if (_messageSubscription != null) {
      _messageSubscription.cancel();
    }
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  // handles sending a notification to the receiver through FCM
  void sendAndRetrieveMessage(ChatMessage model) async {
    print("sending message $serverToken");
    await firebaseMessaging.requestPermission();
    if (chatUser.fcmToken == null) {
      print("NULL TOKEN");
      return;
    }

    var body = jsonEncode(<String, dynamic>{
      'notification': <String, dynamic>{
        'body': model.message,
        'title': "Message from ${model.senderName}",
        "sound": "default",
        "content_available": true,
      },
      'priority': 'high',
      'data': <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
        "type": NotificationType.Message.toString(),
        "senderId": model.senderId,
        "receiverId": model.receiverId,
        "title": "title",
        "body": model.message,
      },
      'to': chatUser.fcmToken
    });

    // sending HTTP request
    // Uri uri = new Uri(host: 'https://fcm.googleapis.com/fcm/send');
    Uri uri = Uri.https("fcm.googleapis.com", "/fcm/send");
    var response = await http.post(uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverToken',
        },
        body: body);
    print(response.body.toString());
  }
}
