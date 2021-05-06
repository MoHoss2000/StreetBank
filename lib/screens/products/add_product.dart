import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/states/authState.dart';
import 'package:streetbank/widgets/customWidgets.dart';
import 'package:streetbank/widgets/processDialog.dart';

class AddProduct extends StatefulWidget {
  final String type;

  AddProduct({
    Key key,
    @required this.type,
  }) : super(key: key);

  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController productTitleController = TextEditingController();
  final TextEditingController productDescriptionController =
      TextEditingController();

  PickedFile imageFile; // product image to upload
  String region = ""; // product region

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslation(context, "add_product")),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Container(
            child: Column(
              children: [
                TextField(
                  controller: productTitleController,
                  decoration: InputDecoration(
                      hintText: getTranslation(context, "title")),
                ),
                SizedBox(height: 20),
                TextField(
                  maxLength: 1000,
                  decoration: InputDecoration(
                      hintText: getTranslation(context, "description")),
                  minLines: 2,
                  maxLines: 8,
                  controller: productDescriptionController,
                ),
                SearchableDropdown(
                  onChanged: (value) {
                    region = value;
                  },
                  hint: getTranslation(context, "region"),
                  isExpanded: true,
                  items: getRegionsList(),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RaisedButton(
                      child: Text(
                        getTranslation(context, "upload_photo"),
                        style: TextStyle(fontSize: 20),
                      ),
                      onPressed: () async {
                        /// choose image from gallery and compress it to reduce size
                        var imagePath = await ImagePicker().getImage(
                            source: ImageSource.gallery, imageQuality: 50);
                        setState(() {
                          imageFile = imagePath;
                        });
                      },
                    ),
                    RaisedButton(
                      child: Text(
                        getTranslation(context, "post"),
                        style: TextStyle(fontSize: 20),
                      ),
                      onPressed: () {
                        if (productTitleController.text.isEmpty) {
                          displayToastMessage(
                              "Please add a title for your product", context);
                        } else if (productDescriptionController.text.length <
                            5) {
                          displayToastMessage(
                              "Description must be at least 5 characters",
                              context);
                        } else if (region == "") {
                          displayToastMessage("Choose a region", context);
                        } else
                          addProduct(context);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(child: previewImage()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget previewImage() {
    if (imageFile != null) {
      return Image.file(
        File(imageFile.path),
        alignment: Alignment.center,
      );
    } else {
      return Text(
        getTranslation(context, "no_image"),
        textAlign: TextAlign.center,
      );
    }
  }

  /// uploads image to cloud storage
  Future<UploadTask> uploadFile(PickedFile file) async {
    if (file == null) {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text("No file was selected")));
      return null;
    }

    UploadTask uploadTask;

    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('products')
        .child(DateTime.now().millisecondsSinceEpoch.toString());

    final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path});

    uploadTask = ref.putFile(File(file.path), metadata);
    return Future.value(uploadTask);
  }

  void addProduct(BuildContext context) async {
    /// dialog shows while adding the product and uploading image
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProgressDialog("Posting...");
        });

    var state = Provider.of<AuthState>(context, listen: false);

    Map<String, dynamic> productDataMap = {
      "title": productTitleController.text,
      "description": productDescriptionController.text,
      "userID": FirebaseAuth.instance.currentUser.uid,
      "region": region,
      "timestamp": FieldValue.serverTimestamp(),
      "type": widget.type,
      "url": "", // if no image the url will be empty string
      "user": state.userModel.toJson(),
    };

    CollectionReference productsCol =
        FirebaseFirestore.instance.collection("products");

    if (imageFile != null) {
      /// if user chose image then upload
      UploadTask uploadTask = await uploadFile(imageFile);

      /// after upload get the url and save it in the product document in Firestore
      uploadTask.then((TaskSnapshot snapshot) async {
        String url = await snapshot.ref.getDownloadURL();
        productDataMap["url"] = url;

        /// upload to Firestore
        await productsCol.add(productDataMap).catchError((error) {
          displayToastMessage("An error occured", context);
          return Navigator.pop(context);
        });

        Navigator.pop(context); // to return to `product-list` screen
        Navigator.pop(context);
      });

      uploadTask.catchError((error) {
        displayToastMessage("An error occured", context);
        return Navigator.pop(context);
      });
    } else {
      /// if no image then just add to firestore
      await productsCol.add(productDataMap).catchError((error) {
        displayToastMessage("An error occured", context);
        return Navigator.pop(context);
      });

      Navigator.pop(context);
      Navigator.pop(context);
    }
  }
}
