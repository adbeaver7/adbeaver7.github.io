import 'dart:async';

import 'package:adbeaver/config.dart';
import 'package:adbeaver/services/signup_bonus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:adbeaver/bell.dart';
import 'package:adbeaver/user.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:adbeaver/ad_create/ad_create_step_1.dart';
import 'package:adbeaver/ad_detail/ad_detail_step_1.dart';

class MainBoardScreen extends StatelessWidget {
  const MainBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainBoardForm();
  }
}

class MainBoardForm extends StatefulWidget {
  const MainBoardForm({super.key});

  @override
  State<MainBoardForm> createState() => _MainBoardFormState();
}

class _MainBoardFormState extends State<MainBoardForm> {
  List<dynamic> _myAds = [];
  bool _isLoading = true;

  int _totalCount = 0;
  int _ongoingCount = 0;
  int _completedCount = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SignupBonusManager.checkAndShowBonus(context);
      await _fetchAds();
      _startAutoRefresh();
    });
    Future.microtask(() async {
      final userProvider = context.read<UserProvider>();
      if (userProvider.userId != null) {
        await userProvider.refreshWallet();
      }
    });
  }

  void _onCreateAdPressed() {
    final userProvider = context.read<UserProvider>();
    final bid = userProvider.bid;
    final money = userProvider.money;

    if (bid <= 0) {
      _showDialog(
        title: '광고 티켓 부족',
        message: '보유 광고 티켓이 0개입니다.\n티켓을 충전한 후 다시 시도해주세요.',
      );
      return;
    }

    if (money <= 0) {
      _showDialog(
        title: '예산 부족',
        message: '보유 광고 예산이 0원입니다.\n예산을 충전한 후 다시 시도해주세요.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdCreateStep1Form(),
      ),
    );
  }

  void _showDialog({
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.shade50 : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? Colors.red : Colors.blue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;
      _fetchAds();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    final userId = context.read<UserProvider>().userId;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    if (userId == null) {
      if (mounted) {
        setState(() {
          _myAds = [];
          _isLoading = false;
          _totalCount = 0;
          _ongoingCount = 0;
          _completedCount = 0;
        });
      }
      return;
    }

    try {
      final dio = Dio();
      final response =
          await dio.get('${ServerConfig.nodeBaseUrl}/api/ads/user/$userId');

      if (mounted) {
        setState(() {
          _myAds = response.data;
          _sortAds();
          _isLoading = false;
          _calculateStats();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

int _getRemainingBudget(dynamic ad) {
  final dynamic display = ad['display_budget'];
  if (display != null) {
    final parsed = int.tryParse(display.toString());
    if (parsed != null) return parsed;
  }

  final dynamic rtbRem = ad['rtb_remaining_budget'];
  if (rtbRem != null) {
    final parsed = int.tryParse(rtbRem.toString());
    if (parsed != null) return parsed;
  }

  final int cost = int.tryParse(ad['cost']?.toString() ?? '0') ?? 0;
  return (cost * 0.2).round();
}

  bool _isFinished(dynamic ad) {
    final String rawState = (ad['adstate'] as String?) ?? '';
    if (rawState == 'FINISHED') return true;
    if (rawState == 'DELETED') return true;
    final int remaining = _getRemainingBudget(ad);
    return remaining <= 0;
  }

  void _sortAds() {
    const Map<String, int> priority = {
      'ACTIVE': 0,
      'SCHEDULED': 1,
      'PAUSED': 2,
      'FINISHED': 3,
    };

    _myAds.sort((a, b) {
      final String sa = (a['adstate'] as String?) ?? '';
      final String sb = (b['adstate'] as String?) ?? '';

      final bool aFinished = _isFinished(a);
      final bool bFinished = _isFinished(b);

      final int pa =
          aFinished ? (priority['FINISHED'] ?? 3) : (priority[sa] ?? 99);
      final int pb =
          bFinished ? (priority['FINISHED'] ?? 3) : (priority[sb] ?? 99);

      if (pa != pb) return pa.compareTo(pb);

      final DateTime startA = a['start_date'] != null
          ? DateTime.parse(a['start_date']).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime startB = b['start_date'] != null
          ? DateTime.parse(b['start_date']).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(0);

      return startB.compareTo(startA);
    });
  }

  void _calculateStats() {
    int ongoing = 0;
    int completed = 0;

    for (var ad in _myAds) {
      if (_isFinished(ad)) {
        completed++;
        continue;
      }

      final rawState = (ad['adstate'] as String?) ?? '';
      final remaining = _getRemainingBudget(ad);

      if (rawState == 'ACTIVE' && remaining > 0) {
        ongoing++;
      }
    }

    _totalCount = _myAds.length;
    _ongoingCount = ongoing;
    _completedCount = completed;
  }

  String _statusLabelFromAd(dynamic ad) {
    if (_isFinished(ad)) {
      return '완료됨';
    }

    final String raw = (ad['adstate'] as String?) ?? '';

    switch (raw) {
      case 'ACTIVE':
        return '진행중';
      case 'SCHEDULED':
        return '준비중';
      case 'PAUSED':
        return '중단중';
      default:
        return '알 수 없음';
    }
  }

  Color _statusColorFromAd(dynamic ad) {
    if (_isFinished(ad)) {
      return const Color(0xFF2EAB88);
    }

    final String raw = (ad['adstate'] as String?) ?? '';

    switch (raw) {
      case 'ACTIVE':
        return const Color(0xFF2972C7);
      case 'SCHEDULED':
        return Colors.orange;
      case 'PAUSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _calculateDuration(String? startDateStr) {
    if (startDateStr == null) return "-";

    final start = DateTime.parse(startDateStr);
    final startFormatted = DateFormat('yyyy.MM.dd').format(start);

    return "$startFormatted ~ 진행중";
  }

  String _formatStartDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      final local = parsed.toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(local);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
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
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectCard({
    required String title,
    required String status,
    required String budgetLabel,
    required String budgetValue,
    required String startDateText,
    required Color statusColor,
    required dynamic adData,
    required int adId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdDetailStep1Screen(adData: adData),
              ),
            );
            _fetchAds();
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoColumn(budgetLabel, budgetValue),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoColumn(
                      "시작일",
                      startDateText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAd(dynamic ad) {
    final int adId = ad['ad_id'] as int;
    final int remaining = _getRemainingBudget(ad);
    final bool finished = _isFinished(ad);
    final currencyFormat = NumberFormat('#,###');

    final int refundAmount = finished ? 0 : remaining;

    final String message = finished
        ? '이 광고를 삭제하시겠어요?\n이미 예산이 모두 사용된 광고입니다.'
        : '이 광고를 삭제하고 남은 예산 ${currencyFormat.format(remaining)}원을 환불받을까요?\n삭제된 광고는 되돌릴 수 없습니다.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '광고 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAd(adId, refundAmount);
            },
            child: const Text(
              '삭제하기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAd(int adId, int refundAmount) async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ServerConfig.nodeBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        ),
      );

      final response = await dio.delete(
        '/api/ads/$adId/delete',
        data: {
          'user_id': userId,
          'refund_amount': refundAmount,
        },
      );

      final data = response.data;

      if (data is Map && data['user'] != null) {
        final userJson = Map<String, dynamic>.from(data['user']);
        await userProvider.setUserFromApi(userJson);
      } else {
        await userProvider.refreshWallet();
      }

      await _fetchAds();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (data is Map && data['message'] is String)
                ? data['message'] as String
                : '광고가 삭제되었고 남은 예산이 환불되었습니다.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('광고 삭제 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('광고 삭제 중 오류가 발생했습니다. 다시 시도해주세요.'),
        ),
      );
    }
  }

  Future<void> _resumeAd(int adId) async {
    try {
      final dio = Dio();
      await dio.post(
        '${ServerConfig.nodeBaseUrl}/api/ads/$adId/resume',
      );

      await _fetchAds();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("광고가 다시 시작되었습니다.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("광고 재시작에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final userProvider = context.watch<UserProvider>();
    final int bid = userProvider.bid;
    final int money = userProvider.money;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserForm()),
            );
          },
          icon: const Icon(Icons.menu, color: Colors.black),
        ),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_num_outlined,
                  size: 18,
                  color: Color(0xFF2972C7),
                ),
                const SizedBox(width: 4),
                Text(
                  '$bid',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  size: 18,
                  color: Color(0xFF2EAB88),
                ),
                const SizedBox(width: 4),
                Text(
                  currencyFormat.format(money),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.black),
            onPressed: () async {
              await userProvider.refreshWallet();
              await _fetchAds();
              if (!mounted) return;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _statCard(
                    title: "전체",
                    value: _totalCount.toString(),
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    title: "진행중",
                    value: _ongoingCount.toString(),
                    color: const Color(0xFF2972C7),
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    title: "완료",
                    value: _completedCount.toString(),
                    color: const Color(0xFF2EAB88),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "광고 목록",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _fetchAds,
                    child: const Text(
                      "새로고침",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _myAds.isEmpty
                      ? const Center(child: Text("생성된 광고가 없습니다."))
                      : RefreshIndicator(
                          onRefresh: _fetchAds,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            itemCount: _myAds.length,
                            itemBuilder: (context, index) {
                              final ad = _myAds[index];
                              final statusLabel = _statusLabelFromAd(ad);
                              final statusColor = _statusColorFromAd(ad);

                              final int cost =
                                  int.tryParse(ad['cost']?.toString() ?? '0') ??
                                      0;
                              final int remaining = _getRemainingBudget(ad);
                              final bool finished = _isFinished(ad);

                              final String budgetLabel =
                                  finished ? "총 예산" : "남은 예산";
                              final int budgetAmount =
                                  finished ? cost : remaining;
                              final String budgetValue =
                                  "${currencyFormat.format(budgetAmount)}원";

                              final String startDateText =
                                  _formatStartDate(
                                      ad['start_date']?.toString());

                              return _projectCard(
                                title: ad['adname'] ?? '제목 없음',
                                status: statusLabel,
                                budgetLabel: budgetLabel,
                                budgetValue: budgetValue,
                                startDateText: startDateText,
                                statusColor: statusColor,
                                adData: ad,
                                adId: ad['ad_id'] as int,
                              );
                            },
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration:
                  const BoxDecoration(color: Color(0xFFF8F9FD)),
              child: ElevatedButton(
                onPressed: _onCreateAdPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2972C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "새 광고 만들기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
}
