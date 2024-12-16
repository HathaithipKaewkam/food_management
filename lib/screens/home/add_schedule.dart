import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../common/colo_extension.dart';
import '../../../common/common.dart';
import '../../../common_widget/icon_title_next_row.dart';
import '../../../common_widget/round_button.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime date;
  const AddScheduleScreen({super.key, required this.date, required event});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  get event => null;

  @override
  Widget build(BuildContext context) {

    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/images/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Add Schedule",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset(
                "assets/images/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Image.asset(
                "assets/images/date.png",
                width: 20,
                height: 20,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                dateToString(widget.date, formatStr: "E, dd MMMM yyyy"),
                style: TextStyle(color: TColor.gray, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "Time",
            style: TextStyle(
                color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: media.width * 0.35,
            child: CupertinoDatePicker(
              onDateTimeChanged: (newDate) {},
              initialDateTime: DateTime.now(),
              use24hFormat: false,
              minuteInterval: 1,
              mode: CupertinoDatePickerMode.time,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "Detail",
            style: TextStyle(
                color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 8,
          ),
          IconTitleNextRow(
              icon: "assets/images/choose_meal.png",
              title: "Choose Meal",
              time: "Upperbody",
              color: TColor.lightGray,
              onPressed: () {}),
          const SizedBox(
            height: 10,
          ),
          IconTitleNextRow(
              icon: "assets/images/menu.png",
              title: "Menu",
              time: "Beginner",
              color: TColor.lightGray,
              onPressed: () {}),
          const SizedBox(
            height: 10,
          ),
          IconTitleNextRow(
              icon: "assets/images/priority.png",
              title: "Priority",
              time: "",
              color: TColor.lightGray,
              onPressed: () {}),
          const SizedBox(
            height: 10,
          ),
          IconTitleNextRow(
              icon: "assets/images/shopping_list.png",
              title: "Shopping List",
              time: "",
              color: TColor.lightGray,
              onPressed: () {}),
              const SizedBox(
            height: 10,
          ),
          IconTitleNextRow(
              icon: "assets/images/notes.png",
              title: "Notes",
              time: "",
              color: TColor.lightGray,
              onPressed: () {}),
          Spacer(),
          RoundButton(title: "Save", onPressed: () {}),
          const SizedBox(
            height: 20,
          ),
        ]),
      ),
    );
  }
}