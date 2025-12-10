import 'package:adbeaver/ad_create/ad_create_step_3.dart';
import 'package:adbeaver/services/ad_provider.dart';
import 'package:adbeaver/test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdCreateStep4Screen extends StatelessWidget {
  const AdCreateStep4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdCreateStep4Form();
  }
}

class AdCreateStep4Form extends StatefulWidget {
  const AdCreateStep4Form({super.key});

  @override
  State<AdCreateStep4Form> createState() => _AdCreateStep4Form();
}

class _AdCreateStep4Form extends State<AdCreateStep4Form> {
  List<bool> _isCheckedGender = [false, false];
  @override
    void initState() {
      super.initState();
      final form = context.read<AdCreationProvider>().formData;

      _isCheckedGender = [
        form.target_gender.contains('남성'),
        form.target_gender.contains('여성'),
      ];
    }
  final List<String> _ageLabels = [
    '20대 미만',
    '20세 ~ 30세',
    '30세 ~ 40세',
    '40세 ~ 50세',
    '50세 이상'
  ];

  @override
    Widget build(BuildContext context) {
      final provider = context.watch<AdCreationProvider>();
      final List<String> currentSelectedAges = provider.formData.target_ages;
      bool isAllAgeSelected = _ageLabels.every((age) => currentSelectedAges.contains(age));
      bool isAllGenderSelected = _isCheckedGender.every((element) => element == true);

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
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "타겟을 \n설정해주세요.",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: _boxDecoration(),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              title: '성별 선택',
                              isSelected: isAllGenderSelected,
                              onTap: () {
                                setState(() {
                                  bool newValue = !isAllGenderSelected;
                                  _isCheckedGender = [newValue, newValue];
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomCheckbox(
                                    label: "남성",
                                    value: _isCheckedGender[0],
                                    onChanged: (val) {
                                      setState(() => _isCheckedGender[0] = val ?? false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildCustomCheckbox(
                                    label: "여성",
                                    value: _isCheckedGender[1],
                                    onChanged: (val) {
                                      setState(() => _isCheckedGender[1] = val ?? false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        decoration: _boxDecoration(),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              title: '나이대 선택 (중복 가능)',
                              isSelected: isAllAgeSelected,
                              onTap: () {
                                final readProvider = context.read<AdCreationProvider>();
                                if (isAllAgeSelected) {
                                  for (var age in _ageLabels) {
                                    if (readProvider.formData.target_ages.contains(age)) {
                                      readProvider.setTargetAges(age);
                                    }
                                  }
                                } else {
                                  for (var age in _ageLabels) {
                                    if (!readProvider.formData.target_ages.contains(age)) {
                                      readProvider.setTargetAges(age);
                                    }
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _ageLabels.length,
                              itemBuilder: (context, index) {
                                final String curLabel = _ageLabels[index];
                                final bool isSelected = provider.formData.target_ages.contains(curLabel);
                                return CheckboxListTile(
                                  title: Text(curLabel, style: const TextStyle(fontSize: 15)),
                                  value: isSelected,
                                  activeColor: const Color(0xFF2972C7),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                  onChanged: (bool? value) {
                                    context.read<AdCreationProvider>().setTargetAges(curLabel);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FD),
                ),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final List<String> selectedGenders = [];
                      if (_isCheckedGender[0]) selectedGenders.add("남성");
                      if (_isCheckedGender[1]) selectedGenders.add("여성");

                      if (selectedGenders.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("성별 카테고리를 선택해주세요.")),
                        );
                        return;
                      }

                      if (provider.formData.target_ages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("나이대 카테고리를 선택해주세요.")),
                        );
                        return;
                      }

                      context.read<AdCreationProvider>().setTargetGender(selectedGenders);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdCreateStep3Form()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2972C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      "다음으로",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.check_circle_outline,
                  size: 18,
                  color: isSelected ? const Color(0xFF2972C7) : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "전체 선택",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF2972C7) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? const Color(0xFF2972C7) : Colors.grey[300]!,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: value
              ? const Color(0xFF2972C7).withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: value ? const Color(0xFF2972C7) : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF2972C7) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
