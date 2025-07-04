import '/components/product_listing_widget.dart';
import '/constants/colors.dart';
import '/provider/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductByCategory extends StatelessWidget {
  static const String screenId = 'product_by_category';
  const ProductByCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: whiteColor,
          iconTheme: IconThemeData(
            color: blackColor,
          ),
          title: Text(
            (categoryProvider.selectedSubCategory == null)
                ? 'Cars'
                : '${categoryProvider.selectedCategory} ${categoryProvider.selectedCategory == 'Cars' ? '' : '> ${categoryProvider.selectedSubCategory}'}',
            style: TextStyle(
              color: blackColor,
            ),
          ),
        ),
        body: const SingleChildScrollView(
            child: ProductListing(
          isProductByCategory: true,
        )));
  }
}
