import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ebroker/Ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/data/cubits/chatCubits/delete_message_cubit.dart';
import 'package:ebroker/utils/customHeroAnimation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/routes.dart';
import '../../../data/Repositories/property_repository.dart';
import '../../../data/cubits/chatCubits/load_chat_messages.dart';
import '../../../data/cubits/chatCubits/send_message.dart';
import '../../../data/helper/widgets.dart';
import '../../../data/model/data_output.dart';
import '../../../data/model/property_model.dart';
import '../../../utils/AppIcon.dart';
import '../../../utils/Extensions/extensions.dart';
import '../../../utils/Notification/chat_message_handler.dart';
import '../../../utils/Notification/notification_service.dart';
import '../../../utils/constant.dart';
import '../../../utils/helper_utils.dart';
import '../../../utils/hive_utils.dart';
import '../../../utils/responsiveSize.dart';
import '../../../utils/ui_utils.dart';
import '../widgets/AnimatedRoutes/blur_page_route.dart';
import '../widgets/AnimatedRoutes/transparant_route.dart';
import 'chatAudio/widgets/chat_widget.dart';
import 'chatAudio/widgets/record_button.dart';

int totalMessageCount = 0;

ValueNotifier<bool> showDeletebutton = ValueNotifier<bool>(false);

ValueNotifier<int> selectedMessageid = ValueNotifier<int>(-5);
ValueNotifier<int> selectedRecieverId = ValueNotifier<int>(-5);

