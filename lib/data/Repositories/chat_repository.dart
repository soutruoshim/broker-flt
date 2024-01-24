import 'package:dio/dio.dart';
import 'package:ebroker/utils/logger.dart';
import 'package:flutter/material.dart';

import '../../Ui/screens/chat/chatAudio/widgets/chat_widget.dart';
import '../../utils/api.dart';
import '../../utils/constant.dart';
import '../../utils/hive_utils.dart';
import '../model/chat/chated_user_model.dart';
import '../model/data_output.dart';

class ChatRepostiory {
  BuildContext? _setContext;

  void setContext(BuildContext context) {
    _setContext = context;
  }

  Future<DataOutput<ChatedUser>> fetchChatList(int pageNumber) async {
    Map<String, dynamic> response = await Api.get(
        url: Api.getChatList,
        queryParameters: {"page": pageNumber, "per_page": Constant.loadLimit});

    List<ChatedUser> modelList = (response['data'] as List).map(
      (e) {
        return ChatedUser.fromJson(e, context: _setContext);
      },
    ).toList();

    return DataOutput(total: response['total_page'] ?? 0, modelList: modelList);
  }

  Future<DataOutput<ChatMessage>> getMessages(
      {required int page, required int userId, required int propertyId}) async {
    Map<String, dynamic> response = await Api.get(
      url: Api.getMessages,
      queryParameters: {
        "user_id": userId,
        "property_id": propertyId,
        "page": page,
        "per_page": Constant.minChatMessages
      },
    );

    List<ChatMessage> modelList = (response['data']['data'] as List).map(
      (result) {
        int senderId = result['sender_id'];
        int reciverId = result['receiver_id'];
        int propertyId = result['property_id'];
        String message = result['message'];
        String file = result['file'];
        String audio = result['audio'];
        String createdAt = result['created_at'];
        int id = result['id'];

        return ChatMessage(
          key: ValueKey(id),
          isSentByMe: HiveUtils.getUserId() == senderId.toString(),
          hasAttachment: file != "",
          isChatAudio: audio != "",
          message: message,
          propertyId: propertyId.toString(),
          reciverId: reciverId.toString(),
          senderId: senderId.toString(),
          time: createdAt,
          isSentNow: false,
          attachment: file,
          audioFile: audio,
        );
      },
    ).toList();

    return DataOutput(total: response['total_page'] ?? 0, modelList: modelList);
  }

  Future<Map<String, dynamic>> sendMessage(
      {required String senderId,
      required String recieverId,
      required String message,
      required String proeprtyId,
      MultipartFile? audio,
      MultipartFile? attachment}) async {
    Map<String, dynamic> parameters = {
      "sender_id": senderId,
      "receiver_id": recieverId,
      "message": message,
      "property_id": proeprtyId,
      "file": attachment,
      "audio": audio
    };

    if (attachment == null) {
      parameters.remove("file");
    }
    if (audio == null) {
      parameters.remove("audio");
    }
    Logger.error(parameters, name: "CHAT PARAMS");
    Map<String, dynamic> map =
        await Api.post(url: Api.sendMessage, parameter: parameters);
    return map;
  }
}
