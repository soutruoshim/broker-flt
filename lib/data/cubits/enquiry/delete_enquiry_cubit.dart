import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Repositories/enquiry_repository.dart';

abstract class DeleteEnquiryState {}

class DeleteEnquiryInitial extends DeleteEnquiryState {}

class DeleteEnquiryInProgress extends DeleteEnquiryState {}

class DeleteEnquirySuccess extends DeleteEnquiryState {
  final String id;
  DeleteEnquirySuccess(this.id);
}

class DeleteEnquiryFailure extends DeleteEnquiryState {
  final String errorMessage;

  DeleteEnquiryFailure(this.errorMessage);
}

class DeleteEnquiryCubit extends Cubit<DeleteEnquiryState> {
  final EnquiryRepository _enquiryRepository = EnquiryRepository();

  DeleteEnquiryCubit() : super(DeleteEnquiryInitial());

  Future<void> deleteEnquiry(int id) async {
    try {
      emit(DeleteEnquiryInProgress());
      await _enquiryRepository.deleteEnquiry(id);
      emit(DeleteEnquirySuccess(id.toString()));
    } catch (e) {
      emit(DeleteEnquiryFailure(e.toString()));
    }
  }
}
