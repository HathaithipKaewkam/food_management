import 'package:flutter/material.dart';
import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import '../common/colo_extension.dart';

class InstructionsWidget extends StatelessWidget {
  final List<String> instructions;

  const InstructionsWidget({
    super.key,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // เว้นระยะระหว่างซ้าย-ขวา
            children: [
              const Text(
                "How To Do It",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${instructions.length} steps", // แสดงจำนวนขั้นตอน
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // ลดระยะห่างระหว่างหัวข้อกับรายการ
          ListView.builder(
            shrinkWrap: true, // ช่วยให้ ListView ไม่ขยายเกินขนาด
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero, 
            itemCount: instructions.length,
            itemBuilder: (context, index) {
              return RecipeStep(
                sObj: {
                  "no": index + 1,
                  "detail": instructions[index],
                },
                isLast: index == instructions.length - 1,
              );
            },
          ),
        ],
      );
    
  }
}

class RecipeStep extends StatelessWidget {
  final Map sObj;
  final bool isLast;
  const RecipeStep({super.key, required this.sObj, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(color: TColor.white, width: 3),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            if (!isLast)
              DottedDashedLine(
                  height: 50,
                  width: 0,
                  dashColor: Colors.greenAccent,
                  axis: Axis.vertical)
          ],
        ), 
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Step ${sObj["no"].toString()}",
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                sObj["detail"].toString(),
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
