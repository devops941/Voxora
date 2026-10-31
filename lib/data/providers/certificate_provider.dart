import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:voxora/core/network/api_client.dart';
import 'package:voxora/core/constants/api_constants.dart';
import 'package:voxora/data/models/certificate_model.dart';

class CertificateProvider {
  final ApiClient _apiClient;

  CertificateProvider(this._apiClient);

  Future<CertificateModel> generateCertificate(
    String assessmentId,
    String fullName,
    String email,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.certificateGenerate,
      data: {'assessmentId': assessmentId, 'fullName': fullName, 'email': email},
    );
    return CertificateModel.fromJson(response.data ?? {});
  }

  Future<Uint8List> downloadCertificate(String certificateId) async {
    final path = ApiConstants.buildUrl(
      ApiConstants.certificateDownload,
      {'certificateId': certificateId},
    );
    final response = await _apiClient.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? []);
  }
}
