import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';
import 'worker_detail_screen.dart';

class RoleDetailScreen extends StatefulWidget {
  final String projectId;
  final String role;

  const RoleDetailScreen({
    super.key,
    required this.projectId,
    required this.role,
  });

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  late DocumentReference _projectRef;

  @override
  void initState() {
    super.initState();
    _projectRef = FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("projects")
        .doc(widget.projectId);
  }

  final nameController = TextEditingController();
  final wageController = TextEditingController();
  final phoneController = TextEditingController();

  void addWorker() async {
    if (nameController.text.isEmpty || wageController.text.isEmpty) return;
    await _projectRef.collection("labor").add({
      "name": nameController.text,
      "role": widget.role,
      "phone": phoneController.text,
      "dailyWage": double.tryParse(wageController.text) ?? 0,
      "totalEarned": 0,
      "presentToday": false,
    });
    nameController.clear();
    wageController.clear();
    phoneController.clear();
    Navigator.pop(context);
  }

  void deleteWorker(String id) async {
    await _projectRef.collection("labor").doc(id).delete();
  }

  void _callNumber(String phone) async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri.parse("tel:$cleanPhone");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.failedToOpenDialer)),
      );
    }
  }

  void toggleAttendance(String id, bool current) async {
    await _projectRef
        .collection("labor")
        .doc(id)
        .update({"presentToday": !current});
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _projectRef
            .collection("labor")
            .where("role", isEqualTo: widget.role)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var workers = snapshot.data!.docs;

          if (workers.isEmpty) {
            return Center(child: Text(lang.noWorkersAdded));
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              var data = workers[index].data() as Map<String, dynamic>;
              bool present = data['presentToday'] ?? false;
              String phone = data['phone'] ?? "";

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerDetailScreen(
                        projectId: widget.projectId,
                        workerId: workers[index].id,
                        workerData: data,
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(data['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rs. ${data['dailyWage']}"),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _callNumber(phone),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: present ? Colors.green : Colors.grey,
                          ),
                          onPressed: () =>
                              toggleAttendance(workers[index].id, present),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteWorker(workers[index].id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}