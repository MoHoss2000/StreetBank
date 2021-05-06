class UserModel {
  String key;
  String email;
  String userId;
  String firstName;
  String lastName;
  String phone;
  String createdAt;
  String fcmToken;
  List<String> favoritesList;

  UserModel({
    this.email,
    this.userId,
    this.firstName,
    this.lastName,
    this.createdAt,
    this.fcmToken,
    this.favoritesList,
    this.phone,
  });

  UserModel.fromJson(Map<dynamic, dynamic> map) {
    if (map == null) {
      return;
    }
    if (favoritesList == null) {
      favoritesList = [];
    }
    email = map['email'];
    userId = map['userId'];
    key = map['key'];
    firstName = map['firstName'];
    lastName = map['lastName'];
    phone = map['phone'];
    createdAt = map['createdAt'];
    fcmToken = map['fcmToken'];
    if (map['favoritesList'] != null) {
      favoritesList = List<String>();
      map['favoritesList'].forEach((value) {
        favoritesList.add(value);
      });
    }
  }
  toJson() {
    return {
      'key': key,
      'userId': userId,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      'createdAt': createdAt,
      "favoritesList": favoritesList,
      'fcmToken': fcmToken,
      "phone": phone,
    };
  }

  UserModel copyWith({
    String email,
    String userId,
    String firstName,
    String lastName,
    String phone,
    String createdAt,
    String fcmToken,
    List<String> favoritesList,
    String key,
    bool isVerified,
  }) {
    return UserModel(
      email: email ?? this.email,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      favoritesList: favoritesList ?? this.favoritesList,
    );
  }
}
