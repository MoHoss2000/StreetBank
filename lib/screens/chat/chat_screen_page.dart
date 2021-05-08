import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:streetbank/helper/theme.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/chatModel.dart';
import 'package:streetbank/models/userModel.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/states/chat/chatState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/full_photo.dart';

class ChatScreenPage extends StatefulWidget {
  ChatScreenPage({Key key, this.userProfileId}) : super(key: key);

  final String userProfileId;

  _ChatScreenPageState createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final messageController = new TextEditingController();
  String senderId;
  String userImage;
  ChatState state;
  ScrollController _controller;
  GlobalKey<ScaffoldState> _scaffoldKey;

  File imageFile;
  bool isLoading;
  String imageUrl;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _controller = ScrollController();
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);

    chatState.setIsChatScreenOpen = true;
    senderId = state.userId;
    chatState.databaseInit(chatState.chatUser.userId, state.userId);
    chatState.getchatDetailAsync();
    super.initState();
  }

  Widget _chatScreenBody() {
    final state = Provider.of<ChatState>(context);
    if (state.messageList == null || state.messageList.length == 0) {
      return Center(
        child: Text(
          'No message found',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      controller: _controller,
      shrinkWrap: true,
      reverse: true,
      physics: BouncingScrollPhysics(),
      itemCount: state.messageList.length,
      itemBuilder: (context, index) => chatMessage(state.messageList[index]),
    );
  }

  Widget chatMessage(ChatMessage message) {
    if (senderId == null) {
      return Container();
    }
    if (message.senderId == senderId)
      return _message(message, true); // message that the user sends
    else
      return _message(message, false); // message that the user receives
  }

  // builds a message left or right depending on the sender
  Widget _message(ChatMessage chat, bool myMessage) {
    return Column(
      textDirection: TextDirection.ltr,
      crossAxisAlignment:
          myMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment:
          myMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            SizedBox(
              width: 15,
            ),
            myMessage
                ? SizedBox()
                : CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        Image.asset("assets/images/avatar.jpg").image,

                    /// displays a static avatar image
                  ),
            Expanded(
              child: Container(
                alignment:
                    myMessage ? Alignment.centerRight : Alignment.centerLeft,
                margin: EdgeInsets.only(
                  right: myMessage ? 10 : (fullWidth(context) / 4),
                  top: 20,
                  left: myMessage ? (fullWidth(context) / 4) : 10,
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: getBorder(myMessage),
                        color: myMessage
                            ? TwitterColor.dodgetBlue
                            : TwitterColor.mystic,
                      ),
                      child: chat.type == 0 // message is text
                          ? Text(
                              chat.message,
                              style: TextStyle(
                                fontSize: 16,
                                color: myMessage
                                    ? TwitterColor.white
                                    : Colors.black,
                              ),
                            )
                          : _buildImage(chat), // message is image
                    ),
                    chat.type == 0 // text
                        ? Positioned(
                            // allows text message to be copied on hold
                            top: 0,
                            bottom: 0,
                            right: 0,
                            left: 0,
                            child: InkWell(
                              borderRadius: getBorder(myMessage),
                              onLongPress: () {
                                var text = ClipboardData(text: chat.message);
                                Clipboard.setData(text);
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: TwitterColor.white,
                                    content: Text(
                                      'Message copied',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(), // if image then no copy
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(right: 10, left: 10),
          child: Text(
            getChatTime(chat.createdAt),
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.caption.copyWith(fontSize: 12),
          ),
        )
      ],
    );
  }

  _buildImage(ChatMessage message) {
    return FlatButton(
      child: CachedNetworkImage(
        placeholder: (context, url) => Container(
          // when image is loading
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
          ),
          width: 200.0,
          height: 200.0,
          padding: EdgeInsets.all(70.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Material(
          // if image was not found/deleted from db or error in connection
          child: Image.asset(
            'assets/images/no_photo.jpeg',
            width: 200.0,
            height: 200.0,
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
          clipBehavior: Clip.hardEdge,
        ),
        imageUrl: message.message,
        width: 200.0,
        height: 200.0,
        fit: BoxFit.cover,
      ),
      onPressed: () {
        // shows the image in full screen when pressed
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FullPhoto(url: message.message)));
      },
      padding: EdgeInsets.all(0),
    );
  }

  BorderRadius getBorder(bool myMessage) {
    return BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomRight: myMessage ? Radius.circular(0) : Radius.circular(20),
      bottomLeft: myMessage ? Radius.circular(20) : Radius.circular(0),
    );
  }

  /// opens image picker to choose photo
  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile(); // when image file is chosen upload to Cloud Storage
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference =
        FirebaseStorage.instance.ref().child("chats").child(fileName);
    UploadTask uploadTask = reference.putFile(imageFile);
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});

    // get the link of the image after it is uploaded
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        submitMessage(
            isImage: true,
            imageUrl: imageUrl); // to upload to db and send the message
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  Widget _bottomEntryField() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Divider(
            thickness: 0,
            height: 1,
          ),
          TextField(
            onSubmitted: (val) async {
              submitMessage();
            },
            controller: messageController,
            decoration: InputDecoration(
              prefixIcon:
                  IconButton(icon: Icon(Icons.image), onPressed: getImage),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              alignLabelWithHint: true,
              hintText: getTranslation(context, "message_box"),
              suffixIcon:
                  IconButton(icon: Icon(Icons.send), onPressed: submitMessage),
            ),
          ),
        ],
      ),
    );
  }

  // send the message
  void submitMessage({isImage = false, String imageUrl}) {
    var authstate = Provider.of<AuthState>(context, listen: false);

    ChatMessage message;
    message = ChatMessage(
        message: messageController.text,
        createdAt: Timestamp.now().toDate().toUtc().toString(),
        senderId: authstate.userModel.userId,
        receiverId: state.chatUser.userId,
        seen: false,
        type: 0,
        timeStamp:
            Timestamp.now().toDate().toUtc().millisecondsSinceEpoch.toString(),
        senderName: authstate.user.displayName);

    if (isImage) {
      message.type = 1;
      message.message = imageUrl;
    } else if (messageController.text == null ||
        messageController.text.isEmpty) {
      return;
    }
    UserModel myUser = UserModel(
        firstName: authstate.userModel.firstName,
        lastName: authstate.userModel.lastName,
        userId: authstate.userModel.userId);

    UserModel secondUser = UserModel(
      firstName: state.chatUser.firstName,
      lastName: state.chatUser.lastName,
      userId: state.chatUser.userId,
    );

    state.onMessageSubmitted(message, myUser: myUser, secondUser: secondUser);
    Future.delayed(Duration(milliseconds: 50)).then((_) {
      messageController.clear(); // clears the text field
    });
    try {
      if (state.messageList != null &&
          state.messageList.length > 1 &&
          _controller.offset > 0) {
        _controller.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      print("[Error] $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    state = Provider.of<ChatState>(context, listen: false);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          "${state.chatUser.firstName} ${state.chatUser.lastName}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: _chatScreenBody(),
              ),
            ),
            _bottomEntryField()
          ],
        ),
      ),
    );
  }
}
