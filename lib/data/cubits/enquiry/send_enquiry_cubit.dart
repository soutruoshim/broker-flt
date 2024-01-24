// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Repositories/enquiry_repository.dart';

abstract class SendEnquiryState {}

class SendEnquiryInitial extends SendEnquiryState {}

class SendEnquiryInProgress extends SendEnquiryState {}

class SendEnquirySuccess extends SendEnquiryState {
  dynamic id;
  SendEnquirySuccess({
    required this.id,
  });
}

class SendEnquiryFailure extends SendEnquiryState {
  final String errorMessage;
  SendEnquiryFailure(this.errorMessage);
}

class SendEnquiryCubit extends Cubit<SendEnquiryState> {
  SendEnquiryCubit() : super(SendEnquiryInitial());

  final EnquiryRepository _enquiryRepository = EnquiryRepository();

  Future sendEnquiry({required String propertyId}) async {
    try {
      emit(SendEnquiryInProgress());
      await _enquiryRepository.sendEnquiry(propertyId);

      emit(SendEnquirySuccess(id: propertyId));
    } catch (e) {
      emit(SendEnquiryFailure(e.toString()));
    }
  }
}
