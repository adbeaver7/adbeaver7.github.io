import 'package:adbeaver/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adbeaver/ad_detail/ad_detail_step_2.dart';

class AdDetailStep1Screen extends StatelessWidget {
  final Map<String, dynamic> adData;

  const AdDetailStep1Screen({super.key, required this.adData});

  @override
  Widget build(BuildContext context) {
    return AdDetailStep1Form(adData: adData);
  }
}

class AdDetailStep1Form extends StatefulWidget {
  final Map<String, dynamic> adData;

  const AdDetailStep1Form({super.key, required this.adData});

  @override
  State<AdDetailStep1Form> createState() => _AdDetailStep1FormState();
}

class _AdDetailStep1FormState extends State<AdDetailStep1Form> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      final local = parsed.toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(local);
    } catch (_) {
      return dateStr;
    }
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  int _getRemainingBudget(Map<String, dynamic> ad) {
    final int? rtbRemain =
        int.tryParse(ad['rtb_remaining_budget']?.toString() ?? '');
    if (rtbRemain != null) {
      return rtbRemain;
    }

    final int? display =
        int.tryParse(ad['display_budget']?.toString() ?? '');
    if (display != null) {
      return display;
    }

    final int cost = int.tryParse(ad['cost']?.toString() ?? '0') ?? 0;
    return (cost * 0.2).round();
  }

  bool _isFinished(Map<String, dynamic> ad) {
    final String rawState = (ad['adstate'] as String?) ?? '';
    if (rawState == 'FINISHED') return true;
    if (rawState == 'DELETED') return true;
    final int remaining = _getRemainingBudget(ad);
    return remaining <= 0;
  }

  String _getBudgetLabel(Map<String, dynamic> ad) {
    final String? t = ad['display_budget_type'] as String?;
    if (t == 'TOTAL') return '총 예산';
    if (t == 'REMAINING') return '남은 예산';

    final String raw = (ad['adstate'] as String?) ?? '';
    if (raw == 'ACTIVE' || raw == 'PAUSED') {
      return '남은 예산';
    }
    return '총 예산';
  }

  String _genderLabel(String raw) {
    final v = raw.toLowerCase();
    if (v == 'm' || v == 'male' || v == '남' || v == '남성') return '남성';
    if (v == 'f' || v == 'female' || v == '여' || v == '여성') return '여성';
    if (raw == 'unknown' || raw.isEmpty) return '제한 없음';
    return raw;
  }

  String _buildTargetAgeLabel(Map<String, dynamic> ad) {
    dynamic v = ad['target_age'];
    v ??= ad['target_ages'];
    v ??= ad['rtb_target_age'];
    v ??= ad['age_targets'];
    if (v == null) return '제한 없음';

    if (v is String) {
      if (v.trim().isEmpty) return '제한 없음';
      return v;
    }

    if (v is List) {
      final labels = v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      if (labels.isEmpty) return '제한 없음';
      return labels.join(', ');
    }

    if (v is Map) {
      final min = v['min'] ?? v['from'] ?? v['start'] ?? v['min_age'];
      final max = v['max'] ?? v['to'] ?? v['end'] ?? v['max_age'];
      if (min != null && max != null) {
        return '${min}세 ~ ${max}세';
      }
    }

    return v.toString();
  }

  String _buildTargetGenderLabel(Map<String, dynamic> ad) {
    dynamic v = ad['target_gender'];
    v ??= ad['rtb_target_gender'];
    v ??= ad['gender_targets'];
    if (v == null) return '제한 없음';

    if (v is String) {
      if (v.trim().isEmpty) return '제한 없음';
      return _genderLabel(v);
    }

    if (v is List) {
      final labels = v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .map(_genderLabel)
          .toList();
      if (labels.isEmpty) return '제한 없음';
      return labels.join(', ');
    }

    return _genderLabel(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final ad = widget.adData;
    final String? imageUrl = ad['image_url']?.toString();

    final bool finished = _isFinished(ad);
    final int totalCost = int.tryParse(ad['cost']?.toString() ?? '0') ?? 0;
    final int remaining = _getRemainingBudget(ad);
    final String budgetLabel = _getBudgetLabel(ad);
    final int budgetValue = finished ? totalCost : remaining;

    final String targetAgeLabel = _buildTargetAgeLabel(ad);
    final String targetGenderLabel = _buildTargetGenderLabel(ad);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "광고 상세",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ad['adname'] ?? '제목 없음',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 35,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: imageUrl != null && imageUrl.startsWith('http')
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: ad['image_url'] == null ||
                              !ad['image_url'].toString().startsWith('http')
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 50,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "이미지 없음",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              _buildInfoItem("입찰 방법", ad['admethod'] ?? '-'),
                              _buildVerticalDivider(),
                              _buildInfoItem("카테고리", ad['category'] ?? '-'),
                            ],
                          ),
                          const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          Row(
                            children: [
                              _buildInfoItem("관심 연령", targetAgeLabel),
                              _buildVerticalDivider(),
                              _buildInfoItem("관심 성별", targetGenderLabel),
                            ],
                          ),
                          const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          Row(
                            children: [
                              _buildInfoItem(
                                "시작일",
                                _formatDate(
                                    ad['start_date']?.toString()),
                              ),
                              _buildVerticalDivider(),
                              _buildInfoItem(
                                budgetLabel,
                                "${currencyFormat.format(budgetValue)}원",
                                isHighlight: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AdDetailStep2Form(
            rtbCampaignId: _parseInt(ad['rtb_campaign_id']),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF2972C7) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFEEEEEE),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}