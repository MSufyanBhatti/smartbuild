import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_detail_screen.dart';
import 'role_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class project_screen extends StatefulWidget {
  const project_screen({super.key});

  @override
  State<project_screen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<project_screen> {
  final Color brandColor = const Color(0xFF0D47A1);

  void deleteProject(String projectId, String projectName) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.deleteProject, style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
        content: Text("${lang.deleteConfirmPrefix} '$projectName'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.cancel)),
          ElevatedButton(
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("projects")
                  .doc(projectId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.projectRemoved)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _togglePin(String projectId, bool currentlyPinned) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("projects")
        .doc(projectId)
        .update({"pinned": !currentlyPinned});
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final width = MediaQuery.of(context).size.width;
    // Yeh add karo build method mein
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(lang.constructionHub, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(width > 600 ? 32 : 24),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.siteInventory,
                  style: TextStyle(
                    fontSize: isLandscape ? 25 : (width > 600 ? 34 : 28),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (!isLandscape) const SizedBox(height: 5),  // landscape mein gap hatao
                if (!isLandscape)

                Text(lang.siteSubtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: width > 600 ? 16 : 13,
                    )),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection("projects")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var projects = snapshot.data!.docs.toList();
                projects.sort((a, b) {
                  bool aPinned = (a.data() as Map<String, dynamic>)['pinned'] == true;
                  bool bPinned = (b.data() as Map<String, dynamic>)['pinned'] == true;
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;
                  return 0;
                });

                if (projects.isEmpty) {
                  return Center(child: Text(lang.noProjects));
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: width > 600 ? 40 : 16,
                    vertical: isLandscape ? 10 : 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    var project = projects[index];
                    var data = project.data() as Map<String, dynamic>;
                    double progress = (data['progress'] ?? 0.0).toDouble();
                    bool isCompleted = ((data['status'] ?? "") == "completed") || ((data['progress'] ?? 0.0).toDouble() >= 1.0);
                    bool isPinned = (data['pinned'] as bool?) ?? false;
                    String clientName = data['client'] ?? lang.noClient;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isPinned ? Colors.amber.withOpacity(0.4) : Colors.grey.withOpacity(0.08),
                          width: isPinned ? 1.5 : 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                projectId: project.id,
                                projectName: data['name'] ?? "Project",
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: EdgeInsets.all(width > 600 ? 24.0 : 18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isCompleted ? Colors.green[50] : const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isCompleted ? lang.completed : lang.activeSite,
                                      style: TextStyle(
                                        color: isCompleted ? Colors.green[700] : brandColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _togglePin(project.id, isPinned),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          margin: const EdgeInsets.only(right: 4),
                                          decoration: BoxDecoration(
                                            color: isPinned
                                                ? Colors.amber.withOpacity(0.15)
                                                : Colors.grey.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                            color: isPinned ? Colors.amber[700] : Colors.grey[400],
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => deleteProject(project.id, data['name'] ?? "this project"),
                                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red[200], size: 22),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  data['name'] ?? "Unnamed Project",
                                  style: TextStyle(
                                    fontSize: width > 600 ? 26 : 22,
                                    fontWeight: FontWeight.w900,
                                    color: brandColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_rounded,
                                      size: width > 600 ? 16 : 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      clientName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_rounded,
                                      size: width > 600 ? 16 : 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['phone'] ?? "No Phone",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(lang.constrProgress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                                  Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w900,
                                      color: brandColor,
                                      fontSize: width > 600 ? 18 : 15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: width > 600 ? 12 : 9,
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress > 1.0 ? 1.0 : progress,
                                    child: Container(
                                      height: width > 600 ? 12 : 9,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [brandColor, const Color(0xFF1976D2)]),
                                        borderRadius: BorderRadius.circular(10),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}