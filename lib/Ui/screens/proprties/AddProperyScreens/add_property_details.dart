import 'dart:developer';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/routes.dart';
import '../../../../data/Repositories/property_repository.dart';
import '../../../../data/model/category.dart';
import '../../../../data/model/property_model.dart';
import '../../../../utils/AppIcon.dart';
import '../../../../utils/Extensions/extensions.dart';
import '../../../../utils/constant.dart';
import '../../../../utils/helper_utils.dart';
import '../../../../utils/imagePicker.dart';
import '../../../../utils/responsiveSize.dart';
import '../../../../utils/ui_utils.dart';
import '../../widgets/AnimatedRoutes/blur_page_route.dart';
import '../../widgets/blurred_dialoge_box.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/panaroma_image_view.dart';

class AddPropertyDetails extends StatefulWidget {
  final Map? properyDetails;

  const AddPropertyDetails({super.key, this.properyDetails});

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return AddPropertyDetails(
          properyDetails: arguments?['details'],
        );
      },
    );
  }

  @override
  State<AddPropertyDetails> createState() => _AddPropertyDetailsState();
}

class _AddPropertyDetailsState extends State<AddPropertyDetails> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  late final TextEditingController _propertyNameController =
      TextEditingController(text: widget.properyDetails?['name']);
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.properyDetails?['desc']);
  late final TextEditingController _cityNameController =
      TextEditingController(text: widget.properyDetails?['city']);
  late final TextEditingController _stateNameController =
      TextEditingController(text: widget.properyDetails?['state']);
  late final TextEditingController _countryNameController =
      TextEditingController(text: widget.properyDetails?['country']);
  late final TextEditingController _latitudeController =
      TextEditingController(text: widget.properyDetails?['latitude']);
  late final TextEditingController _longitudeController =
      TextEditingController(text: widget.properyDetails?['longitude']);
  late final TextEditingController _addressController =
      TextEditingController(text: widget.properyDetails?['address']);
  late final TextEditingController _priceController =
      TextEditingController(text: widget.properyDetails?['price']);
  late final TextEditingController _clientAddressController =
      TextEditingController(text: widget.properyDetails?['client']);

  late final TextEditingController _videoLinkController =
      TextEditingController();

  Map propertyData = {};
  final PickImage _pickTitleImage = PickImage();
  final PickImage _propertisImagePicker = PickImage();
  final PickImage _pick360deg = PickImage();
  List editPropertyImageList = [];
  String titleImageURL = "";
  String selectedRentType = "Monthly";
  List removedImageId = [];

  List<dynamic> mixedPropertyImageList = [];

  @override
  void initState() {
    titleImageURL = widget.properyDetails?['titleImage'] ?? "";
    // editPropertyImageList = widget.properyDetails?['images'] ?? [];
    mixedPropertyImageList =
        List<dynamic>.from(widget.properyDetails?['images'] ?? []);
    if ((widget.properyDetails != null)) {
      selectedRentType = widget.properyDetails?['rentduration'] ?? "Monthly";
    }

    _propertisImagePicker.listener((images) {
      // if (editPropertyImageList.isNotEmpty) {
      //   editPropertyImageList.clear();
      // }
      log(images.toString(), name: "IMAGE1");
      // if (images is List<File>) {
      // log("WHAT IS THE  $propertyImageList");

      try {
        mixedPropertyImageList.addAll(List<dynamic>.from(images));
      } catch (e) {
        log(e.toString(), name: "ISSUE");
      }
      // propertyImageList.addAll(List.from(images));
      //}
      log(mixedPropertyImageList.toString(), name: "IMAGE");
      setState(() {});
    });
    _pickTitleImage.listener((p0) {
      titleImageURL = "";
      WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
        // log("CALLED TITLE IMAGE ${_pickTitleImage.subscription?.isPaused} ${( _pickTitleImage.subscription?.isPaused)==false}");
        if (mounted) setState(() {});
      });
    });
    super.initState();
  }

  void _onTapChooseLocation(FormFieldState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    Map? placeMark =
        await Navigator.pushNamed(context, Routes.chooseLocaitonMap) as Map?;
    var latlng = placeMark?['latlng'] as LatLng?;
    Placemark? place = placeMark?['place'] as Placemark?;
    log("place $placeMark ");
    if (latlng != null && place != null) {
      _latitudeController.text = latlng.latitude.toString();
      _longitudeController.text = latlng.longitude.toString();
      _cityNameController.text = place.locality ?? "";
      _countryNameController.text = place.country ?? "";
      _stateNameController.text = place.administrativeArea ?? "";
      _addressController.text = "";
      _addressController.text = getAddress(place);
      // log(City().get());
      state.didChange(true);
    } else {
      // state.didChange(false);
    }
  }

  String getAddress(Placemark place) {
    try {
      String address = "";
      log((place.street == null).toString(), name: "##SD");
      if (place.street == null && place.subLocality != null) {
        address = place.subLocality!;
      } else if (place.street == null && place.subLocality == null) {
        address = "";
      } else {
        address = "${place.street ?? ""},${place.subLocality ?? ""}";
      }

      return address;
    } catch (e, st) {
      log(e.toString());
      throw Exception("E $st");
    }
  }

  void _onTapContinue() async {
    File? titleImage;
    File? v360Image;
    if (_pickTitleImage.pickedFile != null) {
      // final mimeType = lookupMimeType(_pickTitleImage.pickedFile!.path);
      // var extension = mimeType!.split("/");

      titleImage = _pickTitleImage.pickedFile;
    }

    if (_pick360deg.pickedFile != null) {
      // final mimeType = lookupMimeType(_pick360deg.pickedFile!.path);
      // var extension = mimeType!.split("/");

      v360Image = _pick360deg.pickedFile;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState?.save();
      bool check = _checkIfLocationIsChosen();
      if (check == false) {
        Future.delayed(
          Duration.zero,
          () {
            UiUtils.showBlurredDialoge(
              context,
              sigmaX: 5,
              sigmaY: 5,
              dialoge: BlurredDialogBox(
                svgImagePath: AppIcons.warning,
                title: UiUtils.getTranslatedLabel(context, "incomplete"),
                showCancleButton: false,
                onAccept: () async {},
                acceptTextColor: context.color.buttonColor,
                content: Text(
                  UiUtils.getTranslatedLabel(context, "addressError"),
                ),
              ),
            );
          },
        );

        return;
      } else if (titleImage == null && titleImageURL == "") {
        Future.delayed(
          Duration.zero,
          () {
            UiUtils.showBlurredDialoge(context,
                sigmaX: 5,
                sigmaY: 5,
                dialoge: BlurredDialogBox(
                    svgImagePath: AppIcons.warning,
                    title: UiUtils.getTranslatedLabel(context, "incomplete"),
                    showCancleButton: false,
                    acceptTextColor: context.color.buttonColor,
                    onAccept: () async {
                      // Navigator.pop(context);
                    },
                    content: Text(UiUtils.getTranslatedLabel(
                        context, "uploadImgMsgLbl"))));
          },
        );
        return;
      }

      var list = mixedPropertyImageList.map((e) {
        if (e is File) {
          return e;
        }
      }).toList()
        ..removeWhere((element) => element == null);

      log(list.toString());
      // return;

      propertyData.addAll({
        "title": _propertyNameController.text,
        "description": _descriptionController.text,
        "city": _cityNameController.text,
        "state": _stateNameController.text,
        "country": _countryNameController.text,
        "latitude": _latitudeController.text,
        "longitude": _longitudeController.text,
        "address": _addressController.text,
        "client_address": _clientAddressController.text,
        "price": _priceController.text,
        "title_image": titleImage,
        "gallery_images": list,
        "remove_gallery_images": removedImageId,
        // "category_id": 1,
        "category_id": widget.properyDetails == null
            ? (Constant.addProperty['category'] as Category).id
            : widget.properyDetails?['catId'],
        // "property_type": 1,
        "property_type": widget.properyDetails == null
            ? (Constant.addProperty['propertyType'] as PropertyType).value
            : widget.properyDetails?['propType'],
        "package_id": Constant.subscriptionPackageId,
        "threeD_image": v360Image,
        "video_link": _videoLinkController.text,
        if ((widget.properyDetails == null
                    ? (Constant.addProperty['propertyType'] as PropertyType)
                        .name
                    : widget.properyDetails?['propType'])
                .toString()
                .toLowerCase() ==
            "rent")
          "rentduration": selectedRentType,
      });

      if (widget.properyDetails?.containsKey("assign_facilities") ?? false) {
        propertyData?["assign_facilities"] =
            widget.properyDetails!['assign_facilities'];
      }
      if (widget.properyDetails != null) {
        propertyData['id'] = widget.properyDetails?['id'];
        propertyData['action_type'] = "0";
      }

      Future.delayed(
        Duration.zero,
        () {
          _pickTitleImage.pauseSubscription();

          Navigator.pushNamed(
            context,
            Routes.setPropertyParametersScreen,
            arguments: {
              "details": propertyData,
              "isUpdate": (widget.properyDetails != null)
            },
          ).then((value) {
            _pickTitleImage.resumeSubscription();
          });
        },
      );
    }
  }

  bool _checkIfLocationIsChosen() {
    if (_cityNameController.text == "" ||
        _stateNameController.text == "" ||
        _countryNameController.text == "" ||
        _latitudeController.text == "" ||
        _longitudeController.text == "") {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _propertyNameController.dispose();
    _descriptionController.dispose();
    _cityNameController.dispose();
    _stateNameController.dispose();
    _countryNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _clientAddressController.dispose();
    _videoLinkController.dispose();
    _pick360deg.dispose();
    _pickTitleImage.dispose();
    _propertisImagePicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: UiUtils.buildButton(context,
              onPressed: _onTapContinue,
              height: 48.rh(context),
              fontSize: context.font.large,
              buttonTitle: UiUtils.getTranslatedLabel(context, "next")),
        ),
      ),
      appBar: UiUtils.buildAppBar(
        context,
        title: widget.properyDetails == null
            ? UiUtils.getTranslatedLabel(context, "ddPropertyLbl")
            : UiUtils.getTranslatedLabel(context, "updateProperty"),
        actions: const [
          Text("2/4"),
          SizedBox(
            width: 14,
          ),
        ],
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(UiUtils.getTranslatedLabel(context, "propertyNameLbl")),
                SizedBox(
                  height: 15.rh(context),
                ),
                CustomTextFormField(
                  controller: _propertyNameController,
                  validator: CustomTextFieldValidator.nullCheck,
                  action: TextInputAction.next,
                  hintText:
                      UiUtils.getTranslatedLabel(context, "propertyNameLbl"),
                ),
                SizedBox(
                  height: 15.rh(context),
                ),
                Text(UiUtils.getTranslatedLabel(context, "descriptionLbl")),
                SizedBox(
                  height: 15.rh(context),
                ),
                CustomTextFormField(
                  action: TextInputAction.next,
                  controller: _descriptionController,
                  validator: CustomTextFieldValidator.nullCheck,
                  hintText:
                      UiUtils.getTranslatedLabel(context, "writeSomething"),
                  maxLine: 100,
                  minLine: 6,
                ),
                SizedBox(
                  height: 15.rh(context),
                ),
                SizedBox(
                  height: 35.rh(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(UiUtils.getTranslatedLabel(
                              context, "addressLbl"))),
                      // const Spacer(),
                      Expanded(
                        flex: 3,
                        child: ChooseLocationFormField(
                          initialValue: false,
                          validator: (bool? value) {
                            //Check if it has already data so we will not validate it.
                            if ((widget.properyDetails != null)) {
                              return null;
                            }

                            if (value == true) {
                              return null;
                            } else {
                              return "Select location";
                            }
                          },
                          build: (state) {
                            return Container(
                              decoration: BoxDecoration(
                                  // color: context.color.teritoryColor,
                                  border: Border.all(
                                      width: 1.5,
                                      color: state.hasError
                                          ? Colors.red
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(9)),
                              child: MaterialButton(
                                  height: 30,
                                  onPressed: () {
                                    _onTapChooseLocation.call(state);
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        UiUtils.getSvg(AppIcons.location,
                                            color:
                                                context.color.textLightColor),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        Text(
                                          UiUtils.getTranslatedLabel(
                                              context, "chooseLocation"),
                                        )
                                            .size(context.font.normal)
                                            .color(context.color.teritoryColor)
                                            .underline(),
                                      ],
                                    ),
                                  )),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 15.rh(context),
                ),
                CustomTextFormField(
                  action: TextInputAction.next,
                  controller: _cityNameController,
                  isReadOnly: false,
                  validator: CustomTextFieldValidator.nullCheck,
                  hintText: UiUtils.getTranslatedLabel(context, "city"),
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                CustomTextFormField(
                  action: TextInputAction.next,
                  controller: _stateNameController,
                  isReadOnly: false,
                  validator: CustomTextFieldValidator.nullCheck,
                  hintText: UiUtils.getTranslatedLabel(context, "state"),
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                CustomTextFormField(
                  action: TextInputAction.next,
                  controller: _countryNameController,
                  isReadOnly: false,
                  validator: CustomTextFieldValidator.nullCheck,
                  hintText: UiUtils.getTranslatedLabel(context, "country"),
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                CustomTextFormField(
                  action: TextInputAction.next,
                  controller: _addressController,
                  hintText: UiUtils.getTranslatedLabel(context, "addressLbl"),
                  maxLine: 100,
                  validator: CustomTextFieldValidator.nullCheck,
                  minLine: 4,
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          _clientAddressController.clear();
                          _clientAddressController.text =
                              HiveUtils.getUserDetails().address ?? "";
                        },
                        style: ButtonStyle(
                            overlayColor: MaterialStatePropertyAll(
                                context.color.teritoryColor.withOpacity(0.3))),
                        child: Text("useYourLocation".translate(context))
                            .underline()
                            .color(context.color.teritoryColor)),
                    CustomTextFormField(
                      action: TextInputAction.next,
                      controller: _clientAddressController,
                      validator: CustomTextFieldValidator.nullCheck,
                      hintText: UiUtils.getTranslatedLabel(
                          context, "clientaddressLbl"),
                      maxLine: 100,
                      minLine: 4,
                    ),
                  ],
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                if ((widget.properyDetails == null
                            ? (Constant.addProperty['propertyType']
                                    as PropertyType)
                                .name
                            : widget.properyDetails?['propType'])
                        .toString()
                        .toLowerCase() ==
                    "rent") ...[
                  Text(UiUtils.getTranslatedLabel(context, "rentPrice")),
                ] else ...[
                  Text(UiUtils.getTranslatedLabel(context, "price")),
                ],
                SizedBox(
                  height: 10.rh(context),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        action: TextInputAction.next,
                        prefix: Text("${Constant.currencySymbol} "),
                        controller: _priceController,
                        formaters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d*')),
                        ],
                        isReadOnly: false,
                        keyboard: TextInputType.number,
                        validator: CustomTextFieldValidator.nullCheck,
                        hintText: "00",
                      ),
                    ),
                    if ((widget.properyDetails == null
                                ? (Constant.addProperty['propertyType']
                                        as PropertyType)
                                    .name
                                : widget.properyDetails?['propType'])
                            .toString()
                            .toLowerCase() ==
                        "rent") ...[
                      const SizedBox(
                        width: 5,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            border: Border.all(
                                color: context.color.borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: DropdownButton<String>(
                            value: selectedRentType,
                            dropdownColor: context.color.primaryColor,
                            underline: const SizedBox.shrink(),
                            items: [
                              DropdownMenuItem(
                                value: "Daily",
                                child: Text(
                                  "Daily".translate(context),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Monthly",
                                child: Text("Monthly".translate(context)),
                              ),
                              DropdownMenuItem(
                                value: "Quarterly",
                                child: Text("Quarterly".translate(context)),
                              ),
                              DropdownMenuItem(
                                value: "Yearly",
                                child: Text("Yearly".translate(context)),
                              ),
                            ],
                            onChanged: (value) {
                              selectedRentType = value ?? "";
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                Row(
                  children: [
                    Text(UiUtils.getTranslatedLabel(context, "uploadPictures")),
                    const SizedBox(
                      width: 3,
                    ),
                    Text("maxSize".translate(context))
                        .italic()
                        .size(context.font.small),
                  ],
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                Wrap(
                  children: [
                    if (_pickTitleImage.pickedFile != null) ...[] else ...[],
                    titleImageListener(),
                  ],
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                Text(UiUtils.getTranslatedLabel(context, "otherPictures")),
                SizedBox(
                  height: 10.rh(context),
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                propertyImagesListener(),
                SizedBox(
                  height: 10.rh(context),
                ),
                Text(UiUtils.getTranslatedLabel(context, "additionals")),
                SizedBox(
                  height: 10.rh(context),
                ),
                CustomTextFormField(
                  // prefix: Text("${Constant.currencySymbol} "),
                  controller: _videoLinkController,
                  // isReadOnly: widget.properyDetails != null,
                  hintText: "http://example.com/video.mp4",
                ),
                SizedBox(
                  height: 10.rh(context),
                ),
                DottedBorder(
                  color: context.color.textLightColor,
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      _pick360deg.pick(pickMultiple: false);
                    },
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      height: 48.rh(context),
                      child: Text(UiUtils.getTranslatedLabel(
                          context, "add360degPicture")),
                    ),
                  ),
                ),
                _pick360deg.listenChangesInUI((context, image) {
                  if (image != null) {
                    return Stack(
                      children: [
                        Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.all(5),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10)),
                            child: Image.file(
                              image,
                              fit: BoxFit.cover,
                            )),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, BlurredRouter(
                                builder: (context) {
                                  return PanaromaImageScreen(
                                    imageUrl: image.path,
                                    isFileImage: true,
                                  );
                                },
                              ));
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.all(5),
                              height: 100,
                              decoration: BoxDecoration(
                                  color:
                                      context.color.teritoryColor.withOpacity(
                                    0.68,
                                  ),
                                  borderRadius: BorderRadius.circular(10)),
                              child: FittedBox(
                                fit: BoxFit.none,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.color.secondaryColor,
                                  ),
                                  width: 60.rw(context),
                                  height: 60.rh(context),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            height: 30.rh(context),
                                            width: 40.rw(context),
                                            child: UiUtils.getSvg(
                                                AppIcons.v360Degree,
                                                color: context
                                                    .color.textColorDark)),
                                        Text(UiUtils.getTranslatedLabel(
                                                context, "view"))
                                            .color(context.color.textColorDark)
                                            .size(context.font.small)
                                            .bold()
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Container();
                }),
                SizedBox(
                  height: 15.rh(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget propertyImagesListener() {
    return _propertisImagePicker.listenChangesInUI((context, file) {
      Widget current = Container();

      current = Wrap(
          children: mixedPropertyImageList
              .map((image) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HelperUtils.unfocus();
                        if (image is String) {
                          UiUtils.showFullScreenImage(context,
                              provider: NetworkImage(image));
                        } else {
                          UiUtils.showFullScreenImage(context,
                              provider: FileImage(image));
                        }
                      },
                      child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.all(5),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ImageAdapter(
                            image: image,
                          )),
                    ),

                    // Positioned(
                    //   right: 5,
                    //   top: 5,
                    //   child: Container(
                    //       width: 100,
                    //       height: 100,
                    //       margin: const EdgeInsets.all(5),
                    //       clipBehavior: Clip.antiAlias,
                    //       decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(10)),
                    //       child: Icon(Icons.close)),
                    // ),
                    closeButton(context, () {
                      mixedPropertyImageList.remove(image);

                      if (image is String) {
                        List<Gallery> properyDetail =
                            widget.properyDetails?['gallary_with_id']
                                as List<Gallery>;
                        var id = properyDetail
                            .where((element) => element.imageUrl == image)
                            .first
                            .id;

                        removedImageId.add(id);
                      }
                      setState(() {});
                    }),

                    // child: GestureDetector(
                    //   onTap: () {
                    //     mixedPropertyImageList.remove(image);
                    //     // removedImageId.add();
                    //
                    //     setState(() {});
                    //   },
                    //   child: Icon(
                    //     Icons.close,
                    //     color: context.color.secondaryColor,
                    //   ),
                    // ),
                    // )
                  ],
                );
              })
              .toList()
              .cast<Widget>());

      // if (propertyImageList.isEmpty && editPropertyImageList.isNotEmpty) {
      //   current = Wrap(
      //       children: editPropertyImageList
      //           .map((image) {
      //             log(image.runtimeType.toString());
      //             return Stack(
      //               children: [
      //                 GestureDetector(
      //                   onTap: () {
      //                     HelperUtils.unfocus();
      //                     UiUtils.showFullScreenImage(context,
      //                         provider: FileImage(image));
      //                   },
      //                   child: Container(
      //                       width: 100,
      //                       height: 100,
      //                       margin: const EdgeInsets.all(5),
      //                       clipBehavior: Clip.antiAlias,
      //                       decoration: BoxDecoration(
      //                           borderRadius: BorderRadius.circular(10)),
      //                       child: Image.network(
      //                         image,
      //                         fit: BoxFit.cover,
      //                       )),
      //                 ),
      //                 Positioned(
      //                   right: 5,
      //                   top: 5,
      //                   child: GestureDetector(
      //                     onTap: () {
      //                       editPropertyImageList.remove(image);
      //                       // removedImageId.add();
      //
      //                       setState(() {});
      //                     },
      //                     child: Icon(
      //                       Icons.close,
      //                       color: context.color.secondaryColor,
      //                     ),
      //                   ),
      //                 )
      //               ],
      //             );
      //           })
      //           .toList()
      //           .cast<Widget>());
      // }
      //
      // if (file is List<File>) {
      //   current = Wrap(
      //       children: propertyImageList
      //           .map((image) {
      //             return Stack(
      //               children: [
      //                 GestureDetector(
      //                   onTap: () {
      //                     HelperUtils.unfocus();
      //                     UiUtils.showFullScreenImage(context,
      //                         provider: FileImage(image));
      //                   },
      //                   child: Container(
      //                       width: 100,
      //                       height: 100,
      //                       margin: const EdgeInsets.all(5),
      //                       clipBehavior: Clip.antiAlias,
      //                       decoration: BoxDecoration(
      //                           borderRadius: BorderRadius.circular(10)),
      //                       child: Image.file(
      //                         image,
      //                         fit: BoxFit.cover,
      //                       )),
      //                 ),
      //                 closeButton(context, () {
      //                   propertyImageList.remove(image);
      //                   setState(() {});
      //                 })
      //               ],
      //             );
      //           })
      //           .toList()
      //           .cast<Widget>());
      // }

      return Wrap(
        runAlignment: WrapAlignment.start,
        children: [
          if (file == null && mixedPropertyImageList.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  _propertisImagePicker.pick(pickMultiple: true);
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  height: 48.rh(context),
                  child: Text(
                      UiUtils.getTranslatedLabel(context, "addOtherPicture")),
                ),
              ),
            ),
          current,
          if (file != null || titleImageURL != "")
            uploadPhotoCard(context, onTap: () {
              _propertisImagePicker.pick(pickMultiple: true);
            })
        ],
      );
    });
  }

  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, file) {
      Widget currentWidget = Container();
      if (titleImageURL != "") {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context,
                provider: NetworkImage(titleImageURL));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Image.network(
              titleImageURL,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      if (file is File) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Column(
            children: [
              Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(5),
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  )),
            ],
          ),
        );
      }

      return Wrap(
        children: [
          if (file == null && titleImageURL == "")
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  _pickTitleImage.resumeSubscription();
                  _pickTitleImage.pick(pickMultiple: false);
                  _pickTitleImage.pauseSubscription();
                  titleImageURL = "";
                  setState(() {});
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  height: 48.rh(context),
                  child: Text(
                      UiUtils.getTranslatedLabel(context, "addMainPicture")),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              closeButton(context, () {
                _pickTitleImage.clearImage();
                titleImageURL = "";
                setState(() {});
              })
            ],
          ),
          if (file != null || titleImageURL != "")
            uploadPhotoCard(context, onTap: () {
              _pickTitleImage.resumeSubscription();
              _pickTitleImage.pick(pickMultiple: false);
              _pickTitleImage.pauseSubscription();
              titleImageURL = "";
              setState(() {});
            })
          // GestureDetector(
          //   onTap: () {
          //     _pickTitleImage.resumeSubscription();
          //     _pickTitleImage.pick(pickMultiple: false);
          //     _pickTitleImage.pauseSubscription();
          //     titleImageURL = "";
          //     setState(() {});
          //   },
          //   child: Container(
          //     width: 100,
          //     height: 100,
          //     margin: const EdgeInsets.all(5),
          //     clipBehavior: Clip.antiAlias,
          //     decoration:
          //         BoxDecoration(borderRadius: BorderRadius.circular(10)),
          //     child: DottedBorder(
          //         borderType: BorderType.RRect,
          //         radius: Radius.circular(10),
          //         child: Container(
          //           alignment: Alignment.center,
          //           child: Text("Upload \n Photo"),
          //         )),
          //   ),
          // ),
        ],
      );
    });
  }
}

Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
  return GestureDetector(
    onTap: () {
      onTap.call();
    },
    child: Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.all(5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: DottedBorder(
          color: context.color.textColorDark.withOpacity(0.5),
          borderType: BorderType.RRect,
          radius: Radius.circular(10),
          child: Container(
            alignment: Alignment.center,
            child: Text("uploadPhoto".translate(context)),
          )),
    ),
  );
}

PositionedDirectional closeButton(BuildContext context, Function onTap) {
  return PositionedDirectional(
    top: 6,
    end: 6,
    child: GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        decoration: BoxDecoration(
            color: context.color.primaryColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.close,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}

class ChooseLocationFormField extends FormField<bool> {
  ChooseLocationFormField(
      {super.key,
      FormFieldSetter<bool>? onSaved,
      FormFieldValidator<bool>? validator,
      bool? initialValue,
      required Widget Function(FormFieldState<bool> state) build,
      bool autovalidateMode = false})
      : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            builder: (FormFieldState<bool> state) {
              return build(state);
            });
}

class ImageAdapter extends StatelessWidget {
  final dynamic image;
  ImageAdapter({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    if (image is String) {
      return Image.network(
        image,
        fit: BoxFit.cover,
      );
    } else if (image is File) {
      return Image.file(
        image,
        fit: BoxFit.cover,
      );
    }
    return Container();
  }
}
