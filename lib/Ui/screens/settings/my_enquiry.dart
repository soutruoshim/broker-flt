import '../home/Widgets/property_horizontal_card.dart';
import '../widgets/Erros/no_data_found.dart';
import '../widgets/Erros/something_went_wrong.dart';
import '../../../app/routes.dart';
import '../../../data/cubits/enquiry/delete_enquiry_cubit.dart';
import '../../../data/cubits/enquiry/enquiry_status_cubit.dart';
import '../../../data/cubits/enquiry/fetch_my_enquiry_cubit.dart';
import '../../../utils/Extensions/extensions.dart';
import '../../../data/model/enquiry_status.dart';
import '../../../data/model/property_model.dart';
import '../../../utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//used for propertyData.toList().firstWhereOrNull
import '../../../data/cubits/favorite/add_to_favorite_cubit.dart';
import '../../../data/cubits/favorite/fetch_favorites_cubit.dart';
import '../../../data/helper/widgets.dart';
import '../../../utils/constant.dart';
import '../../../utils/helper_utils.dart';
import '../../../utils/ui_utils.dart';
import '../widgets/AnimatedRoutes/blur_page_route.dart';
import '../widgets/Erros/no_internet.dart';
import '../widgets/blurred_dialoge_box.dart';
import '../widgets/shimmerLoadingContainer.dart';

class MyEnquiry extends StatefulWidget {
  const MyEnquiry({Key? key}) : super(key: key);

  @override
  MyEnquiryState createState() => MyEnquiryState();

  static Route route(RouteSettings routeSettings) {
    // Map? arguments = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (_) => const MyEnquiry(),
    );
  }
}

class MyEnquiryState extends State<MyEnquiry> with TickerProviderStateMixin {
  //List<Property> propertyData = [];
  List enquiryData = [];

  final ScrollController _pageScrollController = ScrollController();
  bool isLoadingShowing = false;
// 0 : Pending 1:Accept 2: Complete 3:Cancle
  late Map<int, dynamic> statusMap;
  late Map<int, Color> statusColorMap;

  @override
  void initState() {
    super.initState();

    statusColorMap = {
      0: Colors.purple,
      1: Colors.green,
      2: Colors.blue,
      3: Colors.red,
    };
    Future.delayed(
      Duration.zero,
      () => statusMap = {
        0: UiUtils.getTranslatedLabel(context, "pendingLbl"),
        1: UiUtils.getTranslatedLabel(context, "acceptLbl"),
        2: UiUtils.getTranslatedLabel(context, "completeLbl"),
        3: UiUtils.getTranslatedLabel(context, "cancelLbl"),
      },
    );

    _pageScrollController.addListener(pageScrollListen);
    Future.delayed(Duration.zero, () {
      context.read<FetchMyEnquiryCubit>().fetchMyEnquiry();
      // context.read<EnquiryStatusCubit>().getEnquiryStatus(
      //       context,
      //     );
    });
  }

  @override
  void didChangeDependencies() {
    statusMap = {
      0: UiUtils.getTranslatedLabel(context, "pendingLbl"),
      1: UiUtils.getTranslatedLabel(context, "acceptLbl"),
      2: UiUtils.getTranslatedLabel(context, "completeLbl"),
      3: UiUtils.getTranslatedLabel(context, "cancelLbl"),
    };
    super.didChangeDependencies();
  }

