import '../../utils/api.dart';
import 'property_model.dart';

class EnquiryStatus {
  String? id;
  String? propertyId;
  String? customerId;
  String? status;
  String? createdAt;
  PropertyModel? property;

  EnquiryStatus(
      {this.property,
      this.id,
      this.propertyId,
      this.customerId,
      this.status,
      this.createdAt});

  EnquiryStatus.fromJson(Map<String, dynamic> json) {
    id = json[Api.id].toString();
    propertyId = json[Api.propertysId].toString();
    customerId = json[Api.customersId].toString();
    status = json[Api.enqStatus].toString();
    createdAt = json[Api.createdAt];
    property = PropertyModel.fromMap(json[Api.property]);
  }
}
