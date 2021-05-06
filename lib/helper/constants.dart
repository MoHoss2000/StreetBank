import 'package:flutter/material.dart';

String appFont = 'HelveticaNeuea';

List<String> _regions = ["Obour", "Maadi", "Downtown", "Sheraton", "Nasr City"];

getRegionsList() {
  _regions.sort();

  List<DropdownMenuItem> regionsList = _regions
      .map((regionName) =>
          DropdownMenuItem(child: Text(regionName), value: regionName))
      .toList();

  return regionsList;
}

/// Firestore collections
///
/// Store `User` Model in db
const String USERS_COLLECTION = "users";

/// Store `ChatMessage` Model in db
const String MESSAGES_COLLECTION = "messages";

/// Store `ChatMessage` Model in db
/// `chatUsers` are stored in `ChatMessage` on purpose
const String CHAT_USER_LIST_COLLECTION = "chatUsers";