class ChatScreen extends StatefulWidget {
  final String? from;
  final String profilePicture;
  final String userName;
  final String propertyImage;
  final String proeprtyTitle;
  final String userId; //for which we are messageing
  final String propertyId;
  const ChatScreen(
      {super.key,
      required this.profilePicture,
      required this.userName,
      required this.propertyImage,
      required this.proeprtyTitle,
      required this.userId,
      required this.propertyId,
      this.from});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _recordButtonAnimation = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: 500,
    ),
  );
  TextEditingController controller = TextEditingController();
  PlatformFile? messageAttachment;
  bool isFetchedFirstTime = false;
  double scrollPositionWhenLoadMore = 0;
  late Stream<PermissionStatus> notificationStream = notificationPermission();
  late StreamSubscription notificationStreamSubsctription;
  bool isNotificationPermissionGranted = true;
  bool showRecordButton = true;
  late final ScrollController _pageScrollController = ScrollController()
    ..addListener(
      () {
        if (_pageScrollController.offset >=
            _pageScrollController.position.maxScrollExtent) {
          if (context.read<LoadChatMessagesCubit>().hasMoreChat()) {
            setState(() {});
            context.read<LoadChatMessagesCubit>().loadMore();
          }
        }
      },
    );
  @override
  void initState() {
    context.read<LoadChatMessagesCubit>().load(
          userId: int.parse(
            widget.userId,
          ),
          propertyId: int.parse(
            widget.propertyId,
          ),
        );

    currentlyChatPropertyId = widget.propertyId;
    currentlyChatingWith = widget.userId;
    notificationStreamSubsctription =
        notificationStream.listen((PermissionStatus permissionStatus) {
      isNotificationPermissionGranted = permissionStatus.isGranted;
      if (mounted) {
        setState(() {});
      }
    });
    controller.addListener(() {
      if (controller.text.isNotEmpty) {
        showRecordButton = false;
      } else {
        showRecordButton = true;
      }
      setState(() {});
    });
    super.initState();
  }

  Stream<PermissionStatus> notificationPermission() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield* Permission.notification.request().asStream();
    }
  }

  @override
  void dispose() {
    notificationStreamSubsctription.cancel();
    super.dispose();
  }

  List<String> supportedImageTypes = [
    'jpeg',
    'jpg',
    'png',
    'gif',
    'webp',
    'animated_webp',
  ];
  @override
  Widget build(BuildContext context) {
    var chatBackground = "assets/chat_background/light.svg";
    var attachmentMIME = "";
    if (messageAttachment != null) {
      attachmentMIME =
          (messageAttachment?.path?.split(".").last.toLowerCase()) ?? "";
    }

    return WillPopScope(
      onWillPop: () async {
        currentlyChatingWith = "";
        showDeletebutton.value = false;

        currentlyChatPropertyId = "";
        notificationStreamSubsctription.cancel();
        ChatMessageHandler.flushMessages();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (messageAttachment != null) ...[
                    if (supportedImageTypes.contains(attachmentMIME)) ...[
                      Container(
                        decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            border: Border.all(
                                color: context.color.borderColor, width: 1.5)),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: GestureDetector(
                                    onTap: () {
                                      UiUtils.showFullScreenImage(context,
                                          provider: FileImage(File(
                                            messageAttachment?.path ?? "",
                                          )));
                                    },
                                    child: Image.file(
                                      File(
                                        messageAttachment?.path ?? "",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  )),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(messageAttachment?.name ?? ""),
                                Text(HelperUtils.getFileSizeString(
                                  bytes: messageAttachment!.size,
                                ).toString()),
                              ],
                            )
                          ],
                        ),
                      )
                    ] else ...[
                      Container(
                        color: context.color.secondaryColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child:
                              AttachmentMessage(url: messageAttachment!.path!),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                  BottomAppBar(
                    padding: const EdgeInsetsDirectional.all(10),
                    elevation: 5,
                    color: context.color.secondaryColor,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          // IconButton(
                          //     onPressed: () async {
                          //       if (messageAttachment == null) {
                          //         FilePickerResult? pickedAttachment =
                          //             await FilePicker.platform.pickFiles(
                          //           allowMultiple: false,
                          //         );

                          //         messageAttachment =
                          //             pickedAttachment?.files.first;
                          //         setState(() {});
                          //       } else {
                          //         messageAttachment = null;
                          //         setState(() {});
                          //       }
                          //     },
                          //     icon: messageAttachment != null
                          //         ? const Icon(Icons.close)
                          //         : const RotatedBox(
                          //             quarterTurns: 3,
                          //             child: Icon(Icons.attachment))),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              cursorColor: context.color.teritoryColor,
                              onTap: () {
                                showDeletebutton.value = false;
                              },
                              textInputAction: TextInputAction.newline,
                              minLines: 1,
                              maxLines: null,
                              decoration: InputDecoration(
                                suffixIconColor: context.color.textLightColor,
                                suffixIcon: IconButton(
                                  onPressed: () async {
                                    if (messageAttachment == null) {
                                      FilePickerResult? pickedAttachment =
                                          await FilePicker.platform.pickFiles(
                                        allowMultiple: false,
                                      );

                                      messageAttachment =
                                          pickedAttachment?.files.first;
                                      showRecordButton = false;
                                      setState(() {});
                                    } else {
                                      messageAttachment = null;
                                      showRecordButton = true;
                                      setState(() {});
                                    }
                                  },
                                  icon: messageAttachment != null
                                      ? const Icon(Icons.close)
                                      : Transform.rotate(
                                          angle: -3.14 / 5.0,
                                          child: const Icon(
                                            Icons.attachment,
                                          ),
                                        ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                        color: context.color.teritoryColor)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                        color: context.color.teritoryColor)),
                                hintText: UiUtils.getTranslatedLabel(
                                  context,
                                  "writeHere",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 9.5,
                          ),

                          if (showRecordButton)
                            RecordButton(
                              controller: _recordButtonAnimation,
                              callback: (path) {
                                if (Constant.isDemoModeOn) {
                                  HelperUtils.showSnackBarMessage(
                                      context,
                                      UiUtils.getTranslatedLabel(
                                          context, "thisActionNotValidDemo"));
                                  return;
                                }

                                //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called
                                ChatMessageHandler.add(BlocProvider(
                                  create: (context) => SendMessageCubit(),
                                  child: ChatMessage(
                                    key: ValueKey(
                                        DateTime.now().toString().toString()),
                                    message: "[AUDIO]",
                                    senderId: HiveUtils.getUserId().toString(),
                                    propertyId: widget.propertyId,
                                    reciverId: widget.userId,
                                    time: DateTime.now().toString(),
                                    hasAttachment: false,
                                    isSentByMe: true,
                                    isChatAudio: true,
                                    isSentNow: true,
                                    audioFile: path,
                                  ),
                                ));
                                totalMessageCount++;

                                setState(() {});
                              },
                              isSending: false,
                            ),
                          if (!showRecordButton)
                            GestureDetector(
                              onTap: () {
                                showDeletebutton.value = false;

                                //if file is selected then user can send message without text
                                if (controller.text.trim().isEmpty &&
                                    messageAttachment == null) return;
                                //This is adding Chat widget in stream with BlocProvider , because we will need to do api process to store chat message to server, when it will be added to list it's initState method will be called
                                if (Constant.isDemoModeOn) {
                                  HelperUtils.showSnackBarMessage(
                                      context,
                                      UiUtils.getTranslatedLabel(
                                          context, "thisActionNotValidDemo"));
                                  return;
                                }
                                ChatMessageHandler.add(
                                  BlocProvider(
                                    key: ValueKey(
                                        DateTime.now().toString().toString()),
                                    create: (context) => SendMessageCubit(),
                                    child: ChatMessage(
                                      key: ValueKey(
                                          DateTime.now().toString().toString()),
                                      message: controller.text,
                                      hasAttachment: messageAttachment != null,
                                      senderId:
                                          HiveUtils.getUserId().toString(),
                                      propertyId: widget.propertyId,
                                      reciverId: widget.userId,
                                      time: DateTime.now().toString(),
                                      isSentByMe: true,
                                      isChatAudio: false,
                                      isSentNow: true,
                                      attachment: messageAttachment?.path,
                                    ),
                                  ),
                                );
                                totalMessageCount++;
                                controller.text = "";
                                messageAttachment = null;
                                setState(() {});
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: context.color.teritoryColor,
                                child: Icon(
                                  Icons.send,
                                  color: context.color.buttonColor,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            centerTitle: false,
            automaticallyImplyLeading: false,
            leading: FittedBox(
              fit: BoxFit.none,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: SvgPicture.asset(
                    AppIcons.arrowLeft,
                    color: context.color.teritoryColor,
                    height: 24,
                  ),
                ),
              ),
            ),
            leadingWidth: 24,
            backgroundColor: context.color.secondaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: context.color.teritoryColor),
            bottom: isNotificationPermissionGranted
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(25),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Container(
                        width: context.screenWidth,
                        color: const Color.fromARGB(255, 151, 151, 151),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("turnOnNotification".translate(context)),
                        ),
                      ),
                    ),
                  ),
            actions: [
              ValueListenableBuilder(
                valueListenable: showDeletebutton,
                builder: (context, value, child) {
                  if (value == false) return const SizedBox.shrink();
                  return IconButton(
                      onPressed: () {
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            onAccept: () async {
                              context.read<DeleteMessageCubit>().delete(
                                  (selectedMessageid.value),
                                  receiverId: selectedRecieverId.value);
                              showDeletebutton.value = false;
                            },
                            title: "areYouSure".translate(context),
                            content: Text(
                              "msgWillNotRecover".translate(context),
                            ),
                          ),
                        );
                      },
                      icon: SvgPicture.asset(
                        AppIcons.delete,
                        color: context.color.teritoryColor,
                      ));
                },
              ),
              if (widget.from != "property")
                FittedBox(
                  fit: BoxFit.none,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        Widgets.showLoader(context);
                        PropertyRepository fetch = PropertyRepository();
                        DataOutput<PropertyModel> dataOutput = await fetch
                            .fetchPropertyFromPropertyId(widget.propertyId);
                        Future.delayed(
                          Duration.zero,
                          () {
                            Widgets.hideLoder(context);

                            HelperUtils.goToNextPage(
                                Routes.propertyDetails, context, false,
                                args: {
                                  'propertyData': dataOutput.modelList[0],
                                  'propertiesList': dataOutput.modelList,
                                  'fromMyProperty': false,
                                });
                          },
                        );
                      } catch (e) {
                        Widgets.hideLoder(context);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        child: Image.network(
                          widget.propertyImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 18,
              ),
              if (false)
                IconButton(
                    onPressed: () {
                      showDeletebutton.value = false;

                      Navigator.push(context, BlurredRouter(
                        builder: (context) {
                          return ChatInfoWidget(
                            propertyId: widget.propertyId,
                            propertyTitle: widget.proeprtyTitle,
                            propertyTitleImage: widget.propertyImage,
                          );
                        },
                      ));
                    },
                    icon: Icon(
                      Icons.info,
                      color: context.color.textColorDark.withOpacity(0.7),
                    ))
            ],
            title: FittedBox(
              fit: BoxFit.none,
              child: Row(
                children: [
                  widget.profilePicture == ""
                      ? CircleAvatar(
                          backgroundColor: context.color.teritoryColor,
                          child: SvgPicture.asset(
                            AppIcons.placeHolder,
                            color: context.color.buttonColor,
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              TransparantRoute(
                                barrierDismiss: true,
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      color: const Color.fromARGB(69, 0, 0, 0),

                                      // child: Hero(
                                      //   tag: "RR",
                                      //   transitionOnUserGestures: true,
                                      //   flightShuttleBuilder: (flightContext,
                                      //       animation,
                                      //       flightDirection,
                                      //       fromHeroContext,
                                      //       toHeroContext) {
                                      //     return CircleAvatar(
                                      //       backgroundImage:
                                      //           CachedNetworkImageProvider(
                                      //         widget.profilePicture,
                                      //       ),
                                      //     );
                                      //   },
                                      //   child: CircleAvatar(
                                      //     backgroundImage:
                                      //         CachedNetworkImageProvider(
                                      //       widget.profilePicture,
                                      //     ),
                                      //   ),
                                      // ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: CustomImageHeroAnimation(
                            type: CImageType.Network,
                            image: widget.profilePicture,
                            child: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                widget.profilePicture,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: context.screenWidth * 0.35,
                        child: Text(widget.userName)
                            .color(context.color.textColorDark)
                            .size(context.font.normal),
                      ),
                      SizedBox(
                        width: context.screenWidth * 0.35,
                        child: Text(widget.proeprtyTitle)
                            .size(context.font.small)
                            .color(context.color.textColorDark),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              SvgPicture.asset(
                chatBackground,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
              BlocListener<DeleteMessageCubit, DeleteMessageState>(
                listener: (context, state) {
                  if (state is DeleteMessageSuccess) {
                    ChatMessageHandler.removeMessage(state.id);
                    showDeletebutton.value = false;
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    showDeletebutton.value = false;
                  },
                  child: BlocConsumer<LoadChatMessagesCubit,
                      LoadChatMessagesState>(
                    listener: (context, state) {
                      if (state is LoadChatMessagesSuccess) {
                        ChatMessageHandler.loadMessages(
                            state.messages, context);
                        totalMessageCount = state.messages.length;
                        isFetchedFirstTime = true;
                        setState(() {});
                      }
                    },
                    builder: (context, state) {
                      return Stack(
                        children: [
                          StreamBuilder(
                              stream: ChatMessageHandler.getChatStream(),
                              builder: (context, AsyncSnapshot snapshot) {
                                Widget? loadingMoreWidget;
                                if (state is LoadChatMessagesSuccess) {
                                  if (state.isLoadingMore) {
                                    loadingMoreWidget = Text(
                                        UiUtils.getTranslatedLabel(
                                            context, "loading"));
                                  }
                                }

                                if (snapshot.connectionState ==
                                        ConnectionState.active ||
                                    snapshot.connectionState ==
                                        ConnectionState.done) {
                                  return Column(
                                    children: [
                                      loadingMoreWidget ??
                                          const SizedBox.shrink(),
                                      Expanded(
                                        child: ListView.builder(
                                          reverse: true,
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          addAutomaticKeepAlives: true,
                                          controller: _pageScrollController,
                                          itemCount: snapshot.data.length,
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          itemBuilder: (context, index) {
                                            dynamic chat =
                                                (snapshot.data as List)
                                                    .elementAt(index);

                                            return chat;
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Container();
                              }),
                          if ((state is LoadChatMessagesInProgress))
                            Center(
                              child: UiUtils.progress(),
                            )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatInfoWidget extends StatelessWidget {
  final String propertyTitleImage;
  final String propertyTitle;
  final String propertyId;
  const ChatInfoWidget(
      {super.key,
      required this.propertyTitleImage,
      required this.propertyTitle,
      required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.color.teritoryColor),
      ),
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: context.screenHeight * 0.46,
              decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(10)),
              width: context.screenWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onTap: () {
                        UiUtils.showFullScreenImage(context,
                            provider:
                                CachedNetworkImageProvider(propertyTitleImage));
                      },
                      child: CachedNetworkImage(
                        imageUrl: propertyTitleImage,
                        width: context.screenWidth,
                        fit: BoxFit.cover,
                        height: context.screenHeight * 0.3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(propertyTitle)
                          .setMaxLines(
                            lines: 2,
                          )
                          .size(
                            context.font.larger.rf(
                              context,
                            ),
                          ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.none,
                      child: UiUtils.buildButton(context, onPressed: () async {
                        try {
                          Widgets.showLoader(context);
                          PropertyRepository fetch = PropertyRepository();
                          DataOutput<PropertyModel> dataOutput = await fetch
                              .fetchPropertyFromPropertyId(propertyId);
                          Future.delayed(
                            Duration.zero,
                            () {
                              Widgets.hideLoder(context);

                              HelperUtils.goToNextPage(
                                  Routes.propertyDetails, context, false,
                                  args: {
                                    'propertyData': dataOutput.modelList[0],
                                    'propertiesList': dataOutput.modelList,
                                    'fromMyProperty': false,
                                  });
                            },
                          );
                        } catch (e) {
                          Widgets.hideLoder(context);
                        }
                      },
                          buttonTitle: UiUtils.getTranslatedLabel(
                              context, "viewProperty"),
                          width: context.screenWidth * 0.5,
                          fontSize: context.font.normal,
                          height: 40),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
