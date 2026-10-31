import 'package:flutter/foundation.dart';
import 'package:voxora/data/models/certificate_model.dart';
import 'package:voxora/data/providers/certificate_provider.dart';

class CertificateRepository {
  final CertificateProvider _provider;

  CertificateRepository(this._provider);

  Future<CertificateModel> generateCertificate(
    String assessmentId,
    String fullName,
    String email,
  ) =>
      _provider.generateCertificate(assessmentId, fullName, email);

  Future<Uint8List> downloadCertificate(String certificateId) =>
      _provider.downloadCertificate(certificateId);
}
