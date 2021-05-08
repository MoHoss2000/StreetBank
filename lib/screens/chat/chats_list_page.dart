import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/chatModel.dart';
import 'package:streetbank/models/userModel.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/states/chat/chatState.dart';
import 'package:streetbank/states/searchState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/newWidget/emptyList.dart';
import 'package:streetbank/widgets/newWidget/title_text.dart';
import 'package:theme_provider/theme_provider.dart';

class ChatListPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatListPage({Key key, this.scaffoldKey}) : super(key: key);
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.setIsChatScreenOpen = true;

    chatState.getUserchatList(state.user.uid);
    super.initState();
  }

  Widget _body() {
    final state = Provider.of<ChatState>(context);
    final searchState = Provider.of<SearchState>(context, listen: false);
    if (state.chatUserList == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: EmptyList(
          'No message available ',
          subTitle: 'When someone sends you message, it will show up here \n ',
        ),
      );
    } else {
      return ListView.separated(
        physics: BouncingScrollPhysics(),
        itemCount: state.chatUserList.length,
        itemBuilder: (context, index) => _userCard(
            searchState.userlist.firstWhere(
              (x) => x.userId == state.chatUserList[index].key,
              orElse: () => UserModel(userId: "Unknown"),
            ),
            state.chatUserList[index]),
        separatorBuilder: (context, index) {
          return Divider(
            thickness: 0.4,
            height: 2,
          );
        },
      );
    }
  }

  Widget _userCard(UserModel model, ChatMessage lastMessage) {
    return Container(
      // color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        onTap: () {
          final chatState = Provider.of<ChatState>(context, listen: false);
          final searchState = Provider.of<SearchState>(context, listen: false);
          chatState.setChatUser = model;
          if (searchState.userlist.any((x) => x.userId == model.userId)) {
            chatState.setChatUser = searchState.userlist
                .where((x) => x.userId == model.userId)
                .first;
          }

          /// opens the chosen user chat
          Navigator.pushNamed(context, '/ChatScreenPage').whenComplete(() {
            setState(() {
              final chatState = Provider.of<ChatState>(context, listen: false);
              final state = Provider.of<AuthState>(context, listen: false);
              chatState.getUserchatList(state.user.uid);
            });
          });
        },
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          backgroundImage:
              Image.asset("assets/images/avatar.jpg").image, //static avatar
        ),
        title: Row(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: 0, maxWidth: fullWidth(context) * .5),
              child: Text(
                "${model.firstName} ${model.lastName}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ThemeProvider.themeOf(context).id == 'dark'
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            SizedBox(width: 3),
            Spacer(),
          ],
        ),
        subtitle: lastMessage.type == 0
            ? TitleText(
                /// shows the last message if it is text

                trimMessage(lastMessage.message) ?? '@${model.firstName}',
                // color: Colors.grey[100],
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              )
            : Row(
                /// if image then show image icon and "Image" text
                children: [
                  Icon(
                    Icons.image,
                    color: Color(0xff1657786),
                  ),
                  SizedBox(width: 5),
                  TitleText(
                    getTranslation(context, "image"), color: Color(0xff1657786),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    // overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
      ),
    );
  }

  String trimMessage(String message) {
    if (message != null && message.isNotEmpty) {
      if (message.length > 70) {
        message = message.substring(0, 70) + '...';
        return message;
      } else {
        return message;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslation(context, "messages"),
        ),
      ),
      // backgroundColor: TwitterColor.mystic,
      body: _body(),
    );
  }
}
