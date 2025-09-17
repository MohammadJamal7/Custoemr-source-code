import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../constant/constant.dart';
import '../../model/driver_document_model.dart';
import '../../model/review_model.dart';
import '../../model/user_model.dart';
import '../../themes/app_colors.dart';
import '../../utils/DarkThemeProvider.dart';
import '../../utils/fire_store_utils.dart';
import '../../widget/firebase_pagination/src/firestore_pagination.dart';

class ReviewsScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String orders;

  const ReviewsScreen(
      {super.key,
      required this.driverId,
      required this.driverName,
      required this.orders});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  int count = 0;
  bool isLoad = true;

  @override
  void initState() {
    getTrips();
    super.initState();
  }

  void getTrips() async {
    isLoad = true;
    count =
        await FireStoreUtils.getOrderCountForDriver(widget.driverId.toString());
    isLoad = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: AppColors.primary,
        title: Text(widget.driverName),
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back,
          ),
        ),
        actions: [
          if(!isLoad)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text(
              "${"numOrders".tr} : $count",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          if(isLoad)
            Container(
              margin: const EdgeInsets.all(8),
              height: 20,
              child: Constant.loader(),
            ),
        ],
      ),
      body: Column(
        children: [
          // car images
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FutureBuilder<DriverDocumentModel?>(
              future: FireStoreUtils.getDocumentOfDriver(id: widget.driverId),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    // todo show skeleton
                    return const SizedBox();
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      //  show image error
                      return const SizedBox();
                    } else {
                      if (snapshot.data == null) {
                        // todo show skeleton
                        return const SizedBox();
                      } else {
                        DriverDocumentModel driverDocs = snapshot.requireData!;
                        final String imageUrl = driverDocs.documents!
                                .firstWhere((e) =>
                                    e.documentId == 'VI2hkuhDVGNJeu3TyIhS')
                                .frontImage ??
                            '';
                        final String imageUrl2 = driverDocs.documents!
                                .firstWhere((e) =>
                                    e.documentId == 'hf07c4pI2qMIjPU6ctYH')
                                .frontImage ??
                            '';
                        // todo show images
                        print('--------- ${widget.driverId}');
                        return Container(
                          height: 100,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            spacing: 10,
                            children: [
                              // car exterior image
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    imageBuilder: (context, provider) {
                                      return InstaImageViewer(
                                        child: Image(
                                          image: provider,
                                          width: double.infinity,
                                          fit: BoxFit.fitWidth,
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      padding: const EdgeInsets.all(24),
                                      width: double.infinity,
                                      height: 100,
                                      child: const Icon(Icons.error),
                                    ),
                                    placeholder: (context, url) => SizedBox(
                                      height: 100,
                                      child: Constant.loader(),
                                    ),
                                  ),
                                ),
                              ),
                              // car interior image

                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl2,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    imageBuilder: (context, provider) {
                                      return InstaImageViewer(
                                        child: Image(
                                          image: provider,
                                          width: double.infinity,
                                          fit: BoxFit.fitWidth,
                                        ),
                                      );
                                    },
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      padding: const EdgeInsets.all(24),
                                      width: double.infinity,
                                      height: 100,
                                      child: const Icon(Icons.error),
                                    ),
                                    placeholder: (context, url) => SizedBox(
                                      height: 100,
                                      child: Constant.loader(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        return const SizedBox();
                      }
                    }
                  default:
                    return const Text('Error');
                }
              },
            ),
          ),
          Expanded(
            child: FirestorePagination(
              query: FireStoreUtils.getReviewsQuery(widget.driverId),
              //key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
              padding: const EdgeInsets.all(10),
              limit: 10,
              onEmpty: Center(
                child: Text("No review found".tr),
              ),
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 10);
              },
              initialLoader: Constant.loader(),
              itemBuilder: (context, docs, index) {
                print(docs);
                final review = ReviewModel.fromFirestore(docs[index]);
                return Container(
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBackground
                        : AppColors.containerBackground,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    border: Border.all(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBorder
                            : AppColors.containerBorder,
                        width: 0.5),
                    boxShadow: themeChange.getThem()
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 5,
                              offset: const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: FutureBuilder<UserModel?>(
                      future: FireStoreUtils.getUserProfile(
                          review.customerId.toString()),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  child: CachedNetworkImage(
                                    height: 50,
                                    width: 50,
                                    imageUrl: Constant.userPlaceHolder,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Constant.loader(),
                                    errorWidget: (context, url, error) =>
                                        Image.network(
                                      Constant.userPlaceHolder,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Asynchronous user",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(
                                              review.date!.toDate(),
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 22,
                                            color: AppColors.ratingColour,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            Constant.calculateReview(
                                                reviewCount: "0.0",
                                                reviewSum: "0.0"),
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (review.comment != null &&
                                          review.comment!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(review.comment!),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          case ConnectionState.done:
                            if (snapshot.hasError) {
                              return Text(snapshot.error.toString());
                            } else {
                              if (snapshot.data == null) {
                                return SizedBox();
                              }
                              UserModel userModel = snapshot.data!;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    child: CachedNetworkImage(
                                      height: 50,
                                      width: 50,
                                      imageUrl: userModel.profilePic.toString(),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Constant.loader(),
                                      errorWidget: (context, url, error) =>
                                          Image.network(
                                              Constant.userPlaceHolder),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                userModel.fullName.toString(),
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(
                                                review.date!.toDate(),
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 22,
                                              color: AppColors.ratingColour,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              review.rating ?? '0.0',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (review.comment != null &&
                                            review.comment!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(review.comment!),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          default:
                            return const Text('Error');
                        }
                      }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
