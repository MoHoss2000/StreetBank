import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/userModel.dart';
import 'appState.dart';

class SearchState extends AppState {
  bool isBusy = false;
  List<UserModel> _userFilterlist;
  List<UserModel> _userlist;

  List<UserModel> get userlist {
    if (_userFilterlist == null) {
      return null;
    } else {
      return List.from(_userFilterlist);
    }
  }

  /// get [User list] from firebase cloud firestore
  void getDataFromDatabase() async {
    try {
      isBusy = true;
      if (_userFilterlist == null) {
        _userFilterlist = List<UserModel>();
      } else {}
      if (_userlist == null) {
        _userlist = List<UserModel>();
      }
      _userFilterlist.clear();
      _userlist.clear();

      QuerySnapshot querySnapshot =
          await kfirestore.collection(USERS_COLLECTION).get();
      if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
        for (var i = 0; i < querySnapshot.docs.length; i++) {
          _userFilterlist.add(UserModel.fromJson(querySnapshot.docs[i].data()));
        }
        _userlist.addAll(_userFilterlist);
      } else {
        _userlist = null;
      }

      isBusy = false;
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getDataFromDatabase');
    }
  }
}
