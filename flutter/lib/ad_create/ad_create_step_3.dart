import 'package:adbeaver/services/ad_provider.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:adbeaver/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ad_create_step_4.dart';

class AdCreateStep3Screen extends StatelessWidget {
  const AdCreateStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdCreateStep3Form();
  }
}

enum StartOption {
  immediate,
  manual,
}

class AdCreateStep3Form extends StatefulWidget {
  const AdCreateStep3Form({super.key});

  @override
  State<AdCreateStep3Form> createState() => _AdCreateStep3FormState();
}

class _AdCreateStep3FormState extends State<AdCreateStep3Form> {
  final List<String> methods = ['일반', '플러스', '프로'];
  String _selectedBidMethod = '일반';
  final TextEditingController _costController = TextEditingController();

  StartOption _startOption = StartOption.immediate;
  DateTime? _manualStartDateTime;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdCreationProvider>();
    final data = provider.formData;

    if (data.admethod != null && methods.contains(data.admethod)) {
      _selectedBidMethod = data.admethod!;
    }

    if (data.cost != null && data.cost! > 0) {
      final formatter = NumberFormat('#,###');
      _costController.text = formatter.format(data.cost!);
    }

    if (data.startOption == "즉시") {
      _startOption = StartOption.immediate;
    } else if (data.startOption == "직접선택") {
      _startOption = StartOption.manual;
      _manualStartDateTime = data.startdate;
    } else {
      _startOption = StartOption.immediate;
      provider.setStartOption("즉시");
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickManualStartDateTime() async {
    final provider = context.read<AdCreationProvider>();

    final DateTime now = DateTime.now();
    final DateTime minAllowed = now.add(const Duration(minutes: 5));

    final DateTime base = _manualStartDateTime ?? minAllowed;

    final DateTime initialDate = DateTime(base.year, base.month, base.day);
    final DateTime firstDate =
        DateTime(now.year, now.month, now.day);
    final DateTime lastDate = now.add(const Duration(days: 365));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2972C7),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF2972C7),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(base);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data:
              MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2972C7),
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime == null) return;

    final DateTime selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selected.isBefore(minAllowed)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("시작일은 현재 시각 기준 5분 뒤부터 설정할 수 있어요."),
        ),
      );
      Future.microtask(_pickManualStartDateTime);
      return;
    }

    setState(() {
      _manualStartDateTime = selected;
    });
    provider.setStartDate(selected);
  }

  Widget _buildStartOptionRow() {
    final bool isImmediate = _startOption == StartOption.immediate;
    final bool isManual = _startOption == StartOption.manual;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "시작일",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _startOption = StartOption.immediate;
                    });
                    final adProvider = context.read<AdCreationProvider>();
                    adProvider.setStartOption("즉시");
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isImmediate
                          ? const Color(0xFF2972C7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isImmediate
                            ? const Color(0xFF2972C7)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "즉시 시작",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isImmediate ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _startOption = StartOption.manual;
                    });
                    final adProvider = context.read<AdCreationProvider>();
                    adProvider.setStartOption("직접선택");
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color:
                          isManual ? const Color(0xFF2972C7) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isManual
                            ? const Color(0xFF2972C7)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "직접 선택",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isManual ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualStartRow() {
    if (_startOption != StartOption.manual) {
      return const SizedBox.shrink();
    }

    final DateTime? date = _manualStartDateTime;
    final String dateText = date != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(date)
        : '날짜/시간 선택';

    return InkWell(
      onTap: _pickManualStartDateTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "선택한 시간",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        date != null ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
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
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "예산과 기간을\n설정해주세요.",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle("입찰 방법"),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: methods.map((method) {
                          final bool isSelected =
                              _selectedBidMethod == method;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedBidMethod = method),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Color(0x332972C7),
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  method,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF2972C7)
                                        : Colors.grey[600],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle("총 예산",
                        subText: "최소 1,000원 이상부터 등록가능합니다."),
                    _buildCostInput(),

                    const SizedBox(height: 24),

                    _buildSectionTitle("기간 설정"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStartOptionRow(),
                          _buildManualStartRow(),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 8),
                            child: const Text(
                              "예산 소진 시까지 진행됩니다.",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2972C7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  final now = DateTime.now();
                  final provider = context.read<AdCreationProvider>();
                  final userProvider =
                      context.read<UserProvider>();
                  final walletMoney = userProvider.money;

                  if (walletMoney <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("보유 광고 예산이 0원입니다. 예산을 충전한 후 다시 시도해주세요."),
                      ),
                    );
                    return;
                  }

                  if (_startOption == StartOption.immediate) {
                    provider.setStartDate(now);
                  } else {
                    final DateTime? start = provider.formData.startdate;

                    if (start == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("시작일을 선택해주세요.")),
                      );
                      return;
                    }
                    if (start.isBefore(now)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("시작일은 현재 시각 이후로만 설정할 수 있어요.")),
                      );
                      return;
                    }
                  }

                  final rawText = _costController.text.trim();
                  if (rawText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("예산을 입력해주세요")),
                    );
                    return;
                  }

                  final cleanText = rawText.replaceAll(',', '');
                  if (!RegExp(r'^[0-9]+$').hasMatch(cleanText)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("예산은 숫자만 입력할 수 있습니다.")),
                    );
                    return;
                  }

                  final int costValue = int.parse(cleanText);

                  if (costValue < 1000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("예산은 최소 1,000원 이상이어야 합니다.")),
                    );
                    return;
                  }

                  if (costValue > walletMoney) {
                    final formattedWallet =
                        NumberFormat('#,###').format(walletMoney);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "입력한 예산이 보유 예산을 초과했습니다.\n현재 보유 예산: $formattedWallet 원",
                        ),
                      ),
                    );
                    return;
                  }

                  provider.setAdMethod(_selectedBidMethod);
                  provider.setCost(costValue);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("광고 설정이 완료되었습니다!")),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdCheckScreen(),
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
                  "완성하기",
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

  Widget _buildSectionTitle(String title, {String? subText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(width: 8),
            Text(
              subText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2972C7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _costController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
        ],
        onChanged: (string) {
          _formatCost(string);
        },
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2972C7),
        ),
        decoration: const InputDecoration(
          suffixText: " 원",
          suffixStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          hintText: "0",
        ),
      ),
    );
  }

  void _formatCost(String value) {
    if (value.isEmpty) return;

    String cleanValue = value.replaceAll(',', '');
    if (cleanValue.isEmpty) return;

    final formatter = NumberFormat('#,###');
    String newText = formatter.format(int.parse(cleanValue));

    if (value != newText) {
      _costController.text = newText;
      _costController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }
  }
}
