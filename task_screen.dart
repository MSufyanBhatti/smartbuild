import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class TaskScreen extends StatefulWidget {
  final String projectId;
  const TaskScreen({super.key, required this.projectId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _tasksRef => FirebaseFirestore.instance
      .collection("users")
      .doc(_uid)
      .collection("projects")
      .doc(widget.projectId)
      .collection("tasks");

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final TextEditingController _taskController = TextEditingController();

  String _format(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  List _getEventsForDay(DateTime day, List<QueryDocumentSnapshot> tasks) {
    String dayKey = _format(day);
    return tasks.where((t) {
      final data = t.data() as Map<String, dynamic>;
      return data["date"] == dayKey;
    }).toList();
  }

  Future<void> _addTask() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    if (_taskController.text.isEmpty || widget.projectId.isEmpty) return;
    try {
      await _tasksRef.add({
        "title": _taskController.text,
        "date": _format(_selectedDay),
        "isDone": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
      _taskController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${lang.errorAddingTask}: $e")),
      );
    }
  }

  Future<void> _toggle(String id, bool val) async {
    await _tasksRef.doc(id).update({"isDone": !val});
  }

  Future<void> _checkAndCarryForward() async {
    if (widget.projectId.isEmpty) return;
    try {
      String todayKey = _format(DateTime.now());
      var snapshot = await _tasksRef.where("isDone", isEqualTo: false).get();
      var pastPendingTasks = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String taskDate = data["date"] ?? "";
        return taskDate.isNotEmpty &&
            taskDate.compareTo(todayKey) < 0 &&
            data["carried"] != true;
      }).toList();

      if (pastPendingTasks.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in pastPendingTasks) {
          final data = doc.data() as Map<String, dynamic>;
          DocumentReference newDoc = _tasksRef.doc();
          batch.set(newDoc, {
            "title": data["title"],
            "date": todayKey,
            "isDone": false,
            "createdAt": FieldValue.serverTimestamp(),
            "carriedFrom": doc.id,
          });
          batch.update(doc.reference, {"carried": true});
        }
        await batch.commit();
      }
    } catch (e) {
      print("Carry forward error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndCarryForward();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final String selectedKey = _format(_selectedDay);
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final double hPad = isTablet ? 24.0 : 12.0;

    return Scaffold(

        resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          lang.dailySiteTasks,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isTablet ? 20 : 17,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLandscape
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.42,
            child: Column(
              children: [
                _buildCalendar(lang, isLandscape: true),
                _buildInput(lang, hPad: 10),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey[200]),
          Expanded(
            child: _buildTaskList(
              lang,
              selectedKey: selectedKey,
              hPad: 10,
            ),
          ),
        ],
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildCalendar(lang, isLandscape: false),
            _buildInput(lang, hPad: hPad),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildTaskList(
                lang,
                selectedKey: selectedKey,
                hPad: hPad,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calendar widget ──
  Widget _buildCalendar(AppLanguage lang, {required bool isLandscape}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _tasksRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var allTasks = snapshot.data!.docs;

        return  ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isLandscape ? 200 : 120,
            ),
            child:TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          eventLoader: (day) => _getEventsForDay(day, allTasks),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLandscape ? 13 : 15,
              color: Colors.blue[900],
            ),
            leftChevronPadding: const EdgeInsets.all(4),
            rightChevronPadding: const EdgeInsets.all(4),
            headerPadding: EdgeInsets.symmetric(
              vertical: isLandscape ? 4 : 8,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: isLandscape ? 10 : 12,
              color: Colors.grey[600],
            ),
            weekendStyle: TextStyle(
              fontSize: isLandscape ? 10 : 12,
              color: Colors.red[300],
            ),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: EdgeInsets.all(isLandscape ? 2 : 4),
            defaultTextStyle: TextStyle(fontSize: isLandscape ? 11 : 13),
            weekendTextStyle: TextStyle(
              fontSize: isLandscape ? 11 : 13,
              color: Colors.red[400],
            ),
            selectedTextStyle: TextStyle(
              fontSize: isLandscape ? 11 : 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue[900],
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue[200],
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              fontSize: isLandscape ? 11 : 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            outsideDaysVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                bool hasPending = events.any((e) =>
                (e as QueryDocumentSnapshot)["isDone"] == false);
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: isLandscape ? 5 : 7,
                    height: isLandscape ? 5 : 7,
                    decoration: BoxDecoration(
                      color: hasPending ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
            )
        );
      },
    );
  }

  // ── Input row ──
  Widget _buildInput(AppLanguage lang, {required double hPad}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: lang.whatNeedsDone,
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton.filled(
              padding: EdgeInsets.zero,
              onPressed: _addTask,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Task list ──
  Widget _buildTaskList(AppLanguage lang,
      {required String selectedKey, required double hPad}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _tasksRef.where("date", isEqualTo: selectedKey).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(fontSize: 13),
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  lang.noTasksForDay,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];
            final data = task.data() as Map<String, dynamic>;
            bool isDone = data["isDone"] ?? false;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                leading: Checkbox(
                  value: isDone,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => _toggle(task.id, isDone),
                ),
                title: Text(
                  data["title"] ?? "No Title",
                  style: TextStyle(
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => task.reference.delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}