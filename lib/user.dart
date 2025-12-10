import 'package:adbeaver/myinformation.dart';
import 'package:adbeaver/services/ad_provider.dart';
import 'package:adbeaver/services/user_provider.dart';
import 'package:adbeaver/use_app.dart';
import 'package:flutter/material.dart';
import 'package:adbeaver/login.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserForm();
  }
}

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userProvider = context.read<UserProvider>();
      if (userProvider.userId != null) {
        userProvider.refreshWallet();
      }
    });
  }
  Future<void> _openInquiryForm() async {
    final uri = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSemp3NOiTf_h7mBxPKvkneTlP2HMmtsF8bsie_RBjz1R21Dfg/viewform?usp=header');

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
  }


  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "로그아웃 하시겠어요?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          "현재 계정에서 로그아웃됩니다.\n다시 로그인해야 서비스를 이용할 수 있어요.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              context.read<UserProvider>().logout();
              context.read<AdCreationProvider>().resetForm();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginForm()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5A5A),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text("로그아웃"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
        ),
        actions: const [
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 18),

              _buildTicketCard(),

              const SizedBox(height: 12),

              _buildWalletCard(),

              const SizedBox(height: 18),

              _buildSectionTitle("내 정보"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(Icons.person_outline, "내 정보",
                        onTap: () {
                          Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => const MyInformationScreen(),
                           ),
                         );
                        }),
                    _buildDivider(),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _buildSectionTitle("고객 지원"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(Icons.headset_mic_outlined, "고객의견",
                        onTap: _openInquiryForm),
                    _buildDivider(),
                    _buildMenuTile(Icons.description_outlined, "이용약관",
                        onTap: () {  Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsScreen(),
                              ),
                            );}),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  "로그아웃",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
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

  Widget _buildProfileHeader() {
    final userProvider = context.watch<UserProvider>();
    final nickname = userProvider.nickname ?? '광고주';
    final email = userProvider.email ?? '이메일 표시';

    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200, width: 2),
            image: const DecorationImage(
              image: AssetImage("assets/images/adbeaver.png"),
              fit: BoxFit.contain,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$nickname 광고주님",
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTicketCard() {
    final userProvider = context.watch<UserProvider>();
    final bid = userProvider.bid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC71).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "보유 광고 티켓",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$bid 개",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final userProvider = context.watch<UserProvider>();
    final money = userProvider.money;

    final formatter = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2972C7), Color(0xFF4C90E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2972C7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "보유 광고 예산",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${formatter.format(money)} 원",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title,
      {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2972C7), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF5F6FA),
      indent: 16,
      endIndent: 16,
    );
  }
}
