import 'package:flutter/material.dart';
import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import '../common/colo_extension.dart';

class AddInstruction extends StatefulWidget {
  final List<String> instructions;
  final Function(String)? onAddInstruction;
  final Function(int)? onRemoveInstruction;

  const AddInstruction({
    super.key,
    required this.instructions,
    this.onAddInstruction,
    this.onRemoveInstruction,
  });

  @override
  State<AddInstruction> createState() => _AddInstructionState();
}

class _AddInstructionState extends State<AddInstruction> {
  void _showAddStepBottomSheet() {
    final TextEditingController stepController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.only(
            bottom: 10,
            right: 15,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Step',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: stepController,
                    decoration: InputDecoration(
                      hintText: 'Enter step instructions',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter step instructions';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Add Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              String stepDescription =
                                  stepController.text.trim();

                              // ส่งข้อมูลขั้นตอนใหม่กลับไปยังหน้าหลัก
                              if (widget.onAddInstruction != null) {
                                widget.onAddInstruction!(stepDescription);
                              }

                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFF78d454),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (widget.onAddInstruction != null)
                  ElevatedButton.icon(
                    onPressed: _showAddStepBottomSheet,
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text("Add Step"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF78d454),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
         ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.instructions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Delete Step"),
                    content: Text("Are you sure you want to delete this step?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("CANCEL"),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onRemoveInstruction != null) {
                            widget.onRemoveInstruction!(index);
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text("DELETE", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แสดงหมายเลขขั้นตอนและเส้นประ
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: TColor.secondaryColor1,
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
                      if (index != widget.instructions.length - 1)
                        DottedDashedLine(
                          height: 50,
                          width: 0,
                          dashColor: TColor.secondaryColor1,
                          axis: Axis.vertical,
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Step ${index + 1}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.instructions[index],
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  // เพิ่มปุ่มลบด้านขวา
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Delete Step"),
                            content: Text("Are you sure you want to delete this step?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text("CANCEL"),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (widget.onRemoveInstruction != null) {
                                    widget.onRemoveInstruction!(index);
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: Text("DELETE"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
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
                color: Colors.greenAccent,
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
                  dashColor: Colors.green,
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
