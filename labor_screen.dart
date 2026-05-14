import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class LaborScreen extends StatefulWidget {
  final String projectId;
  const LaborScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<LaborScreen> createState() => _LaborScreenState();
}

class _LaborScreenState extends State<LaborScreen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _projectRef => FirebaseFirestore.instance
      .collection("users")
      .doc(_uid)
      .collection("projects")
      .doc(widget.projectId);

  Map<String, Color> roleColorMap = {};
  int colorIndex = 0;

  final nameController = TextEditingController();
  final wageController = TextEditingController();
  final roleController = TextEditingController();
  final phoneController = TextEditingController();

  Color getRoleColor(String role) {
    List<Color> colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.indigo, Colors.red, Colors.yellow, Colors.pink,
      Colors.teal, Colors.brown, Colors.cyan, Colors.deepPurple,
    ];
    role = role.trim();
    if (roleColorMap.containsKey(role)) return roleColorMap[role]!;
    Color color = colors[colorIndex % colors.length];
    roleColorMap[role] = color;
    colorIndex++;
    return color;
  }

  Future<void> _updateFinancialProgress(double newWage) async {
    var projectSnap = await _projectRef.get();
    var data = projectSnap.data() as Map<String, dynamic>;
    double budget = (data['budget'] ?? 0).toDouble();
    double currentSpent = (data['spent'] ?? 0).toDouble();
    double newTotalSpent = currentSpent + newWage;
    double newProgress = 0.0;
    if (budget > 0) {
      newProgress = newTotalSpent / budget;
      if (newProgress > 1.0) newProgress = 1.0;
    }
    await _projectRef.update({"spent": newTotalSpent, "progress": newProgress});
  }

  void addWorker() async {
    if (nameController.text.isEmpty || wageController.text.isEmpty) return;
    String role = roleController.text.trim().isEmpty ? "Worker" : roleController.text.trim();
    await _projectRef.collection("labor").add({
      "name": nameController.text,
      "role": role,
      "phone": phoneController.text,
      "dailyWage": double.tryParse(wageController.text) ?? 0,
      "totalEarned": 0,
      "presentToday": false,
      "groupRole": role,
    });
    nameController.clear();
    wageController.clear();
    roleController.clear();
    phoneController.clear();
    Navigator.pop(context);
  }

  void deleteWorker(String laborId) async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    await _projectRef.collection("labor").doc(laborId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.workerDeleted)),
    );
  }

  void markAttendance(String laborId, double wage, bool currentStatus) async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    bool newStatus = !currentStatus;
    await _projectRef.collection("labor").doc(laborId).update({
      "presentToday": newStatus,
      "totalEarned": newStatus
          ? FieldValue.increment(wage)
          : FieldValue.increment(-wage),
    });
    await _updateFinancialProgress(newStatus ? wage : -wage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(newStatus ? lang.markedPresent : lang.markedAbsent)),
    );
  }

  Map<String, int> _getRoleCounts(List<QueryDocumentSnapshot> docs) {
    Map<String, int> counts = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      String role = (data['role'] ?? "Worker").toString().trim();
      counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.laborDashboard,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLaborDialog,
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: _projectRef.collection("labor").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            lang.noWorkersYet,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.tapToAddWorker,
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var roleCounts = _getRoleCounts(docs);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roleCounts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: width > 600 ? 1.2 : width < 350 ? 0.75 : 0.85,
                    ),
                    itemBuilder: (context, index) {
                      var entry = roleCounts.entries.toList()[index];
                      return _roleCard(entry.key, entry.value, lang);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(String role, int count, AppLanguage lang) {
    Color color = getRoleColor(role);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoleDetailScreen(projectId: widget.projectId, role: role),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.engineering, size: 32, color: Colors.white),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(role,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count ${lang.workersCount}",  // ✅ "5 Workers" ya "5 مزدور"
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLaborDialog() {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.addWorker,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NAME
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: lang.workerName,
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.nameRequired;
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return lang.onlyAlphabets;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // ROLE
                TextFormField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: lang.workerRole,
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.roleRequired;
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return lang.onlyAlphabets;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // PHONE
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: lang.workerPhone,
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.phoneRequired;
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return lang.onlyNumbers;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // WAGE
                TextFormField(
                  controller: wageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: lang.workerWage,
                    prefixIcon: const Icon(Icons.currency_rupee_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return lang.wageRequired;
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return lang.onlyNumbers;
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) addWorker();
            },
            child: Text(lang.save),
          ),
        ],
      ),
    );
  }
}