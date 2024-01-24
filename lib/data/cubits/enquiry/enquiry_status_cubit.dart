import 'dart:convert';

import 'package:ebroker/utils/Extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../utils/api.dart';
import '../../../utils/helper_utils.dart';
import '../../../utils/hive_utils.dart';
import '../../helper/custom_exception.dart';
import '../../model/enquiry_status.dart';

abstract class EnquiryStatusState {}

class EnquiryStatusInitial extends EnquiryStatusState {}

class EnquiryStatusProgress extends EnquiryStatusState {}

class EnquiryStatusSuccess extends EnquiryStatusState {
  List<EnquiryStatus> enquiryStatusList = [];
  EnquiryStatusSuccess(this.enquiryStatusList);
}

class EnquiryStatusFailure extends EnquiryStatusState {
  final String errmsg;
  EnquiryStatusFailure(this.errmsg);
}

class EnquiryStatusCubit extends Cubit<EnquiryStatusState> {
  EnquiryStatusCubit() : super(EnquiryStatusInitial());

  void getEnquiryStatus(
    BuildContext context,
  ) {
    emit(EnquiryStatusProgress());
    getEnquiryStatusFromDb(
      context,
    )
        .then((value) => emit(EnquiryStatusSuccess(value)))
        .catchError((e) => emit(EnquiryStatusFailure(e.toString())));
  }

  Future<List<EnquiryStatus>> getEnquiryStatusFromDb(
    BuildContext context,
  ) async {
    List<EnquiryStatus> enquiryStatusList = [];
    Map<String, String> body = {
      //get current user's enquiry status
      Api.customerId: HiveUtils.getUserId().toString(),
    };

    var response = await HelperUtils.sendApiRequest(
        Api.apiGetPropertyEnquiry, body, false, context,
        passUserid: false);
    var getdata = json.decode(response);
    if (getdata != null) {
      if (!getdata[Api.error]) {
        List list = getdata['data'];
        enquiryStatusList =
            list.map((model) => EnquiryStatus.fromJson(model)).toList();
        //EnquiryStatus
      } else {
        throw CustomException(getdata[Api.message]);
      }
    } else {
      Future.delayed(
        Duration.zero,
        () {
          throw CustomException("nodatafound".translate(context));
        },
      );
    }
    return enquiryStatusList; //getdata[ApiParams.message];
  }
}
