import '/components/product_listing_widget.dart';
import '/components/search_card.dart';
import '/constants/colors.dart';
import '/models/product_model.dart';
import '/provider/product_provider.dart';
import '/screens/product/product_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:search_page/search_page.dart';

class Search {
  searchQueryPage(
      {required BuildContext context,
      required List<Products> products,
      required String address,
      DocumentSnapshot? sellerDetails,
      required ProductProvider provider}) {
    showSearch(
      context: context,
      delegate: SearchPage<Products>(
          barTheme: ThemeData(
              appBarTheme: AppBarTheme(
                  backgroundColor: whiteColor,
                  elevation: 0,
                  surfaceTintColor: primaryColor,
                  iconTheme: IconThemeData(color: blackColor),
                  actionsIconTheme: IconThemeData(color: blackColor))),
          onQueryUpdate: (s) => print(s),
          items: products,
          searchLabel: 'Search cars, mobiles, properties...',
          suggestion: const SingleChildScrollView(child: ProductListing()),
          failure: const Center(
            child: Text('No product found, Please check and try again..'),
          ),
          filter: (product) => [
                product.title,
                product.description,
                product.category,
                product.subcategory,
              ],
          builder: (product) {
            return InkWell(
                onTap: () {
                  provider.setProductDetails(product.document);
                  provider.setSellerDetails(sellerDetails);
                  Navigator.pushNamed(context, ProductDetail.screenId);
                },
                child: SearchCard(
                  product: product,
                  address: address,
                ));
          }),
    );
  }
}
