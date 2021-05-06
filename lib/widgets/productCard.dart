// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class ProductCard extends StatefulWidget {
//   final DocumentSnapshot productData;
//   final List favorites;

//   const ProductCard({
//     Key key,
//     this.productData,
//     this.favorites,
//   }) : super(key: key);

//   @override
//   _ProductCardState createState() => _ProductCardState();
// }

// class _ProductCardState extends State<ProductCard> {
//   DocumentSnapshot _productData;
//   List _favorites;

//   @override
//   void initState() {
//     super.initState();
//     _favorites = widget.favorites;
//     _productData = widget.productData;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             children: [
//               Hero(
//                 tag: _productData.id,
//                 child: _productData["url"] == ""
//                     ? Image.asset(
//                         "assets/images/no_photo.jpeg",
//                         width: 100,
//                       )
//                     : CachedNetworkImage(
//                         width: 100,
//                         imageUrl: _productData["url"],
//                         placeholder: (context, string) {
//                           return Image.asset("assets/images/placeholder.jpg");
//                         },
//                       ),
//               ),
//               SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _productData['title'],
//                       style: TextStyle(
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.location_on),
//                             SizedBox(width: 5),
//                             Text(_productData['region']),
//                           ],
//                         ),
//                         Expanded(
//                           child: Container(),
//                         ),
//                         IconButton(
//                           alignment: Alignment.centerRight,
//                           onPressed: () {
//                             setState(() {
//                               String productID = _productData.id;
//                               Map productData = _productData.data();
//                               productData["id"] = productID;

//                               if (favorites
//                                   .any((fav) => fav["id"] == productID)) {
//                                 favorites.removeAt(index);
//                                 userFavoritesRef.doc(productID).delete();
//                               } else {
//                                 favorites.add(productData);
//                                 userFavoritesRef
//                                     .doc(productID)
//                                     .set(productData);
//                               }
//                             });
//                           },
//                           icon: Icon(
//                               favorites.any(
//                                       (fav) => fav["id"] == _productData.id)
//                                   ? Icons.favorite
//                                   : Icons.favorite_border,
//                               color: Colors.red),
//                         )
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
