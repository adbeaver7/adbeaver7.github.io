import 'package:adbeaver/services/ad_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ad_create_step_2.dart';

class AdCreateStep1Screen extends StatelessWidget {
  const AdCreateStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdCreateStep1Form();
  }
}

class AdCreateStep1Form extends StatefulWidget {
  const AdCreateStep1Form({super.key});

  @override
  State<AdCreateStep1Form> createState() => _AdCreateStep1FormState();
}

class _AdCreateStep1FormState extends State<AdCreateStep1Form> {
  final List<String> categories = [
    "식품/음료", "스포츠", "화장품/뷰티", "의약품/건강",
    "통신/IT", "금융", "전자제품", "자동차",
    "교육/학습", "게임/엔터", "경제/부동산", "여행/레저",
    "반려동물", "패션/의류",
  ];

  late List<bool> isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = List.generate(categories.length, (index) => false);
  }

  void _onCategorySelected(int index) {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "광고 만들기",
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "어떤 카테고리의 광고인가요?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final bool selected = isSelected[index];
                    return GestureDetector(
                      onTap: () => _onCategorySelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF2972C7) : Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF2972C7)
                                : Colors.grey.shade200,
                            width: selected ? 0 : 1,
                          ),
                          boxShadow: [
                            if (!selected)
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 0,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey[700],
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 30.0),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FD),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (!isSelected.contains(true)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("카테고리를 선택해주세요.")),
                    );
                    return;
                  }

                  final selectedIndex = isSelected.indexOf(true);
                  final selectedCategory = categories[selectedIndex];

                  context.read<AdCreationProvider>().setCategory(selectedCategory);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdCreateStep2Form(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: const Color(0xFF2972C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0)),
                ),
                child: const Text(
                  "다음으로",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}