import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxora/data/models/certificate_model.dart';
import 'package:voxora/data/repositories/certificate_repository.dart';

class CertificateController extends GetxController {
  final isDownloading = false.obs;
  final isTestMode = false.obs;

  late final String assessmentId;
  late final String level;
  late final int score;
  late final double percentage;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  CertificateModel? _certificate;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    assessmentId = args?['assessmentId'] as String? ?? '';
    level = args?['level'] as String? ?? '';
    score = (args?['score'] as num?)?.toInt() ?? 0;
    percentage = (args?['percentage'] as num?)?.toDouble() ?? 0.0;
    isTestMode.value = args?['isTestMode'] as bool? ?? false;
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  String get courseName => 'Spoken English – Voxora AI';

  String get completionDateStr {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String get scoreDisplay => '$score/100 (${percentage.toStringAsFixed(0)}%)';

  Future<void> generateAndDownload() async {
    final name = fullNameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        'Required Field',
        'Please enter your full name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isDownloading.value = true;
    try {
      final repo = Get.find<CertificateRepository>();

      _certificate ??=
          await repo.generateCertificate(assessmentId, name, email);

      final bytes = await repo.downloadCertificate(_certificate!.certificateId);

      final dir = await getApplicationDocumentsDirectory();
      final prefix = _certificate!.isTestMode ? 'TEST_' : '';
      final filename =
          '${prefix}Voxora_Certificate_${level}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      Get.snackbar(
        _certificate!.isTestMode ? 'TEST Certificate Saved' : 'Certificate Downloaded!',
        'Saved to Documents folder.\nFile: $filename',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar(
        'Download Failed',
        'Could not download certificate. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isDownloading.value = false;
    }
  }
}
