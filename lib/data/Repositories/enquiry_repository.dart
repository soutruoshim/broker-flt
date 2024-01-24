import '../../utils/api.dart';
import '../../utils/constant.dart';
import '../model/data_output.dart';
import '../model/enquiry_status.dart';

class EnquiryRepository {
  Future<DataOutput<EnquiryStatus>> fetchMyEnquiry(
      {required int offset}) async {
    try {
      Map<String, dynamic> parameters = {
        Api.limit: Constant.loadLimit,
        Api.offset: offset
      };
      Map<String, dynamic> response = await Api.get(
          url: Api.apiGetPropertyEnquiry, queryParameters: parameters);

      List<EnquiryStatus> modelList = (response['data'] as List)
          .map((e) => EnquiryStatus.fromJson(e))
          .toList();
      return DataOutput(total: response['total'] ?? 0, modelList: modelList);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEnquiry(String propertyId) async {
    Map<String, dynamic> parameters = {
      Api.actionType: "0",
      Api.propertyId: propertyId,
    };

    await Api.post(url: Api.apiSetPropertyEnquiry, parameter: parameters);
  }

  Future<void> deleteEnquiry(int id) async {
    await Api.post(url: Api.deleteInquiry, parameter: {Api.id: id});
  }
}
