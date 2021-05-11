import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/models/userModel.dart';
import 'package:streetbank/states/chat/chatState.dart';
import 'package:streetbank/states/searchState.dart';
import 'package:streetbank/widgets/newWidget/customLoader.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductInfo extends StatelessWidget {
  DocumentSnapshot product;
  Map ownerData;

  ProductInfo(product, ownerData) {
    this.product = product;
    this.ownerData = ownerData;
    print(ownerData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getTranslation(context, "product_info"))),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.data()["title"],
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      product.data()["description"],
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 5),
                        Text(product.data()['region']),
                      ],
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Hero(
                        tag: product.id,
                        child: product.data()["url"] == ""
                            ? Image.asset("assets/images/no_photo.jpeg")
                            : CachedNetworkImage(
                                imageUrl: product.data()["url"],
                                placeholder: (context, string) {
                                  return Image.asset(
                                      "assets/images/placeholder.jpg");
                                },
                              ),
                      ),
                    ),
                    Divider(),
                    ownerData["userId"] != FirebaseAuth.instance.currentUser.uid
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              RaisedButton(
                                child:
                                    Text(getTranslation(context, "chat_owner")),
                                onPressed: () {
                                  /// starts chat with owner
                                  final chatState = Provider.of<ChatState>(
                                      context,
                                      listen: false);
                                  final searchState = Provider.of<SearchState>(
                                      context,
                                      listen: false);

                                  UserModel user =
                                      searchState.userlist.firstWhere(
                                    (x) => x.userId == ownerData["userId"],
                                    orElse: () => UserModel(userId: "Unknown"),
                                  );

                                  chatState.setChatUser = user;

                                  Navigator.pushNamed(
                                      context, '/ChatScreenPage');
                                },
                              ),
                              RaisedButton(
                                /// launches phone app to call owner
                                child:
                                    Text(getTranslation(context, "call_owner")),
                                onPressed: () {
                                  launch("tel://${ownerData['phone']}");
                                },
                              ),
                            ],
                          )
                        : Center(
                            child: RaisedButton(
                              child: Text(
                                  getTranslation(context, "delete_product")),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                      title: Text(
                                          "Are you sure you want to delete this product?"),
                                      content: Text(
                                          "This action is permanent and can't be reverted. Your product will no longer be visible to other users."),
                                      actions: [
                                        FlatButton(
                                          /// cancel deletion
                                          child: Text("Cancel"),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        FlatButton(
                                          /// confirm delete
                                          child: Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () async {
                                            CustomLoader loader =
                                                CustomLoader();
                                            loader.showLoader(context);
                                            await deleteProduct(context);
                                            loader.hideLoader();
                                            Navigator.pop(
                                                context); //exit dialog
                                            Navigator.pop(
                                                context); //go to products page
                                          },
                                        ),
                                      ]),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deleteProduct(context) async {
    String imageURL = product.data()["url"];
    if (imageURL != "") {
      /// if product has an image then delete from cloud storage
      await FirebaseStorage.instance.refFromURL(imageURL).delete();
    }

    /// delete product from firestore
    await product.reference.delete();
  }
}
