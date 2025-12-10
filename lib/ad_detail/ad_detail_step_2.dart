import 'package:adbeaver/config.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdDetailStep2Form extends StatefulWidget {
  final int? rtbCampaignId;
  final VoidCallback? onRequestPreviousPage;
  final void Function(int remainingBudget, int totalBudget, int spent)?
      onBudgetUpdated;

  const AdDetailStep2Form({
    super.key,
    this.rtbCampaignId,
    this.onRequestPreviousPage,
    this.onBudgetUpdated,
  });

  @override
  State<AdDetailStep2Form> createState() => _AdDetailStep2FormState();
}

class _AdDetailStep2FormState extends State<AdDetailStep2Form> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  int? _touchedGenderIndex;
  int? _touchedAgeIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.rtbCampaignId == null) {
      _loading = false;
      _error = '이 광고는 RTB 캠페인과 연결되어 있지 않습니다.';
    } else {
      _fetchStats();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

    Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
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

      final resp = await dio.get(
        '/api/rtb/campaigns/${widget.rtbCampaignId}/stats',
      );

      if (!mounted) return;

      final data = Map<String, dynamic>.from(resp.data as Map);

      if (widget.onBudgetUpdated != null) {
        final summary = data['summary'];
        final campaign = data['campaign'];
        if (summary is Map<String, dynamic> &&
            campaign is Map<String, dynamic>) {
          final totalBudget = _toInt(campaign['total_budget']);
          final remainingBudget = _toInt(campaign['remaining_budget']);
          final spent = _toInt(summary['budget_spent']);
          widget.onBudgetUpdated!(remainingBudget, totalBudget, spent);
        }
      }

      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '통계를 불러오는 중 오류가 발생했습니다.';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> get _summary {
    final summary = _stats?['summary'];
    if (summary is Map<String, dynamic>) return summary;
    return {};
  }

  Map<String, dynamic> get _campaign {
    final c = _stats?['campaign'];
    if (c is Map<String, dynamic>) return c;
    return {};
  }

  List<dynamic> get _gender {
    final targets = _stats?['targets'];
    if (targets is Map<String, dynamic>) {
      final g = targets['gender'];
      if (g is List) return g;
    }
    return const [];
  }

  List<dynamic> get _age {
    final targets = _stats?['targets'];
    if (targets is Map<String, dynamic>) {
      final a = targets['age'];
      if (a is List) return a;
    }
    return const [];
  }

  List<dynamic> get _region {
    final targets = _stats?['targets'];
    if (targets is Map<String, dynamic>) {
      final r = targets['region'];
      if (r is List) return r;
    }
    return const [];
  }

  List<dynamic> get _hobbies {
    final targets = _stats?['targets'];
    if (targets is Map<String, dynamic>) {
      final h = targets['hobbies'];
      if (h is List) return h;
    }
    return const [];
  }

  List<dynamic> get _recentAuctions {
    final v = _stats?['recent_auctions'];
    if (v is List) return v;
    return const [];
  }

  int _summaryInt(String key) {
    final v = _summary[key];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _summaryDouble(String key) {
    final v = _summary[key];
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _campaignInt(String key) {
    final v = _campaign[key];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _budgetUsageRatio() {
    final r = _summaryDouble('budget_usage_ratio');
    if (r.isNaN || r.isInfinite) return 0;
    if (r < 0) return 0;
    if (r > 1) return 1;
    return r;
  }

  int _budgetSpent() {
    return _summaryInt('budget_spent');
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatRecentDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('M/d HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _genderKorean(String raw) {
    final v = raw.toLowerCase();
    if (v == 'm' || v == 'male' || v == '남' || v == '남성') return '남성';
    if (v == 'f' || v == 'female' || v == '여' || v == '여성') return '여성';
    if (raw == 'unknown' || raw.isEmpty) return '알 수 없음';
    return raw;
  }

  String _ageBucketLabel(String raw) {
    final s = raw.replaceAll(' ', '');
    if (s.contains('20대미만') || s.contains('20세미만') || s.contains('미만')) {
      return '20세 미만';
    }
    if (s.contains('20세~30세') || s.contains('20대')) {
      return '20대';
    }
    if (s.contains('30세~40세') || s.contains('30대')) {
      return '30대';
    }
    if (s.contains('40세~50세') || s.contains('40대')) {
      return '40대';
    }
    if (s.contains('50세이상') || s.contains('50대이상') || s.contains('이상')) {
      return '50세 이상';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2972C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat('#,###');

    final wins = _summaryInt('wins');
    final avgWinPrice = _summaryDouble('avg_win_price').round();
    final spent = _budgetSpent();
    final usageRatio = _budgetUsageRatio();
    final totalBudget = _campaignInt('total_budget');
    final remainingBudget = _campaignInt('remaining_budget');
    final ratioPercent = (usageRatio * 100).round();

    return SafeArea(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.pixels <= 0.0 &&
            (notification.scrollDelta ?? 0) < 0) {
          widget.onRequestPreviousPage?.call();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTopMetricCard(
                  title: '낙찰 수',
                  value: currencyFormat.format(wins),
                  color: const Color(0xFF43A047),
                ),
                const SizedBox(width: 12),
                _buildTopMetricCard(
                  title: '평균 입찰가',
                  value: '${currencyFormat.format(avgWinPrice)}원',
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(width: 12),
                _buildBudgetTopCard(
                  ratioPercent: ratioPercent,
                  totalBudget: totalBudget,
                  spent: spent,
                  remainingBudget: remainingBudget,
                ),
              ],
            ),
            const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGenderCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAgeCard()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRegionCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildHobbyCard()),
                ],
              ),
              const SizedBox(height: 24),
              _buildRecentAuctionsCardTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetTopCard({
    required int ratioPercent,
    required int totalBudget,
    required int spent,
    required int remainingBudget,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예산 소진율',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ratioPercent.clamp(0, 100) / 100.0,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2972C7),
                      ),
                    ),
                    Text(
                      '$ratioPercent%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAuctionsCardTable() {
    if (_recentAuctions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: _cardDecoration(),
        child: const Text(
          '최근 경매 데이터가 없습니다.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final items = <Map<String, String>>[];
    for (final raw in _recentAuctions.take(5)) {
      final m = raw as Map<String, dynamic>;
      final createdAt = m['created_at']?.toString() ?? '';
      final region = m['region']?.toString() ?? '알 수 없음';
      final ageRaw = m['age_bucket']?.toString() ?? '알 수 없음';
      final age = ageRaw == 'unknown' ? '알 수 없음' : _ageBucketLabel(ageRaw);
      final genderRaw = m['gender']?.toString() ?? '';
      final hobbyRaw = m['hobby']?.toString() ?? '';
      final gender = _genderKorean(genderRaw);
      final hobby =
          (hobbyRaw == 'unknown' || hobbyRaw.isEmpty) ? '알 수 없음' : hobbyRaw;

      items.add({
        'created_at': createdAt,
        'region': region,
        'age': age,
        'gender': gender,
        'hobby': hobby,
      });
    }

    Widget headerCell(String text, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    Widget dataCell(
      String text, {
      int flex = 1,
      TextAlign align = TextAlign.center,
      bool scrollable = false,
    }) {
      Alignment alignment;
      if (align == TextAlign.left) {
        alignment = Alignment.centerLeft;
      } else if (align == TextAlign.right) {
        alignment = Alignment.centerRight;
      } else {
        alignment = Alignment.center;
      }

      return Expanded(
        flex: flex,
        child: scrollable
            ? ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Align(
                    alignment: alignment,
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              )
            : Align(
                alignment: alignment,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 5개 경매 퍼블리셔 정보',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              headerCell('날짜/시간', flex: 3),
              headerCell('성별', flex: 2),
              headerCell('연령대', flex: 3),
              headerCell('지역', flex: 3),
              headerCell('관심사', flex: 3),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 4),
          ...items.map((e) {
            final dt = e['created_at'] ?? '';
            final region = e['region'] ?? '';
            final age = e['age'] ?? '';
            final gender = e['gender'] ?? '';
            final hobby = e['hobby'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  dataCell(
                    _formatRecentDateTime(dt),
                    flex: 3,
                    align: TextAlign.left,
                    scrollable: true,
                  ),
                  dataCell(gender, flex: 2),
                  dataCell(age, flex: 3),
                  dataCell(region, flex: 3),
                  dataCell(hobby, flex: 3),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGenderCard() {
    if (_gender.isEmpty) {
      return _emptyCard('성별 데이터가 없습니다.');
    }

    int total = 0;
    for (final item in _gender) {
      final m = item as Map<String, dynamic>;
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      total += v;
    }
    if (total <= 0) {
      return _emptyCard('성별 데이터가 없습니다.');
    }

    final sections = <PieChartSectionData>[];
    final slices = <_SliceInfo>[];

    for (final item in _gender) {
      final m = item as Map<String, dynamic>;
      final label = m['label']?.toString() ?? 'unknown';
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      if (v <= 0) continue;

      String displayLabel;
      Color color;

      if (label == 'M') {
        displayLabel = '남성';
        color = const Color(0xFF2972C7);
      } else if (label == 'F') {
        displayLabel = '여성';
        color = const Color(0xFFFF9800);
      } else {
        displayLabel = '기타';
        color = const Color(0xFF9E9E9E);
      }

      final percent = total > 0 ? (v * 100 / total).round() : 0;

      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          color: color,
          radius: 34,
          title: '$percent%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

      slices.add(
        _SliceInfo(
          label: displayLabel,
          count: v,
          percent: percent,
        ),
      );
    }

    if (sections.isEmpty) {
      return _emptyCard('성별 데이터가 없습니다.');
    }

    final legendEntries = <_LegendEntry>[
      _LegendEntry(
        color: const Color(0xFFFF9800),
        label: '여성',
      ),
      _LegendEntry(
        color: const Color(0xFF2972C7),
        label: '남성',
      ),
    ];

    _SliceInfo? currentSlice;
    if (_touchedGenderIndex != null &&
        _touchedGenderIndex! >= 0 &&
        _touchedGenderIndex! < slices.length) {
      currentSlice = slices[_touchedGenderIndex!];
    }

    const chartHeight = 150.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '성별 비율',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                Center(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            setState(() {
                              _touchedGenderIndex = null;
                            });
                            return;
                          }
                          setState(() {
                            _touchedGenderIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (currentSlice != null)
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentSlice.label} : '
                          '${currentSlice.count}명 / ${currentSlice.percent}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendRows(legendEntries),
        ],
      ),
    );
  }

  Widget _buildAgeCard() {
    if (_age.isEmpty) {
      return _emptyCard('연령대 데이터가 없습니다.');
    }

    int total = 0;
    for (final item in _age) {
      final m = item as Map<String, dynamic>;
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      total += v;
    }
    if (total <= 0) {
      return _emptyCard('연령대 데이터가 없습니다.');
    }

    final sections = <PieChartSectionData>[];
    final legendEntries = <_LegendEntry>[];
    final slices = <_SliceInfo>[];

    final Map<String, Color> ageColors = {
      '20세 미만': const Color(0xFF4CAF50),
      '20대': const Color(0xFF2972C7),
      '30대': const Color(0xFFFFB74D),
      '40대': const Color(0xFFAB47BC),
      '50세 이상': const Color(0xFFE57373),
    };

    for (final item in _age) {
      final m = item as Map<String, dynamic>;
      final rawLabel = m['label']?.toString() ?? 'unknown';
      final label = _ageBucketLabel(rawLabel);
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      if (v <= 0) continue;

      final percent = total > 0 ? (v * 100 / total).round() : 0;
      final color = ageColors[label] ?? const Color(0xFF9E9E9E);

      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          color: color,
          radius: 34,
          title: percent < 10 ? '' : '$percent%',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

      legendEntries.add(_LegendEntry(color: color, label: label));
      slices.add(
        _SliceInfo(
          label: label,
          count: v,
          percent: percent,
        ),
      );
    }

    if (sections.isEmpty) {
      return _emptyCard('연령대 데이터가 없습니다.');
    }

    _SliceInfo? currentSlice;
    if (_touchedAgeIndex != null &&
        _touchedAgeIndex! >= 0 &&
        _touchedAgeIndex! < slices.length) {
      currentSlice = slices[_touchedAgeIndex!];
    }

    const chartHeight = 150.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연령대 분포',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                Center(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            setState(() {
                              _touchedAgeIndex = null;
                            });
                            return;
                          }
                          setState(() {
                            _touchedAgeIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (currentSlice != null)
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentSlice.label} : '
                          '${currentSlice.count}명 / ${currentSlice.percent}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendRows(legendEntries),
        ],
      ),
    );
  }

  Widget _buildLegendRows(List<_LegendEntry> entries) {
    final rows = <Widget>[];

    for (int i = 0; i < entries.length; i += 2) {
      final first = Expanded(
        child: _buildLegendItem(entries[i]),
      );

      Widget second;
      if (i + 1 < entries.length) {
        second = Expanded(
          child: _buildLegendItem(entries[i + 1]),
        );
      } else {
        second = const Spacer();
      }

      rows.add(
        Row(
          children: [
            first,
            const SizedBox(width: 12),
            second,
          ],
        ),
      );

      if (i + 2 < entries.length) {
        rows.add(const SizedBox(height: 4));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildLegendItem(_LegendEntry entry) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: entry.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            entry.label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard() {
    if (_region.isEmpty) {
      return _emptyCard('지역 데이터가 없습니다.');
    }

    final items = <Map<String, dynamic>>[];
    for (final item in _region) {
      final m = item as Map<String, dynamic>;
      final label = m['label']?.toString() ?? 'unknown';
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      if (v <= 0) continue;
      items.add({'label': label, 'count': v});
    }
    if (items.isEmpty) {
      return _emptyCard('지역 데이터가 없습니다.');
    }

    final limited = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '지역별 노출 상위',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...limited.map((e) {
            final label = e['label'] as String;
            final count = e['count'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '$count회',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHobbyCard() {
    if (_hobbies.isEmpty) {
      return _emptyCard('관심사 데이터가 없습니다.');
    }

    final items = <Map<String, dynamic>>[];
    for (final item in _hobbies) {
      final m = item as Map<String, dynamic>;
      final label = m['label']?.toString() ?? 'unknown';
      final c = m['count'];
      final v = c is int ? c : int.tryParse(c.toString()) ?? 0;
      if (v <= 0) continue;
      items.add({'label': label, 'count': v});
    }
    if (items.isEmpty) {
      return _emptyCard('관심사 데이터가 없습니다.');
    }

    final limited = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '관심사 상위',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...limited.map((e) {
            final label = e['label'] as String;
            final count = e['count'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '$count회',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _cardDecoration(),
      child: Text(
        msg,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _LegendEntry {
  final Color color;
  final String label;

  _LegendEntry({required this.color, required this.label});
}

class _SliceInfo {
  final String label;
  final int count;
  final int percent;

  _SliceInfo({
    required this.label,
    required this.count,
    required this.percent,
  });
}
