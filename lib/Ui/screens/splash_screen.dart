// import 'dart:async';

import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebroker/Ui/screens/widgets/Erros/no_internet.dart';
import 'package:ebroker/app/routes.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// import '../app/routes.dart';
import 'package:ebroker/data/cubits/profile_setting_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_language_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/utils/AppIcon.dart';
import 'package:ebroker/utils/Extensions/extensions.dart';
import 'package:ebroker/utils/api.dart';
import 'package:ebroker/utils/ui_utils.dart';
// import 'package:ebroker/main.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/app.dart';
import '../../data/cubits/auth/auth_state_cubit.dart';
import '../../data/cubits/category/fetch_category_cubit.dart';
import '../../data/cubits/outdoorfacility/fetch_outdoor_facility_list.dart';
import '../../data/cubits/subscription/get_subsctiption_package_limits_cubit.dart';
import '../../utils/constant.dart';
import '../../utils/hive_keys.dart';
import '../../utils/hive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AuthenticationState authenticationState;

  bool isTimerCompleted = false;
  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;

  @override
  void initState() {
    context.read<FetchCategoryCubit>().fetchCategories();
    context.read<FetchOutdoorFacilityListCubit>().fetch();
    locationPermission();
    super.initState();

    getDefaultLanguage(
      () {
        isLanguageLoaded = true;
        setState(
          () {},
        );
      },
    );

    checkIsUserAuthenticated();
    bool isDataAvailable = checkPersistedDataAvailibility();
    Connectivity().checkConnectivity().then((value) {
      if (value == ConnectivityResult.none && !isDataAvailable) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) {
            return NoInternet(
              onRetry: () {
                Navigator.pushReplacementNamed(
                  context,
                  Routes.splash,
                );
              },
            );
          },
        ));
      }
    });
    startTimer();
    //get Currency Symbol from Admin Panel
    Future.delayed(Duration.zero, () {
      context.read<ProfileSettingCubit>().fetchProfileSetting(
            context,
            Api.currencySymbol,
          );
    });
  }

  Future<void> locationPermission() async {
    if ((await Permission.location.status) == PermissionStatus.denied) {
      await Permission.location.request();
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void checkIsUserAuthenticated() async {
    authenticationState = context.read<AuthenticationCubit>().state;
    if (authenticationState == AuthenticationState.authenticated) {
      ///Only load sensitive details if user is authenticated
      ///This call will load sensitive details with settings
      context.read<FetchSystemSettingsCubit>().fetchSettings(
            isAnonymouse: false,
            forceRefresh: true,
          );
      completeProfileCheck();
    } else {
      //This call will hide sensitive details.
      context.read<FetchSystemSettingsCubit>().fetchSettings(
            isAnonymouse: true,
            forceRefresh: true,
          );
    }
  }

  Future<void> startTimer() async {
    Timer(const Duration(seconds: 3), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
    });
  }

  void navigateCheck() {
    log(
      {
        "timer": isTimerCompleted,
        "setting": isSettingsLoaded,
        "language": isLanguageLoaded
      }.toString(),
      name: "StatusNavigation",
    );
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded) {
      navigateToScreen();
    }
  }

  void completeProfileCheck() {
    if (HiveUtils.getUserDetails().name == "" ||
        HiveUtils.getUserDetails().email == "") {
      Future.delayed(
        const Duration(milliseconds: 100),
        () {
          Navigator.pushReplacementNamed(
            context,
            Routes.completeProfile,
            arguments: {
              "from": "login",
            },
          );
        },
      );
    }
  }

  void navigateToScreen() {
    if (context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.maintenanceMode) ==
        "1") {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(
          Routes.maintenanceMode,
        );
      });
    } else if (authenticationState == AuthenticationState.authenticated) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context)
            .pushReplacementNamed(Routes.main, arguments: {'from': "main"});
      });
    } else if (authenticationState == AuthenticationState.unAuthenticated) {
      if (Hive.box(HiveKeys.userDetailsBox).get("isGuest") == true) {
        Future.delayed(Duration.zero, () {
          Navigator.of(context)
              .pushReplacementNamed(Routes.main, arguments: {"from": "splash"});
        });
      } else {
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pushReplacementNamed(Routes.login);
        });
      }
    } else if (authenticationState == AuthenticationState.firstTime) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    navigateCheck();

    return BlocListener<FetchLanguageCubit, FetchLanguageState>(
      listener: (context, state) {},
      child: BlocListener<FetchSystemSettingsCubit, FetchSystemSettingsState>(
        listener: (context, state) {
          log("SYSTM SETTING STATUS $state");
          if (state is FetchSystemSettingsFailure) {
            log("SYSTEM SETTING FAILUR IS ${state.errorMessage}");
          }
          if (state is FetchSystemSettingsSuccess) {
            var setting = context
                .read<FetchSystemSettingsCubit>()
                .getSetting(SystemSetting.subscription);
            if ((setting as List).isNotEmpty) {
              if ((setting[0] as Map).containsKey("package_id")) {
                Constant.subscriptionPackageId =
                    setting[0]['package_id'].toString();
                context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
                      setting[0]['package_id'].toString(),
                    );
              }
            }

            if (state.settings['data'].containsKey("demo_mode")) {
              Constant.isDemoModeOn = state.settings['data']['demo_mode'];
            }
            isSettingsLoaded = true;
            setState(() {});
          }
        },
        child: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: context.color.teritoryColor,
          ),
          child: Scaffold(
            backgroundColor: context.color.teritoryColor,
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                      width: 150,
                      height: 150,
                      child: UiUtils.getSvg(
                        AppIcons.splashLogo,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      key: const ValueKey("companylogo"),
                      child: UiUtils.getSvg(AppIcons.companyLogo)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
