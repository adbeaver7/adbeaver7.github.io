import 'package:flutter/material.dart';

class BellScreen extends StatelessWidget {
  const BellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BellForm();
  }
}

class BellForm extends StatefulWidget {
  const BellForm({super.key});

  @override
  State<BellForm> createState() => _BellFormState();
}

class _BellFormState extends State<BellForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "알림 센터",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "모두 읽음",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDateHeader("오늘"),

          _buildNotificationCard(
            type: NotificationType.success,
            title: "광고가 채택되었습니다!",
            message: "'가을 신상 프로모션' 광고가 '450원에 채택되었습니다.",
            time: "방금 전",
            isRead: false,
          ),

          const SizedBox(height: 12),

          _buildNotificationCard(
            type: NotificationType.error,
            title: "광고 심사가 반려되었습니다.",
            message: "'여름 바캉스 기획전' 광고가 이미지 규격 미준수로 인해 반려되었습니다. 수정 후 재신청해주세요.",
            time: "2시간 전",
            isRead: true,
          ),

          const SizedBox(height: 24),

          _buildDateHeader("지난 알림"),

          _buildNotificationCard(
            type: NotificationType.info,
            title: "지갑이 충전되었습니다.",
            message: "요청하신 500,000원이 충전 완료되었습니다.",
            time: "1일 전",
            isRead: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        date,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required NotificationType type,
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    Color iconBgColor;
    IconData iconData;

    switch (type) {
      case NotificationType.success:
        iconBgColor = const Color(0xFF2972C7);
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        iconBgColor = const Color(0xFFFF5A5A);
        iconData = Icons.error_outline;
        break;
      case NotificationType.info:
        iconBgColor = const Color(0xFFED8639);
        iconData = Icons.info_outline;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFFDFDFD) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconBgColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: isRead ? Colors.grey[800] : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


enum NotificationType {
  success,
  error,
  info
}