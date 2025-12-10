import 'package:flutter/material.dart';

class ErrorSpaceScreen extends StatelessWidget {
  final double minWidth;
  final double minHeight;

  const ErrorSpaceScreen({
    super.key,
    required this.minWidth,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final current = '${size.width.toInt()} × ${size.height.toInt()}';
    final orientationText =
        orientation == Orientation.landscape ? '가로 모드' : '세로 모드';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // 화면이 작아도 스크롤로 해결 가능하게 최소 높이만 화면 높이에 맞춤
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          const Icon(
                            Icons.phone_android_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '화면이 너무 작아요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '이 화면은 세로 방향 기준으로\n'
                            '가로 최소 ${minWidth.toInt()}px, 세로 최소 ${minHeight.toInt()}px '
                            '이상에서만 표시됩니다.\n\n'
                            '브라우저 창 크기를 키워주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              '현재 해상도: $current • $orientationText',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}