  void pageScrollListen() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchMyEnquiryCubit>().hasMoreData()) {
        context.read<FetchMyEnquiryCubit>().fetchMyEnquiryMore();
      }
    }
    // if (_pageScrollController.offset == 0) {
    //   HapticFeedback.lightImpact();
    // } else if (_pageScrollController.isEndReached()) {
    //   HapticFeedback.lightImpact();
    // }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    Routes.currentRoute = Routes.previousCustomerRoute;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: UiUtils.buildAppBar(context,
          showBackButton: true,
          title: UiUtils.getTranslatedLabel(context, "myEnquiry")),
      body: BlocBuilder<FetchMyEnquiryCubit, FetchMyEnquiryState>(
          builder: (context, state) {
        if (state is FetchMyEnquiryInProgress) {
          return buildMyPropertyShimmer();
        } else if (state is FetchMyEnquirySuccess) {
          enquiryData = state.myEnquiries;
          return enquiriesList(state);
        } else if (state is FetchMyEnquiryFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage.error == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchMyEnquiryCubit>().fetchMyEnquiry();
                },
              );
            }
          }
          return const SomethingWentWrong();
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }

  bool isSameStatus(int index, String sttauts, EnquiryStatusSuccess state) {
    bool isSameStatus = true;
    if (index == 0) {
      isSameStatus = false;
    } else {
      final String s = state.enquiryStatusList[index - 1].status.toString();

      isSameStatus = sttauts == s;
    }
    return isSameStatus;
  }

  Widget buildMyPropertyShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      itemCount: 5,
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ClipRRect(
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  child: CustomShimmer(height: 90, width: 90),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(
                          height: 10,
                        ),
                        CustomShimmer(
                          height: 10,
                          width: c.maxWidth - 50,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const CustomShimmer(
                          height: 10,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomShimmer(
                          height: 10,
                          width: c.maxWidth / 1.2,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CustomShimmer(
                            width: c.maxWidth / 4,
                          ),
                        ),
                      ],
                    );
                  }),
                )
              ]),
        );
      },
    );
  }

  Widget enquiriesList(FetchMyEnquirySuccess state) {
    if (state.myEnquiries.isEmpty) {
      return NoDataFound(
        onTap: () {
          context.read<FetchMyEnquiryCubit>().fetchMyEnquiry();
        },
      );
    }
    return Column(
      children: <Widget>[
        Expanded(
          child: ScrollConfiguration(
            behavior: RemoveGlow(),
            child: ListView.separated(
                controller: _pageScrollController,
                padding: const EdgeInsets.all(10),
                separatorBuilder: (context, index) => const SizedBox(),
                shrinkWrap: true,
                itemCount: state.myEnquiries.length,
                itemBuilder: (context, index) {
                  state.myEnquiries
                      .sort((a, b) => a.status!.compareTo(b.status!));
                  EnquiryStatus enquiryStatus = state.myEnquiries[index];

                  return BlocProvider(
                    create: (context) => DeleteEnquiryCubit(),
                    child: _buildItem(enquiryStatus.property!, index, state),
                  );
                }),
          ),
        ),
        if (state.isLoadingMore) UiUtils.progress()
      ],
    );
  }

  _buildItem(
      PropertyModel property, int indexOfStatus, FetchMyEnquirySuccess state) {
    return BlocListener<DeleteEnquiryCubit, DeleteEnquiryState>(
      listener: (context, state) {
        if (state is DeleteEnquiryInProgress) {
          Widgets.showLoader(context);
        }
        if (state is DeleteEnquirySuccess) {
          Widgets.hideLoder(context);
          context.read<FetchMyEnquiryCubit>().removeEnquriy(state.id);
        }
        if (state is DeleteEnquiryFailure) {
          Widgets.hideLoder(context);
        }
      },
      child: Builder(builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.propertyDetails,
              arguments: {
                'propertyData': property,
                'propertiesList': [],
                'fromMyProperty': false
              },
            );
          },
          child: PropertyHorizontalCard(
            property: property,
            additionalHeight: 50,
            onDeleteTap: () async {
              var delete = await UiUtils.showBlurredDialoge(
                context,
                dialoge: BlurredDialogBox(
                  title: UiUtils.getTranslatedLabel(context, "deleteBtnLbl"),
                  content: Text(
                    UiUtils.getTranslatedLabel(context, "deleteEnquiryMessage"),
                  ),
                ),
              );

              if (delete == true) {
                Future.delayed(
                  Duration.zero,
                  () {
                    if (Constant.isDemoModeOn) {
                      HelperUtils.showSnackBarMessage(
                          context,
                          UiUtils.getTranslatedLabel(
                              context, "thisActionNotValidDemo"));
                    } else {
                      context.read<DeleteEnquiryCubit>().deleteEnquiry(
                          int.parse(enquiryData[indexOfStatus].id!));
                    }
                  },
                );
              }
            },
            showDeleteButton: true,
            useRow: true,
            onLikeChange: (FavoriteType type) {
              if (type == FavoriteType.add) {
                context.read<FetchFavoritesCubit>().add(
                      state.myEnquiries[indexOfStatus].property!,
                    );
              } else {
                context
                    .read<FetchFavoritesCubit>()
                    .remove(state.myEnquiries[indexOfStatus].property!.id);
              }
            },
            // addBottom: [
            //   SizedBox(
            //     width: 10.rw(context),
            //   ),
            //   // Chip(
            //   //   backgroundColor: statusColorMap[
            //   //       int.parse(enquiryData[indexOfStatus].status!)],
            //   //   label: Text(
            //   //           statusMap[int.parse(enquiryData[indexOfStatus].status!)]
            //   //               .toString())
            //   //       .color(context.color.buttonColor)
            //   //       .size(context.font.small),
            //   // ),
            //   SizedBox(
            //     width: 10.rw(context),
            //   ),
            //   const Spacer(),
            //   GestureDetector(
            //     onTap: () {
            //       context
            //           .read<DeleteEnquiryCubit>()
            //           .deleteEnquiry(int.parse(enquiryData[indexOfStatus].id!));
            //     },
            //     child: FittedBox(
            //       fit: BoxFit.none,
            //       child: UiUtils.buildButton(context, onPressed: () async {

            //       },
            //           width: 100,
            //           height: 30.rh(context),
            //           radius: 10,
            //           fontSize: context.font.normal,
            //           buttonTitle:
            //               UiUtils.getTranslatedLabel(context, "deleteBtnLbl")),
            //     ),
            //   ),
            //   SizedBox(
            //     width: 10.rw(context),
            //   ),
            // ],
          ),
        );
      }),
    );
  }
}
