import 'package:adbeaver/ad_create/ad_create_step_4.dart';
import 'package:adbeaver/config.dart';
import 'package:adbeaver/services/ad_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'ad_create_step_3.dart';

class AdCreateStep2Screen extends StatelessWidget {
  const AdCreateStep2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdCreateStep2Form();
  }
}

class AdCreateStep2Form extends StatefulWidget {
  const AdCreateStep2Form({super.key});

  @override
  State<AdCreateStep2Form> createState() => _AdCreateStep2FormState();
}

class _AdCreateStep2FormState extends State<AdCreateStep2Form> {
  final TextEditingController _adNameController = TextEditingController();
  String? uploadedImageUrl;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final formData = context.read<AdCreationProvider>().formData;

    if (formData.adname != null && formData.adname!.isNotEmpty) {
      _adNameController.text = formData.adname!;
    }

    if (formData.image_url != null && formData.image_url!.isNotEmpty) {
      uploadedImageUrl = formData.image_url!;
      _selectedImageName = Uri.parse(uploadedImageUrl!).pathSegments.last;
    }
  }

  @override
  void dispose() {
    _adNameController.dispose();
    super.dispose();
  }

  Future<void> handleImageUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final String extension = picked.name.split('.').last.toLowerCase();
    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("JPG 또는 PNG 형식의 이미지만 업로드할 수 있습니다."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final bytes = await picked.readAsBytes();

      FormData formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(
          bytes,
          filename: picked.name,
        ),
      });

      final response = await Dio().post(
        "${ServerConfig.nodeBaseUrl}/api/upload/image",
        data: formData,
      );

      if (response.statusCode == 200) {
        setState(() {
          uploadedImageUrl = response.data["imageUrl"] as String;
          _selectedImageName = picked.name;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미지 업로드 실패: ${response.statusCode}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이미지 업로드에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "광고 만들기",
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "기본 정보를 입력해주세요.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                    _buildInputSection(
                      title: "광고 이름",
                      isRequired: true,
                      child: _buildTextField(
                        controller: _adNameController,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputSection(
                      title: "광고 이미지",
                      isRequired: true,
                      child: _buildImageUploadArea(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FD),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_adNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("광고 이름을 입력해주세요")),
                    );
                    return;
                  }

                  if (uploadedImageUrl == null ||
                      uploadedImageUrl!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("이미지를 업로드해야 다음 단계로 진행할 수 있습니다."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final provider = context.read<AdCreationProvider>();
                  provider.setAdName(_adNameController.text);
                  provider.setImageUrl(uploadedImageUrl ?? "");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdCreateStep4Form(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF2972C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: const Text(
                  "다음으로",
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(
                  color: Color(0xFF2972C7),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hintText = "",
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadArea() {
    final bool hasImage =
        uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: hasImage
              ? null
              : () async {
                  await handleImageUpload();
                },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: hasImage ? null : 200,
            width: double.infinity,
            padding: hasImage ? const EdgeInsets.symmetric(vertical: 20) : null,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1.8,
                          child: Image.network(
                            uploadedImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Text(
                                  "이미지를 불러오지 못했습니다.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "이미지가 추가되었습니다",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedImageName != null)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _selectedImageName!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2972C7).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF2972C7),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "이미지를 업로드해주세요",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "JPG, PNG 형식만 가능합니다.",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (hasImage) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await handleImageUpload();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                "이미지 재등록",
                style: TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2972C7),
              ),
            ),
          ),
        ],
      ],
    );
  }
}