import 'package:flutter/material.dart';
import 'package:adbeaver/useterms.dart';
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "이용약관",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              termsOfUse,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          )
        ),
      ),
      backgroundColor: const Color(0xFFF8F9FD),
    );
  }
}
