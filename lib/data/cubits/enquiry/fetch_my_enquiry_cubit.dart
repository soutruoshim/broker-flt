// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ebroker/data/Repositories/enquiry_repository.dart';
import 'package:ebroker/data/model/data_output.dart';
import 'package:ebroker/data/model/enquiry_status.dart';

abstract class FetchMyEnquiryState {}

class FetchMyEnquiryInitial extends FetchMyEnquiryState {}

class FetchMyEnquiryInProgress extends FetchMyEnquiryState {}

class FetchMyEnquirySuccess extends FetchMyEnquiryState {
  final int total;
  final int offset;
  final bool isLoadingMore;
  final bool hasError;
  final List<EnquiryStatus> myEnquiries;
  FetchMyEnquirySuccess({
    required this.total,
    required this.offset,
    required this.isLoadingMore,
    required this.hasError,
    required this.myEnquiries,
  });

  FetchMyEnquirySuccess copyWith({
    int? total,
    int? offset,
    bool? isLoadingMore,
    bool? hasMoreData,
    List<EnquiryStatus>? myEnquiries,
  }) {
    return FetchMyEnquirySuccess(
      total: total ?? this.total,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasMoreData ?? hasError,
      myEnquiries: myEnquiries ?? this.myEnquiries,
    );
  }
}

class FetchMyEnquiryFailure extends FetchMyEnquiryState {
  final dynamic errorMessage;

  FetchMyEnquiryFailure(this.errorMessage);
}

class FetchMyEnquiryCubit extends Cubit<FetchMyEnquiryState> {
  FetchMyEnquiryCubit() : super(FetchMyEnquiryInitial());
  final EnquiryRepository _enquiryRepository = EnquiryRepository();
  void fetchMyEnquiry() async {
    try {
      emit(FetchMyEnquiryInProgress());
      DataOutput<EnquiryStatus> result =
          await _enquiryRepository.fetchMyEnquiry(offset: 0);
      emit(FetchMyEnquirySuccess(
          hasError: false,
          isLoadingMore: false,
          myEnquiries: result.modelList,
          offset: 0,
          total: result.total));
    } catch (e) {
      emit(FetchMyEnquiryFailure(e));
    }
  }

  void fetchMyEnquiryMore() async {
    try {
      if (state is FetchMyEnquirySuccess) {
        if ((state as FetchMyEnquirySuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyEnquirySuccess).copyWith(isLoadingMore: true));

        DataOutput<EnquiryStatus> result =
            await _enquiryRepository.fetchMyEnquiry(
          offset: (state as FetchMyEnquirySuccess).myEnquiries.length,
        );

        FetchMyEnquirySuccess bookingsState = (state as FetchMyEnquirySuccess);
        bookingsState.myEnquiries.addAll(result.modelList);
        emit(
          FetchMyEnquirySuccess(
            isLoadingMore: false,
            hasError: false,
            myEnquiries: bookingsState.myEnquiries,
            offset: (state as FetchMyEnquirySuccess).myEnquiries.length,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchMyEnquirySuccess).copyWith(
          isLoadingMore: false,
          hasMoreData: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchMyEnquirySuccess) {
      return (state as FetchMyEnquirySuccess).myEnquiries.length <
          (state as FetchMyEnquirySuccess).total;
    }
    return false;
  }

  void removeEnquriy(String id) {
    if (state is FetchMyEnquirySuccess) {
      (state as FetchMyEnquirySuccess)
          .myEnquiries
          .removeWhere((element) => element.id == id);

      emit((state as FetchMyEnquirySuccess)
          .copyWith(myEnquiries: (state as FetchMyEnquirySuccess).myEnquiries));
    }
  }
}
