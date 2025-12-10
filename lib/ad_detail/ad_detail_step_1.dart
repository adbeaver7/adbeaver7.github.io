import 'package:adbeaver/config.dart';
import 'package:adbeaver/ad_detail/ad_detail_step_2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  int? _statsRemainingBudget;
  int? _statsTotalBudget;
  int? _statsBudgetSpent;
  bool _statsLoading = false;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    final rtbId = _parseInt(widget.adData['rtb_campaign_id']);
    if (rtbId != null) {
      _fetchStatsBudget(rtbId);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatsBudget(int campaignId) async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ServerConfig.nodeBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        ),
      );

      final resp =
          await dio.get('/api/rtb/campaigns/$campaignId/stats');

      final raw = resp.data;
      if (raw is! Map) {
        throw Exception('invalid stats response');
      }
      final data = Map<String, dynamic>.from(raw as Map);

      int? toInt(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        if (v is double) return v.round();
        return int.tryParse(v.toString());
      }

      final summary = data['summary'];
      final campaign = data['campaign'];

      int? remaining;
      int? total;
      int? spent;

      if (campaign is Map<String, dynamic>) {
        remaining = toInt(campaign['remaining_budget']);
        total = toInt(campaign['total_budget']);
      }
      if (summary is Map<String, dynamic>) {
        spent = toInt(summary['budget_spent']);
      }

      if (!mounted) return;

      setState(() {
        _statsLoading = false;
        _statsRemainingBudget = remaining;
        _statsTotalBudget = total;
        _statsBudgetSpent = spent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _statsError = e.toString();
      });
    }
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

  int _getFallbackRemainingBudget(Map<String, dynamic> ad) {
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
    final int remaining = _getFallbackRemainingBudget(ad);
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

  String _normalizeAgeBucketLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;

    if (t.contains('20대 미만') || t.contains('20세 미만')) {
      return '20세 미만';
    }
    if (t.contains('20세 ~ 30세') || t == '20대') {
      return '20대';
    }
    if (t.contains('30세 ~ 40세') || t == '30대') {
      return '30대';
    }
    if (t.contains('40세 ~ 50세') || t == '40대') {
      return '40대';
    }
    if (t.contains('50세 이상')) {
      return '50세 이상';
    }
    return t;
  }

  String _buildTargetAgeLabel(Map<String, dynamic> ad) {
    dynamic v = ad['target_age'];
    v ??= ad['target_ages'];
    v ??= ad['rtb_target_age'];
    v ??= ad['age_targets'];
    if (v == null) return '제한 없음';

    if (v is String) {
      if (v.trim().isEmpty) return '제한 없음';
      return _normalizeAgeBucketLabel(v);
    }

    if (v is List) {
      final labels = v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .map(_normalizeAgeBucketLabel)
          .toList();
      if (labels.isEmpty) return '제한 없음';
      return labels.join(', ');
    }

    if (v is Map) {
      final min = v['min'] ?? v['from'] ?? v['start'] ?? v['min_age'];
      final max = v['max'] ?? v['to'] ?? v['end'] ?? v['max_age'];
      if (min != null && max != null) {
        final raw = '${min}세 ~ ${max}세';
        return _normalizeAgeBucketLabel(raw);
      }
    }

    return _normalizeAgeBucketLabel(v.toString());
  }

  String _buildTargetGenderLabel(Map<String, dynamic> ad) {
    dynamic v = ad['target_gender'];
    v ??= ad['rtb_target_gender'];
    v ??= ad['gender_targets'];
    if (v == null) return '제한 없음';

    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return '제한 없음';
      final lower = trimmed.toLowerCase();
      if (lower == 'all' || lower == 'any') {
        return '모든 성별';
      }
      return _genderLabel(trimmed);
    }

    if (v is List) {
      final labels = v
          .map((e) => e?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .map(_genderLabel)
          .toList();

      if (labels.isEmpty) return '제한 없음';

      final s = labels.toSet();
      if (s.contains('남성') && s.contains('여성') && s.length == 2) {
        return '모든 성별';
      }
      return labels.join(', ');
    }

    return _genderLabel(v.toString());
  }

  double _responsiveValueFontSize(double maxWidth) {
    if (maxWidth <= 320) return 12;
    if (maxWidth <= 360) return 13;
    if (maxWidth <= 400) return 14;
    return 16;
  }

    @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final ad = widget.adData;
    final String? imageUrl = ad['image_url']?.toString();

    final int totalCost = int.tryParse(ad['cost']?.toString() ?? '0') ?? 0;
    final int fallbackRemaining = _getFallbackRemainingBudget(ad);

    final int effectiveRemaining =
        _statsRemainingBudget ?? fallbackRemaining;
    final int effectiveTotal =
        _statsTotalBudget ?? totalCost;

    final bool finishedByState = _isFinished(ad);
    final bool finishedByStats =
        _statsRemainingBudget != null && _statsRemainingBudget! <= 0;

    final bool finished = finishedByStats || finishedByState;

    final String baseBudgetLabel = _getBudgetLabel(ad);
    final String budgetLabel = finished ? '총 예산' : baseBudgetLabel;
    final int budgetValue =
        finished ? effectiveTotal : effectiveRemaining;

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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final valueFontSize =
                                  _responsiveValueFontSize(
                                      constraints.maxWidth);
                              return Row(
                                children: [
                                  _buildInfoItemCustom(
                                    "관심 연령",
                                    _buildAgeValueWidget(
                                      targetAgeLabel,
                                      valueFontSize,
                                    ),
                                  ),
                                  _buildVerticalDivider(),
                                  _buildInfoItemCustom(
                                    "관심 성별",
                                    _buildGenderValueWidget(
                                      targetGenderLabel,
                                      valueFontSize,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(
                              height: 1, color: Color(0xFFEEEEEE)),
                          Row(
                            children: [
                              _buildInfoItem(
                                "시작일",
                                _formatDate(ad['start_date']?.toString()),
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
            onRequestPreviousPage: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            onBudgetUpdated: (remaining, total, spent) {
              setState(() {
                _statsRemainingBudget = remaining;
                _statsTotalBudget = total;
                _statsBudgetSpent = spent;
              });
            },
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

  Widget _buildInfoItemCustom(String label, Widget valueWidget) {
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
          valueWidget,
        ],
      ),
    );
  }

  TextStyle _valueTextStyle(double fontSize) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  int _ageSortKey(String s) {
    final matches = RegExp(r'(\d+)').allMatches(s).toList();
    if (matches.isEmpty) return 100000;
    final first = int.tryParse(matches.first.group(1) ?? '') ?? 0;
    int secondary = 0;
    if (s.contains('미만')) {
      secondary = -1;
    } else if (s.contains('~')) {
      secondary = 0;
    } else if (s.contains('이상')) {
      secondary = 1;
    }
    return first * 10 + secondary;
  }

  Widget _buildAgeValueWidget(String targetAgeLabel, double fontSize) {
    if (targetAgeLabel == '제한 없음' || targetAgeLabel.trim().isEmpty) {
      return Text(
        targetAgeLabel.isEmpty ? '제한 없음' : targetAgeLabel,
        style: _valueTextStyle(fontSize),
      );
    }

    final tokens = targetAgeLabel
        .split(RegExp(r'\s*,\s*'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return Text('제한 없음', style: _valueTextStyle(fontSize));
    }

    final sorted = [...tokens]
      ..sort((a, b) => _ageSortKey(a).compareTo(_ageSortKey(b)));

    if (sorted.length >= 5) {
      return Text('모든 연령', style: _valueTextStyle(fontSize));
    }

    final limited = sorted.take(4).toList();

    final rows = <List<String>>[];
    final row1 = <String>[];
    final row2 = <String>[];

    for (int i = 0; i < limited.length; i++) {
      if (i < 2) {
        row1.add(limited[i]);
      } else {
        row2.add(limited[i]);
      }
    }
    if (row1.isNotEmpty) rows.add(row1);
    if (row2.isNotEmpty) rows.add(row2);

    final children = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      final rowText = rows[i].join('   ');
      children.add(
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            rowText,
            style: _valueTextStyle(fontSize),
          ),
        ),
      );
      if (i + 1 < rows.length) {
        children.add(const SizedBox(height: 2));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildGenderValueWidget(String targetGenderLabel, double fontSize) {
    String label = targetGenderLabel;

    final normalized = label.replaceAll(' ', '');
    if (normalized.contains('남성') &&
        normalized.contains('여성') &&
        !normalized.contains('제한없음')) {
      label = '모든 성별';
    }

    return Text(
      label,
      style: _valueTextStyle(fontSize),
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