import 'dart:async';

import '/constants/colors.dart';
import '/provider/product_provider.dart';
import '/screens/chat/user_chat_screen.dart';
import '/services/auth.dart';
import '/services/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart' as launcher;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetail extends StatefulWidget {
  static const screenId = 'product_details_screen';
  const ProductDetail({Key? key}) : super(key: key);

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late GoogleMapController _mapController;
  Auth authService = Auth();
  UserService firebaseUser = UserService();
  bool _loading = true;
  int _index = 0;
  bool isLiked = false;
  List fav = [];
  @override
  void initState() {
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _loading = false;
      });
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    var productProvider = Provider.of<ProductProvider>(context);
    getFavourites(productProvider: productProvider);
    super.didChangeDependencies();
  }

  getFavourites({required ProductProvider productProvider}) {
    authService.products
        .doc(productProvider.productData!.id)
        .get()
        .then((value) {
      if (mounted) {
        setState(() {
          fav = value['favourites'];
        });
      }
      if (fav.contains(firebaseUser.user!.uid)) {
        if (mounted) {
          setState(() {
            isLiked = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLiked = false;
          });
        }
      }
    });
  }

  _mapLauncher(location) async {
    final availableMaps = await launcher.MapLauncher.installedMaps;
    await availableMaps.first.showMarker(
      coords: launcher.Coords(location.latitude, location.longitude),
      title: "Seller Location is here..",
    );
  }

  Future<void> _callLauncher(number) async {
    if (!await launchUrl(number)) {
      throw 'Could not launch $number';
    }
  }

  _createChatRoom(ProductProvider productProvider) {
    Map product = {
      'product_id': productProvider.productData!.id,
      'product_img': productProvider.productData!['images'][0],
      'price': productProvider.productData!['price'],
      'title': productProvider.productData!['title'],
      'seller': productProvider.productData!['seller_uid'],
    };
    List<String> users = [
      productProvider.sellerDetails!['uid'],
      firebaseUser.user!.uid,
    ];
    String chatroomId =
        '${productProvider.sellerDetails!['uid']}.${firebaseUser.user!.uid}${productProvider.productData!.id}';
    Map<String, dynamic> chatData = {
      'users': users,
      'chatroomId': chatroomId,
      'read': false,
      'product': product,
      'lastChat': null,
      'lastChatTime': DateTime.now().microsecondsSinceEpoch,
    };
    firebaseUser.createChatRoom(data: chatData);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => UserChatScreen(
                  chatroomId: chatroomId,
                )));
  }

  _body({
    required DocumentSnapshot<Object?> data,
    required String formattedDate,
    required ProductProvider productProvider,
    required String formattedPrice,
    required GeoPoint location,
    required NumberFormat numberFormat,
  }) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 450,
                        color: Colors.transparent,
                        child: _loading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: secondaryColor,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Loading..',
                                    )
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  Center(
                                    child: Image.network(
                                      data['images'][_index],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      height: 60,
                                      color: whiteColor,
                                      width: MediaQuery.of(context).size.width,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ListView.builder(
                                            physics: const ScrollPhysics(),
                                            scrollDirection: Axis.horizontal,
                                            itemCount: data['images'].length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _index = index;
                                                  });
                                                },
                                                child: Container(
                                                  width: 100,
                                                  color: whiteColor,
                                                  child: Image.network(
                                                      data['images'][index]),
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                      ),
                      _loading
                          ? Container()
                          : Container(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          data['title'].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        if (data['category'] == 'Cars')
                                          Text('[${data['year']}]')
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      '\u{20b9} $formattedPrice',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (data['category'] == 'Cars')
                                      Container(
                                        decoration: BoxDecoration(
                                            color:
                                                disabledColor.withOpacity(0.3),
                                            border: Border.all(
                                                color: blackColor
                                                    .withOpacity(0.3))),
                                        margin: const EdgeInsets.only(top: 10),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 10, bottom: 10),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .filter_alt_outlined,
                                                        color: blackColor,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        data['fuel_type'],
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.av_timer_outlined,
                                                        color: blackColor,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        '${numberFormat.format(int.parse(data['km_driven']))} Km',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .account_tree_outlined,
                                                        color: blackColor,
                                                        size: 12,
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        data[
                                                            'transmission_type'],
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                              Divider(
                                                color: blackColor,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          color: blackColor,
                                                          size: 12,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          '${data['owners']} Owner',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        child: TextButton.icon(
                                                            onPressed: () {},
                                                            icon: Icon(
                                                              Icons
                                                                  .location_on_outlined,
                                                              size: 12,
                                                              color: blackColor,
                                                            ),
                                                            label: Text(
                                                              productProvider
                                                                          .sellerDetails !=
                                                                      null
                                                                  ? productProvider
                                                                          .sellerDetails![
                                                                      'address']
                                                                  : '',
                                                              style:
                                                                  const TextStyle(),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            )),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Text(
                                                              'Posted At'),
                                                          Text(formattedDate
                                                              .toString()),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(data['description']),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 15,
                                                    vertical: 10,
                                                  ),
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  color: disabledColor
                                                      .withOpacity(0.3),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (data['subcategory'] ==
                                                              'Mobile Phones' ||
                                                          data['subcategory'] ==
                                                              null)
                                                        Text(
                                                          'Brand: ${data['brand']}',
                                                          style: TextStyle(
                                                            color: blackColor,
                                                          ),
                                                        ),
                                                      (data['subcategory'] ==
                                                                  'Accessories' ||
                                                              data['subcategory'] ==
                                                                  'Tablets' ||
                                                              data['subcategory'] ==
                                                                  'For Sale: House & Apartments' ||
                                                              data['subcategory'] ==
                                                                  'For Rent: House & Apartments')
                                                          ? Text(
                                                              'Type: ${data['type']}',
                                                              style: TextStyle(
                                                                color:
                                                                    blackColor,
                                                              ),
                                                            )
                                                          : const SizedBox(),
                                                      (data['subcategory'] ==
                                                                  'For Sale: House & Apartments' ||
                                                              data['subcategory'] ==
                                                                  'For Rent: House & Apartments')
                                                          ? Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Bedrooms: ${data['bedroom']}',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        blackColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Bathrooms: ${data['bathroom']}',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        blackColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Furnished Type: ${data['furnishing']}',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        blackColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Construction Status: ${data['construction_status']}',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        blackColor,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Floors: ${data['floors']}',
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        blackColor,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 20),
                                                              ],
                                                            )
                                                          : const SizedBox(),
                                                      Text(
                                                        'Posted At: $formattedDate',
                                                        style: TextStyle(
                                                          color: blackColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      color: blackColor,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: primaryColor,
                                          radius: 40,
                                          child: CircleAvatar(
                                            backgroundColor: secondaryColor,
                                            radius: 37,
                                            child: Icon(
                                              CupertinoIcons.person,
                                              color: whiteColor,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: ListTile(
                                            title: Text(
                                              productProvider
                                                  .sellerDetails!['name']
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // subtitle: Text(
                                            //   'View Profile',
                                            //   style: TextStyle(
                                            //     fontWeight: FontWeight.bold,
                                            //     color: linkColor,
                                            //   ),
                                            // )
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Divider(
                                      color: blackColor,
                                    ),
                                    const Text(
                                      'Ad Post at:',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      height: 200,
                                      color: disabledColor.withOpacity(0.3),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: GoogleMap(
                                              initialCameraPosition:
                                                  CameraPosition(
                                                zoom: 15,
                                                target: LatLng(
                                                  location.latitude,
                                                  location.longitude,
                                                ),
                                              ),
                                              mapType: MapType.normal,
                                              onMapCreated: (GoogleMapController
                                                  controller) {
                                                setState(() {
                                                  _mapController = controller;
                                                });
                                              },
                                            ),
                                          ),
                                          const Center(
                                              child: Icon(
                                            Icons.location_pin,
                                            color: Colors.red,
                                            size: 35,
                                          )),
                                          Center(
                                            child: CircleAvatar(
                                              radius: 60,
                                              backgroundColor:
                                                  blackColor.withOpacity(0.1),
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Material(
                                              elevation: 4,
                                              shape: Border.all(
                                                  color: disabledColor
                                                      .withOpacity(0.2)),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.alt_route_outlined,
                                                ),
                                                onPressed: () async {
                                                  await _mapLauncher(location);
                                                },
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Ad Id: ${data['posted_at']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          child: Text(
                                            'REPORT AD',
                                            style: TextStyle(color: linkColor),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 80,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _bottomSheet({required ProductProvider productProvider}) {
    return BottomAppBar(
      child: Padding(
        padding: (productProvider.productData!['seller_uid'] ==
                firebaseUser.user!.uid)
            ? EdgeInsets.zero
            : const EdgeInsets.all(16),
        child: (productProvider.productData!['seller_uid'] ==
                firebaseUser.user!.uid)
            ? null
            : Row(children: [
                Expanded(
                  child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(secondaryColor)),
                      onPressed: () {
                        _createChatRoom(productProvider);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              size: 16,
                              color: whiteColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Chat',
                            )
                          ],
                        ),
                      )),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(secondaryColor)),
                      onPressed: () async {
                        var phoneNo = Uri.parse(
                            'tel:${productProvider.sellerDetails!['mobile']}');
                        await _callLauncher(phoneNo);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.call,
                              size: 16,
                              color: whiteColor,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Call',
                            )
                          ],
                        ),
                      )),
                )
              ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var productProvider = Provider.of<ProductProvider>(context);
    final numberFormat = NumberFormat('##,##,##0');
    var data = productProvider.productData;
    var price = int.parse(data!['price']);
    var formattedPrice = numberFormat.format(price);
    var date = DateTime.fromMicrosecondsSinceEpoch(data['posted_at']);
    var formattedDate = DateFormat.yMMMd().format(date);
    GeoPoint location = productProvider.sellerDetails!['location'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        title: Text(
          'Product Details',
          style: TextStyle(color: blackColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: blackColor,
            ),
            onPressed: () {},
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  isLiked = !isLiked;
                });
                firebaseUser.updateFavourite(
                  context: context,
                  isLiked: isLiked,
                  productId: data.id,
                );
              },
              color: isLiked ? secondaryColor : disabledColor,
              icon: Icon(
                isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              ))
        ],
      ),
      body: _body(
        data: data,
        formattedDate: formattedDate,
        productProvider: productProvider,
        formattedPrice: formattedPrice,
        location: location,
        numberFormat: numberFormat,
      ),
      bottomSheet: _loading
          ? const SizedBox()
          : _bottomSheet(
              productProvider: productProvider,
            ),
    );
  }
}
