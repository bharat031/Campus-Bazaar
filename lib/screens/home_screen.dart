
import '/screens/category/category_widget.dart';
import '/components/main_appbar_with_search.dart';
import '/components/product_listing_widget.dart';
import '/constants/colors.dart';
import '/constants/widgets.dart';
import '/provider/category_provider.dart';
import '/screens/location_screen.dart';
import '/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String screenId = 'home_screen';
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController searchController;
  late CarouselController _controller;
  final int _current = 0;
  late FocusNode searchNode;

  Future<List<String>> downloadBannerImageUrlList() async {
    List<String> bannerUrlList = [];
    final ListResult storageRef =
        await FirebaseStorage.instance.ref().child('banner').listAll();
    List<Reference> bannerRef = storageRef.items;
    await Future.forEach<Reference>(bannerRef, (image) async {
      final String fileUrl = await image.getDownloadURL();
      bannerUrlList.add(fileUrl);
    });
    return bannerUrlList;
  }

  @override
  void initState() {
    searchController = TextEditingController();
    searchNode = FocusNode();
    _controller = CarouselController();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: MainAppBarWithSearch(
            controller: searchController, focusNode: searchNode),
      ),
      body: homeBodyWidget(),
    );
  }

  lcoationAutoFetchBar(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    User? user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(user!.uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return customSnackBar(
              context: context, content: "Something went wrong");
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return customSnackBar(
              context: context, content: "Addrress not selected");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          if (data['address'] == null) {
            Position? position = data['location'];
            getFetchedAddress(context, position).then((location) {
              return locationTextWidget(
                location: location,
              );
            });
          } else {
            return locationTextWidget(location: data['address']);
          }
          return const locationTextWidget(location: 'Update Location');
        }
        return const locationTextWidget(location: 'Fetching location');
      },
    );
  }

  Widget homeBodyWidget() {
    return SingleChildScrollView(
      physics: const ScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: 40,
              child: InkWell(
                onTap: () {
                  // Navigator.of(context).pushNamed(LocationScreen.screenId);
                },
                child: Center(child: lcoationAutoFetchBar(context)),
              ),
            ),
            Container(
              child: const Column(
                children: [
                  CategoryWidget(),
                  // FutureBuilder(
                  //   future: downloadBannerImageUrlList(),
                  //   builder: (BuildContext context,
                  //       AsyncSnapshot<List<String>> snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.waiting) {
                  //       return SizedBox(
                  //         height: 250,
                  //         child: Center(
                  //             child: CircularProgressIndicator(
                  //           color: secondaryColor,
                  //         )),
                  //       );
                  //     } else {
                  //       if (snapshot.hasError) {
                  //         return const Text(
                  //             'Currently facing issue in banner loading');
                  //       } else {
                  //         return Padding(
                  //           padding: const EdgeInsets.symmetric(vertical: 8),
                  //           child: CarouselSlider.builder(
                  //             itemCount: snapshot.data!.length,
                  //             options: CarouselOptions(
                  //               autoPlay: true,
                  //               viewportFraction: 1.0,
                  //             ),
                  //             itemBuilder: (context, index, realIdx) {
                  //               return CachedNetworkImage(
                  //                 imageUrl: snapshot.data![index],
                  //               );
                  //             },
                  //           ),
                  //         );
                  //       }
                  //     }
                  //   },
                  // ),
                ],
              ),
            ),
            const ProductListing()
          ],
        ),
      ),
    );
  }
}

class locationTextWidget extends StatelessWidget {
  final String? location;
  const locationTextWidget({Key? key, required this.location})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.pin_drop,
          size: 18,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          location ?? '',
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
