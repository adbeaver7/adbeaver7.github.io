import 'package:adbeaver/config.dart';
import 'package:adbeaver/mainboard.dart';
import 'package:adbeaver/services/ad_provider.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:dio/dio.dart' show Dio;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdCheckScreen extends StatelessWidget {
  const AdCheckScreen({super.key});

  String _buildStartDateText(formData) {
    if (formData.startOption == "즉시") {
      return "광고 생성 시 즉시 시작";
    }
    if (formData.startdate != null) {
      return DateFormat('yyyy-MM-dd HH:mm').format(formData.startdate!);
    }
    return "-";
  }

  String _ageDisplayLabel(String value) {
    switch (value) {
      case '20대 미만':
        return '10대 이하';
      case '20세 ~ 30세':
        return '20대';
      case '30세 ~ 40세':
        return '30대';
      case '40세 ~ 50세':
        return '40대';
      case '50세 이상':
        return '50대 이상';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = context.watch<AdCreationProvider>().formData;
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "최종 확인",
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "입력하신 내용을\n마지막으로 확인해주세요",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle("기본 정보"),
              _buildInfoBlock("카테고리", formData.category ?? "선택 안함"),
              const SizedBox(height: 12),
              _buildInfoBlock("광고 이름", formData.adname ?? "입력 안함"),
              const SizedBox(height: 12),
              _buildImageBlock(formData.image_url),
              const SizedBox(height: 12),
              _buildInfoBlock("광고 방법", formData.admethod ?? "선택 안함"),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEEEEEE), thickness: 1),
              const SizedBox(height: 24),
              _buildSectionTitle("타겟팅 설정"),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock(
                      "관심 성별",
                      formData.target_gender.isEmpty
                          ? "전체 성별"
                          : formData.target_gender.join(', '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoBlock(
                "관심 연령",
                formData.target_ages.isEmpty
                    ? "전체 연령"
                    : formData.target_ages
                        .map<String>(_ageDisplayLabel)
                        .join(', '),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEEEEEE), thickness: 1),
              const SizedBox(height: 24),
              _buildSectionTitle("예산 및 일정"),
              _buildInfoBlock(
                "총 예산",
                "${numberFormat.format(formData.cost)} 원",
                isHighlight: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBlock(
                      "시작일",
                      _buildStartDateText(formData),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _submitAd(context, formData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2972C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    "이대로 광고 생성하기",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? const Color(0xFF2972C7) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageBlock(String? imageUrl) {
    final bool hasImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "광고 이미지",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: hasImage
              ? null
              : const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("이미지 로드 실패"),
                      );
                    },
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(Icons.image_outlined,
                        size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      "이미지가 등록되지 않았습니다.",
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _submitAd(BuildContext context, dynamic adFormData) async {
    final userId = context.read<UserProvider>().userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("로그인 정보가 없습니다. 다시 로그인해주세요.")),
      );
      return;
    }

    final adProvider = context.read<AdCreationProvider>();
    final formData = adProvider.formData;

    final now = DateTime.now();
    final String? startOption = formData.startOption;

    if (startOption == "즉시") {
      adProvider.setStartDate(null);
    } else {
      if (formData.startdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("시작일을 선택해주세요.")),
        );
        return;
      }

      if (formData.startdate!.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("시작일은 현재 시각 이후로만 설정할 수 있어요."),
          ),
        );
        return;
      }
    }

    final Map<String, dynamic> dataToSend = adProvider.formData.toJson();
    dataToSend['user_id'] = userId;

    try {
      final dio = Dio();
      const String serverUrl = '${ServerConfig.nodeBaseUrl}/api/ads';

      final response = await dio.post(serverUrl, data: dataToSend);

      if (response.statusCode == 200) {
        if (!context.mounted) return;

        context.read<AdCreationProvider>().resetForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("광고가 성공적으로 등록되었습니다!"),
            backgroundColor: Color(0xFF2972C7),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainBoardForm()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("광고 등록 실패")),
      );
    }
  }
}