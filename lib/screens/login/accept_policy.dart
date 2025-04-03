import 'package:flutter/material.dart';
import 'package:food_project/screens/login/food_preferences.dart';

class AcceptPolicyScreen extends StatefulWidget {
  @override
  _AcceptPolicyScreenState createState() => _AcceptPolicyScreenState();
}

class _AcceptPolicyScreenState extends State<AcceptPolicyScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // กลับไปหน้าก่อนหน้า
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionCard(
              title: '1. PRINCIPLES AND OBJECTIVES',
              content:
                  'Our application recognizes the importance of personal data and other user-related information. We are committed to ensuring transparency and accountability in the collection, use, and disclosure of your personal data in compliance with the Personal Data Protection Act (PDPA) and other relevant laws.'
                  'This Privacy Policy outlines how we collect, use, store, and protect your personal information. By using our application, you acknowledge that you have read and understood the terms outlined in this policy.',
            ),
            _buildSectionCard(
              title: '2. COLLECTION OF PERSONAL DATA',
              content:
                  'Personal data refers to information about an individual that can identify them directly or indirectly. We collect personal data only when necessary and use it appropriately.',
              additionalWidget:
                  _buildListSection('Personal Identifiable Information', [
                '• Name',
                '• Gender',
                '• Weight & Height',
                '• Date of Birth',
              ]),
            ),
            _buildSectionCard(
              title: '3. USER RIGHTS REGARDING PERSONAL DATA',
              content:
                  'Users have the right to access and review their personal data stored by the application. They can also edit or update their personal information to ensure accuracy.',
            ),
            _buildSectionCard(
              title: '4. AMENDMENTS TO THE PRIVACY POLICY',
              content:
                  'This privacy policy may be updated, modified, or changed as necessary to comply with personal data protection laws and other relevant regulations. We recommend that you periodically review this privacy policy for any updates.',
            ),
            _buildSectionCard(
              title: '5. CONTACT INFORMATION',
              content:
                  'If you have any questions, suggestions, or require further details, please contact:',
              additionalWidget: _buildListSection('Data Protection Officer', [
                '• Email: Hataichanok.kl@ku.th or Hathaithip.ka@ku.th',
                '• Phone: 089-497-8019 or 062-778-7998',
              ]),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I understand and agree to the Privacy Policy',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _isChecked
                    ? () {
                        // เมื่อกดยอมรับแล้ว ให้ไปหน้า FoodPreferences
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodPreferences(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF325b51), // ใช้สีพื้นหลังที่เข้ากับธีม
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง Section แบบการ์ด
  Widget _buildSectionCard({
    required String title,
    required String content,
    Widget? additionalWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(title),
              _buildSectionText(content),
              if (additionalWidget != null) additionalWidget,
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง title ของแต่ละ section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black, // เปลี่ยนสีหัวข้อเป็นสีดำ
        ),
      ),
    );
  }

  // Widget สำหรับสร้างข้อความของแต่ละ section
  Widget _buildSectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  // Widget สำหรับแสดงข้อมูลในรูปแบบรายการ
  Widget _buildListSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black, // เปลี่ยนสีหัวข้อรายการเป็นสีดำ
            ),
          ),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )),
        ],
      ),
    );
  }
}
