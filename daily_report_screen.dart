import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class DailyReportScreen extends StatefulWidget {
  final String projectId;
  const DailyReportScreen({super.key, required this.projectId});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final horizontalPadding = isTablet ? size.width * 0.06 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          lang.dailySiteReports,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0D2A6E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("projects")
            .doc(widget.projectId)
            .collection("reports")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D2A6E)),
            );
          }

          List<DateTime> reportedDates = [];
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('timestamp') && data['timestamp'] != null) {
                Timestamp ts = data['timestamp'];
                reportedDates.add(DateTime(
                  ts.toDate().year,
                  ts.toDate().month,
                  ts.toDate().day,
                ));
              }
            }
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
                final bool isSideBySide = isLandscape || isTablet;

                Widget calendarWidget = Container(
                  margin: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {CalendarFormat.month: ''},
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            DateTime normalized = DateTime(date.year, date.month, date.day);
                            if (reportedDates.contains(normalized)) {
                              return Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 9),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            color: Color(0xFF0D2A6E),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF0D2A6E)),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF0D2A6E)),
                          decoration: const BoxDecoration(color: Color(0xFFF0F4FF)),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                              color: Color(0xFF0D2A6E), fontWeight: FontWeight.w600, fontSize: 12),
                          weekendStyle: TextStyle(
                              color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                              color: Color(0xFF0D2A6E), shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.18),
                              shape: BoxShape.circle),
                          todayTextStyle: const TextStyle(
                              color: Color(0xFF0D2A6E), fontWeight: FontWeight.bold),
                          selectedTextStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          weekendTextStyle: const TextStyle(color: Color(0xFF1565C0)),
                          outsideDaysVisible: false,
                          cellMargin: const EdgeInsets.all(4),
                        ),
                        rowHeight: isSideBySide ? 34 : 44,
                        daysOfWeekHeight: 20,
                      ),
                    ),
                  ),
                );

                Widget reportsWidget = Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D2A6E),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDay != null
                                    ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year} — ${lang.reports}"
                                    : lang.reports,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D2A6E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Image List
                      Expanded(
                        child: _buildImageDetails(
                            snapshot.data?.docs ?? [], isTablet, lang),
                      ),
                    ],
                  ),
                );

                // ── Side by Side (tablet / landscape) ──
                if (isSideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.48,
                        child: calendarWidget,
                      ),
                      reportsWidget,           // <-- Expanded wrapper hata diya
                    ],
                  );
                }

                // ── Portrait (phone) — stacked ──
                return Column(
                  children: [
                    calendarWidget,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2A6E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDay != null
                                  ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year} — ${lang.reports}"
                                  : lang.reports,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D2A6E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildImageDetails(
                          snapshot.data?.docs ?? [], isTablet, lang),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageDetails(
      List<QueryDocumentSnapshot> allDocs, bool isTablet, AppLanguage lang) {
    var filteredDocs = allDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('timestamp') || data['timestamp'] == null) return false;
      Timestamp ts = data['timestamp'];
      return isSameDay(ts.toDate(), _selectedDay);
    }).toList();

    if (filteredDocs.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF8),
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: const Icon(Icons.photo_library_outlined,
                            size: 36, color: Color(0xFF0D2A6E)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.noReports,
                        style: const TextStyle(
                            color: Color(0xFF8898AA),
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.selectOtherDate,
                        style: const TextStyle(
                            color: Color(0xFFB0BAC9), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) {
          var data = filteredDocs[index].data() as Map<String, dynamic>;
          return _buildReportCard(data, lang);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        var data = filteredDocs[index].data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildReportCard(data, lang),
        );
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data, AppLanguage lang) {
    String base64Image = data['image'] ?? "";
    String? note = data['note'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Expanded(
        child: Stack(
          children: [
            Image.memory(
              base64Decode(base64Image.split(',').last),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFEEF2FA),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 40, color: Color(0xFFB0BAC9)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A6E).withOpacity(0.82),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      lang.sitePhoto,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}