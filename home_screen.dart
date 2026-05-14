import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'project_screen.dart';
import 'login_screen.dart';
import 'project_detail_screen.dart';
import 'estimation_screen.dart';
import 'scanner_screen.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';
import 'billing_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Constructor";
  final TextEditingController nameController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final Color brandColor = const Color(0xFF0D47A1);

  double _parseSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  void getUserName() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    var userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (userData.exists) {
      setState(() {
        userName = userData['name'];
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  LANGUAGE DIALOG
  // ════════════════════════════════════════════════════════════════════════
  // void _showLanguageDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) {
  //       final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //         title: Row(
  //           children: [
  //             Icon(Icons.language_rounded, color: brandColor),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               child: Text(lang.selectLanguage,
  //                 style: const TextStyle(fontWeight: FontWeight.bold),
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             _langOption(dialogContext, "English", "EN", AppLang.english),
  //             const SizedBox(height: 10),
  //             _langOption(dialogContext, "اردو", "UR", AppLang.urdu),
  //             const SizedBox(height: 10),
  //             _langOption(dialogContext, "Roman Urdu", "RO", AppLang.roman),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _langOption(BuildContext context, String label, String badge, AppLang langType) {
    final appLang = Provider.of<AppLanguage>(context, listen: false);
    final isSelected = appLang.lang == langType;
    return GestureDetector(
      onTap: () async {
        await appLang.setLanguage(langType);
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandColor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? brandColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? brandColor : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: brandColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  LOW BUDGET ALERTS
  // ════════════════════════════════════════════════════════════════════════
  void _showLowBudgetAlerts(BuildContext context, List<Map<String, dynamic>> lowBudgetProjects) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(lang.criticalBudget,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: lowBudgetProjects.isEmpty
                ? Text(lang.allSitesFunded)
                : ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.6),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lowBudgetProjects.length,
                itemBuilder: (_, index) {
                  var project = lowBudgetProjects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red)),
                        const SizedBox(height: 4),
                        Text(
                          "${lang.remaining}: Rs. ${project['remaining'].toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.close,
                  style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }


  // ════════════════════════════════════════════════════════════════════════
  //  BUDGET BREAKDOWN
  // ════════════════════════════════════════════════════════════════════════
  void _showBudgetBreakdownDialog(BuildContext context, List<QueryDocumentSnapshot> projects) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(lang.budgetBreakdown,
                    style: const TextStyle(fontWeight: FontWeight.bold),

                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: projects.isEmpty
                ? Text(lang.noProjects)
                : ConstrainedBox(
              constraints: BoxConstraints(

                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.6),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (_, index) {
                  var data = projects[index].data() as Map<String, dynamic>;
                  double budget = _parseSafe(data['budget']);
                  double spent = _parseSafe(data['spent']);
                  double remaining = budget - spent;
                  double percent = budget > 0 ? (spent / budget) * 100 : 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? "Unnamed Project",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: brandColor)),
                          const Divider(height: 20),
                          _buildBudgetRow(lang.totalBudget,
                              "Rs. ${budget.toStringAsFixed(0)}", Colors.black87),
                          _buildBudgetRow(lang.totalSpent,
                              "Rs. ${spent.toStringAsFixed(0)}", Colors.red[700]!),
                          _buildBudgetRow(
                              lang.remaining,
                              "Rs. ${remaining.toStringAsFixed(0)}",
                              remaining >= 0 ? Colors.green[700]! : Colors.redAccent),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: budget > 0 ? (spent / budget) : 0,
                              backgroundColor: Colors.grey[200],
                              color: percent > 90 ? Colors.red : Colors.green,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                                "${percent.toStringAsFixed(1)}% ${lang.used}",
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.close,
                  style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CLIENTS DIALOG
  // ════════════════════════════════════════════════════════════════════════
  void _showClientsDialog(BuildContext context, List<QueryDocumentSnapshot> projects) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          title: Row(
            children: [
              Icon(Icons.people_alt_rounded, color: Colors.purple[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(lang.clientPortfolio,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: projects.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(lang.noClientData),
            )
                : ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.6),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (_, index) {
                  var data = projects[index].data() as Map<String, dynamic>;
                  String clientName = data['client'] ?? "Unknown Client";
                  String projectName = data['name'] ?? "Unnamed Project";
                  String phone = data['phone'] ?? "No Phone";
                  double budget = _parseSafe(data['budget']);
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: Icon(Icons.person_rounded,
                            color: Colors.purple[700], size: 18),
                      ),
                      title: Text(clientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        "${lang.site}: $projectName\n$phone",
                        style: const TextStyle(
                            fontSize: 11, color: Colors.blueGrey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: FittedBox(
                        child: Text("Rs. ${budget.toStringAsFixed(0)}",
                            style: TextStyle(
                                color: brandColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          dialogContext,
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailScreen(
                              projectId: projects[index].id,
                              projectName: projectName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.close,
                  style: TextStyle(
                      color: brandColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  ACTIVE PROJECTS DIALOG
  // ════════════════════════════════════════════════════════════════════════
  void _showActiveProjectsDialog(BuildContext context, List<QueryDocumentSnapshot> projects) {
    var activeProjects = projects.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _parseSafe(data['progress']) < 1.0;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.construction_rounded, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Text(lang.activeSitesTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: activeProjects.isEmpty
                ? Text(lang.noActiveProjects)
                : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.5,
                maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeProjects.length,
                itemBuilder: (_, index) {
                  var data = activeProjects[index].data() as Map<String, dynamic>;
                  double progress = _parseSafe(data['progress']);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: Icon(Icons.location_on_rounded,
                          color: Colors.orange[800], size: 24),
                    ),
                    title: Text(data['name'] ?? "Unnamed Project",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(
                      "${lang.progress}: ${(progress * 100).toInt()}% ${lang.completed}",
                      style: const TextStyle(fontSize: 15),
                    ),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        dialogContext,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(
                            projectId: activeProjects[index].id,
                            projectName: data['name'] ?? "Project",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.close,
                  style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
  void _showPaywallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Premium Feature",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        size: 48, color: Colors.amber[700]),
                    const SizedBox(height: 12),
                    const Text(
                      "AI Map Scanner",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "For Blueprint analyze Subscription must be active .",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: brandColor, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Add payment method to continue.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BillingScreen()));
              },
              icon: const Icon(Icons.payment_rounded, color: Colors.white),
              label: const Text("Subscribe",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  PROJECT STATUS DIALOG
  // ════════════════════════════════════════════════════════════════════════
  void _showProjectStatusDialog(BuildContext context, int active, int completed) {
    showDialog(
      context: context,
      useRootNavigator: false,

      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lang.projectsOverview,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content:  SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusTile(lang.ongoingSites, "$active", Colors.orange[800]!),
                const SizedBox(height: 12),
                _buildStatusTile(lang.finishedProjects, "$completed", Colors.green[700]!),
              ],
                        ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.close,
                  style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusTile(String title, String count, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = MediaQuery.of(context).size.width < 380;
        return Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: isSmall ? 13 : 16),
                    overflow: TextOverflow.ellipsis),
              ),
              FittedBox(
                child: Text(count,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 20 : 24,
                        color: color)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  ADD PROJECT DIALOG
  // ════════════════════════════════════════════════════════════════════════
  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,


      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(lang.newSiteEnrollment,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: lang.projectName,
                    prefixIcon: const Icon(Icons.business_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: clientController,
                  decoration: InputDecoration(
                    labelText: lang.clientName,
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: lang.phoneNumber,
                    prefixIcon: const Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.cancel, style: const TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .collection("projects")
                        .add({
                      "name": nameController.text,
                      "client": clientController.text,
                      "phone": phoneController.text,
                      "budget": 0,
                      "spent": 0,
                      "progress": 0.0,
                      "status": "active",
                      "createdAt": DateTime.now(),
                    });
                    nameController.clear();
                    clientController.clear();
                    phoneController.clear();
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(lang.startProject,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    String today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.engineering_rounded, color: brandColor, size: 24),
            ),
            const SizedBox(width: 10),
            Text("SmartBuild",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: brandColor)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red[700], size: 20),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => login_screen()));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("projects")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Something went wrong"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var projects = snapshot.data!.docs;
          double totalBudget = 0;
          double totalSpent = 0;
          int activeCount = 0;
          int completedCount = 0;
          List<Map<String, dynamic>> lowBudgetProjects = [];

          for (var doc in projects) {
            var data = doc.data() as Map<String, dynamic>;
            double budget = _parseSafe(data['budget']);
            double spent = _parseSafe(data['spent']);
            double remaining = budget - spent;
            if (_parseSafe(data['progress']) >= 1.0) {
              completedCount++;
            } else {
              activeCount++;
              if (budget > 0 && remaining < 200000) {
                lowBudgetProjects.add({
                  "name": data['name'] ?? "Unnamed",
                  "remaining": remaining
                });
              }
            }
            totalBudget += budget;
            totalSpent += spent;
          }

          double budgetUsagePercent =
          totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.welcomeBack,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                        Builder(builder: (context) {
                          final isSmall = MediaQuery.of(context).size.width < 380;
                          return Text(userName,
                              style: TextStyle(
                                  fontSize: isSmall ? 24 : 32,
                                  fontWeight: FontWeight.w900,
                                  color: brandColor));
                        }),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          // onTap: () => _showLanguageDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            // decoration: BoxDecoration(
                            //   color: Colors.white,
                            //   borderRadius: BorderRadius.circular(15),
                            //   boxShadow: [BoxShadow(
                            //       color: Colors.black.withOpacity(0.05),
                            //       blurRadius: 10)],
                            // ),
                           // child: Icon(Icons.language_rounded, color: brandColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showLowBudgetAlerts(context, lowBudgetProjects),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10)],
                                ),
                                child: Icon(Icons.notifications_none_rounded,
                                    color: brandColor),
                              ),
                              if (lowBudgetProjects.isNotEmpty)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    constraints: const BoxConstraints(
                                        minWidth: 10, minHeight: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(today,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: _buildModernCard(
                      context,
                      lang.totalProjects,
                      "${projects.length}",
                      Icons.architecture_rounded,
                      [const Color(0xFF3949AB), const Color(0xFF1A237E)],
                          () => _showProjectStatusDialog(context, activeCount, completedCount),
                    ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernCard(
                      context,
                      lang.activeSites,
                      "$activeCount",
                      Icons.construction_rounded,
                      [const Color(0xFFF57C00), const Color(0xFFE65100)],
                          () => _showActiveProjectsDialog(context, projects),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildModernCard(
                      context,
                      lang.budgetUsed,
                      "${budgetUsagePercent.toInt()}%",
                      Icons.account_balance_wallet_rounded,
                      [const Color(0xFF43A047), const Color(0xFF1B5E20)],
                          () => _showBudgetBreakdownDialog(context, projects),
                    ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernCard(
                      context,
                      lang.ourClients,
                      "${projects.length}",
                      Icons.people_alt_rounded,
                      [const Color(0xFF8E24AA), const Color(0xFF4A148C)],
                          () => _showClientsDialog(context, projects),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Text(lang.smartTools,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildToolButton(context, lang.addExpenseManually,
                          Icons.calculate_rounded, Colors.teal, () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EstimationScreen()));
                          }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildToolButton(context, lang.aiMapScanner,
                              Icons.qr_code_scanner_rounded, Colors.blueGrey, () async {
                                final uid = FirebaseAuth.instance.currentUser!.uid;
                                final userDoc = await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(uid)
                                    .get();
                                final data = userDoc.data() as Map<String, dynamic>? ?? {};
                                final bool isPaid = data['isPaid'] == true;

                                if (!context.mounted) return;

                                if (isPaid) {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const ScannerScreen()));
                                } else {
                                  _showPaywallDialog(context);
                                }
                              }),
                          Positioned(
                            top: -5,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber[700],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Text(
                                "PAID",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Text(lang.managementHub,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: brandColor)),
                const SizedBox(height: 16),
                _buildActionButton(context, lang.manageProjects,
                    Icons.inventory_2_rounded, brandColor, () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const project_screen()));
                    }),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final lang = Provider.of<AppLanguage>(context);
          final isSmall = MediaQuery.of(context).size.width < 380;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(
                  color: brandColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8))],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddProjectDialog(context),
              backgroundColor: brandColor,
              elevation: 0,
              icon: Icon(Icons.add_rounded,
                  color: Colors.white, size: isSmall ? 22 : 28),
              label: Text(lang.addProject,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 14 : 18,
                      letterSpacing: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  // Updated to support full width when used inside a Stack
  Widget _buildToolButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,   // <-- yeh add karo
        padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isSmall ? 26 : 32),
            SizedBox(height: isSmall ? 6 : 8),
            FittedBox(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isSmall ? 12 : 15)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildModernCard(BuildContext context, String title, String value,
  //     IconData icon, List<Color> gradient, VoidCallback onTap)
  // {
  //   final sw = MediaQuery.of(context).size.width;
  //   final isSmall = sw < 380;
  //   final cardHeight = isSmall ? 110.0 : sw < 420 ? 125.0 : 140.0;
  //   final iconSize = isSmall ? 20.0 : 24.0;
  //   final valueSize = isSmall ? 20.0 : 26.0;
  //   final titleSize = isSmall ? 10.0 : 12.0;
  //   final iconPad = isSmall ? 6.0 : 8.0;
  //
  //   return GestureDetector(
  //       onTap: onTap,
  //       child: Container(
  //         height: cardHeight,
  //         padding: EdgeInsets.symmetric(
  //             horizontal: isSmall ? 10 : 14,
  //             vertical: 12),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //               colors: gradient,
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight),
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: [BoxShadow(
  //               color: gradient[1].withOpacity(0.3),
  //               blurRadius: 10,
  //               offset: const Offset(0, 5))],
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Container(
  //                   padding: EdgeInsets.all(iconPad),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white.withOpacity(0.2),
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: Icon(icon, color: Colors.white, size: iconSize),
  //                 ),
  //                 SizedBox(width: isSmall ? 6 : 8),
  //                 Flexible(
  //                   child: FittedBox(
  //                     fit: BoxFit.scaleDown,
  //                     child: Text(value,
  //                         style: TextStyle(
  //                             color: Colors.white,
  //                             fontSize: valueSize,
  //                             fontWeight: FontWeight.w900)),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: isSmall ? 6 : 8),
  //             FittedBox(
  //               fit: BoxFit.scaleDown,
  //               child: Text(title,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                       color: Colors.white.withOpacity(0.9),
  //                       fontSize: titleSize,
  //                       fontWeight: FontWeight.w600,
  //                       letterSpacing: 0.3)),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //
  // }
  Widget _buildModernCard(BuildContext context, String title, String value,
      IconData icon, List<Color> gradient, VoidCallback onTap) {
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 380;
    final cardHeight = isSmall ? 110.0 : sw < 420 ? 125.0 : 140.0;
    final iconSize = isSmall ? 20.0 : 24.0;
    final valueSize = isSmall ? 20.0 : 26.0;
    final titleSize = isSmall ? 10.0 : 12.0;
    final iconPad = isSmall ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 10 : 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: gradient[1].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: iconSize),
                ),
                SizedBox(width: isSmall ? 6 : 8),
                // Expanded hatao — FittedBox direct rakho
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: valueSize,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 6 : 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16, vertical: isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isSmall ? 18 : 22),
            ),
            SizedBox(width: isSmall ? 8 : 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 13 : 16,
                      color: brandColor),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: isSmall ? 12 : 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}