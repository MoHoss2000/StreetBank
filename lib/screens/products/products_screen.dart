import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

import 'package:streetbank/helper/constants.dart';
import 'package:streetbank/helper/utility.dart';
import 'package:streetbank/screens/products/product_info.dart';

import 'add_product.dart';

class ProductsScreen extends StatefulWidget {
  final String productType;
  bool favoritesOnly; // used to use the screen to show favorited products only

  ProductsScreen({
    Key key,
    this.productType,
    this.favoritesOnly = false,
  }) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  DocumentReference currentUserRef;
  List favorites = ["null"];

  String searchTerm = "";

  int _limit = 10;
  final int _limitIncrement = 10;

  final ScrollController listScrollController = ScrollController();

  Stream<QuerySnapshot> stream;

  String regionFilter = "";

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      print("reach the bottom");
      setState(() {
        print("reach the bottom");
        _limit += _limitIncrement;

        /// limit of products shown in the screen
        /// when the user scrolls to end of page
        /// the limit is incremented to show
        /// more products
      });
    }
    if (listScrollController.offset <=
            listScrollController.position.minScrollExtent &&
        !listScrollController.position.outOfRange) {
      print("reach the top");
      // setState(() {
      //   print("reach the top");
      // });
    }
  }

  @override
  void initState() {
    listScrollController.addListener(_scrollListener);

    currentUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser.uid);

    currentUserRef.get().then((DocumentSnapshot s) {
      setState(() {
        /// fetch the favorited products' ids and save them in local var
        favorites = s.data()["favoritesList"];
        if (favorites == null || favorites.isEmpty) favorites = ["null"];
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(favorites);
    var _collection = widget.favoritesOnly
        ?

        /// shows all products that their IDs exists in the user's favorite list
        /// does not filter out any product type
        FirebaseFirestore.instance
            .collection("products")
            .where(FieldPath.documentId, whereIn: favorites)

        ///shows all products in  a certain category ordered by timestamp
        : FirebaseFirestore.instance
            .collection("products")
            .where("type", isEqualTo: widget.productType)
            .orderBy("timestamp", descending: true);

    Stream stream = regionFilter != ""

        /// if region filter is applied, fetch only products
        /// from this region
        ? _collection
            .where("region", isEqualTo: regionFilter)
            .limit(_limit)
            .snapshots()
        : _collection.limit(_limit).snapshots();

    return Scaffold(
      floatingActionButton: widget.favoritesOnly

          /// hide addproducts button if the screen is
          /// loaded for fav only
          ? null
          : RaisedButton(
              // splashColor: Colors.blueGrey,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
              shape: CircleBorder(),
              color: Theme.of(context).accentColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProduct(
                      type: widget.productType,
                    ),
                  ),
                );
              },
            ),
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() {
              searchTerm = value;
            });
          },
          decoration: InputDecoration(
            hintText: getTranslation(context, "search"),
            icon: Icon(Icons.search),
          ),
        ),
        actions: [
          /// region filter button
          PopupMenuButton(
            itemBuilder: (context) {
              List<PopupMenuItem> list = [];
              list.add(PopupMenuItem(
                child: SearchableDropdown(
                  items: getRegionsList(),
                  onClear: () {
                    setState(() {
                      regionFilter = "";
                    });
                  },
                  hint: getTranslation(context, "region"),
                  displayClearIcon: true,
                  onChanged: (value) {
                    setState(() {
                      regionFilter = value;
                    });
                  },
                ),
              ));
              return list;
            },
            icon: Icon(Icons.filter_list_alt),
          )
        ],
      ),
      body: StreamBuilder(
        stream: stream,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            List<DocumentSnapshot> data = snapshot.data.docs;

            if (data.isEmpty)
              return Center(
                  child: Text("No products available in this category"));

            /// this list contains only items that match the search criteria
            List<DocumentSnapshot> item = [];

            if (searchTerm != "") {
              for (DocumentSnapshot i in data) {
                if (i
                    .data()["title"]
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase())) {
                  item.add(i);
                }
              }
            } else
              item = data; // if no search then it holds all data

            return ListView.builder(
              controller: listScrollController,
              itemCount: item.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    var ownerData = item[index].data()["user"];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ProductInfo(item[index], ownerData);
                        },
                      ),
                    );
                  },
                  child: ListTile(
                    title: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Hero(
                              tag: item[index].id,
                              child: item[index]["url"] == ""
                                  ?

                                  /// product is uploaded with no photo
                                  /// loads static photo
                                  Image.asset(
                                      "assets/images/no_photo.jpeg",
                                      width: 100,
                                    )

                                  /// fetches photo from Cloud Storage
                                  : CachedNetworkImage(
                                      width: 100,
                                      imageUrl: item[index]["url"],
                                      placeholder: (context, string) {
                                        return Image.asset(
                                            "assets/images/placeholder.jpg");
                                      },
                                    ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item[index]['title'],
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on),
                                          SizedBox(width: 5),
                                          Text(item[index]['region']),
                                        ],
                                      ),
                                      Expanded(
                                        child: Container(),
                                      ),
                                      IconButton(
                                        alignment: Alignment.centerRight,
                                        onPressed: () {
                                          setState(() {
                                            String productID = item[index].id;
                                            Map productData =
                                                item[index].data();
                                            productData["id"] = productID;

                                            /// if already favorited, remove it
                                            /// else add to the list
                                            favorites.contains(productID)
                                                ? favorites.remove(productID)
                                                : favorites.add(productID);

                                            /// update the db to account
                                            /// for the change in favorites
                                            currentUserRef.update(
                                                {"favoritesList": favorites});
                                          });
                                        },
                                        icon: Icon(
                                            favorites.contains(item[index].id)

                                                /// if product is favorited
                                                /// show filled heart icon
                                                /// else, only show red oultine
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          } else
            return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
