class NotificationModel {
  String updatedAt;
  String type;

  NotificationModel();

  NotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    this.updatedAt = json["updatedAt"];
    this.type = json["type"];
  }
}
