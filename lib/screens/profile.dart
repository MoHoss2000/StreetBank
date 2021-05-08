import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:theme_provider/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  final DocumentSnapshot currentUserData;

  const ProfileScreen({
    Key key,
    this.currentUserData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map data = currentUserData.data();
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslation(context, "profile")),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Center(
          child: ListView(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                _buildItem(
                  getTranslation(context, "name"),
                  "${data["firstName"]} ${data["lastName"]}",
                  Icons.person,
                  context,
                ),
                _buildItem(
                  getTranslation(context, "email"),
                  FirebaseAuth.instance.currentUser.email,
                  Icons.email,
                  context,
                ),
                _buildItem(
                  getTranslation(context, "phone"),
                  data["phone"],
                  Icons.phone,
                  context,
                ),
              ],
            ).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
      String title, String content, IconData icon, BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).accentColor,
      ),
      contentPadding: EdgeInsets.all(10),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          color: ThemeProvider.themeOf(context).id == 'dark'
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3.5),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
