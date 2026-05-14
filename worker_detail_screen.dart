import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class WorkerDetailScreen extends StatefulWidget {
  final String projectId;
  final String workerId;
  final Map<String, dynamic> workerData;

  const WorkerDetailScreen({
    super.key,
    required this.projectId,
    required this.workerId,
    required this.workerData,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final Color brandColor = const Color(0xFF0D47A1);
  Set<DateTime> _presentDays = {};
  bool _isLoading = false;

  late TextEditingController nameController;
  late TextEditingController wageController;
  late TextEditingController phoneController;

  late DocumentReference _workerRef;
  late DocumentReference _projectRef;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.workerData['name'] ?? "");
    wageController = TextEditingController(
        text: widget.workerData['dailyWage']?.toString() ?? "");
    phoneController = TextEditingController(text: widget.workerData['phone'] ?? "");

    final uid = FirebaseAuth.instance.currentUser!.uid;
    _workerRef = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("projects").doc(widget.projectId)
        .collection("labor").doc(widget.workerId);

    _projectRef = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("projects").doc(widget.projectId);

    _loadAttendance();
  }

  void _loadAttendance() async {
    var snap = await _workerRef.collection("attendance").get();
    Set<DateTime> days = {};
    for (var doc in snap.docs) {
      DateTime dt = DateTime.parse(doc.id);
      days.add(DateTime(dt.year, dt.month, dt.day));
    }
    setState(() => _presentDays = days);
  }

  Future<void> _toggleDay(DateTime day) async {
    final dayKey =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    final normalized = DateTime(day.year, day.month, day.day);
    double wage = double.tryParse(wageController.text) ??
        (widget.workerData['dailyWage'] ?? 0).toDouble();

    setState(() => _isLoading = true);

    if (_presentDays.contains(normalized)) {
      await _workerRef.collection("attendance").doc(dayKey).delete();
      await _projectRef.update({"spent": FieldValue.increment(-wage)});
      await _workerRef.update({"totalEarned": FieldValue.increment(-wage)});
      setState(() => _presentDays.remove(normalized));
    } else {
      await _workerRef.collection("attendance").doc(dayKey).set({
        "date": dayKey,
        "wage": wage,
        "present": true,
      });
      await _projectRef.update({"spent": FieldValue.increment(wage)});
      await _workerRef.update({"totalEarned": FieldValue.increment(wage)});
      setState(() => _presentDays.add(normalized));
    }

    setState(() => _isLoading = false);
  }

  void _saveWorkerInfo() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    await _workerRef.update({
      "name": nameController.text,
      "dailyWage": double.tryParse(wageController.text) ?? 0,
      "phone": phoneController.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.workerInfoUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    double dailyWage = double.tryParse(wageController.text) ??
        double.tryParse(widget.workerData['dailyWage'].toString()) ?? 0.0;
    double totalEarned = _presentDays.length * dailyWage;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          widget.workerData['name'] ?? lang.workerDetail,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF0D2A6E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Info Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.workerInfo,
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16, color: brandColor)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: lang.workerName,
                      prefixIcon: const Icon(Icons.person_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: lang.workerPhone,
                      prefixIcon: const Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: wageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.dailyWageRs,
                      prefixIcon: const Icon(Icons.payments_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveWorkerInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(lang.saveChanges,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats ──
            Row(
              children: [
                _statBox(lang.daysPresent, "${_presentDays.length}", Colors.green[700]!),
                const SizedBox(width: 12),
                _statBox(lang.totalEarned, "Rs. ${totalEarned.toStringAsFixed(0)}", brandColor),
              ],
            ),

            const SizedBox(height: 20),

            // ── Calendar ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: brandColor),
                        const SizedBox(width: 8),
                        Text(lang.attendanceCalendar,
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: brandColor)),
                        if (_isLoading) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ],
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime(2024, 1, 1),
                    lastDay: DateTime(2026, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                          color: brandColor, fontWeight: FontWeight.bold),
                      selectedDecoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    selectedDayPredicate: (day) =>
                        _presentDays.contains(DateTime(day.year, day.month, day.day)),
                    onDaySelected: (selectedDay, focusedDay) =>
                        _toggleDay(selectedDay),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                                color: brandColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(lang.present, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                                color: Colors.grey[200], shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(lang.absent,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}