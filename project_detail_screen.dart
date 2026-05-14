import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'material_screen.dart';
import 'labor_screen.dart';
import 'task_screen.dart';
import 'daily_report_screen.dart';
import 'services/pdf_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isLoading = false;
  bool _isGeneratingReport = false;
  final Color brandColor = const Color(0xFF0D2A6E);
  final List<File> _completionImages = [];

  double _parseSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<Map<String, dynamic>> _fetchFullProjectData(
      String uid, Map<String, dynamic> projectData) async {
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("projects")
          .doc(widget.projectId)
          .collection("materials")
          .get(),
      FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("projects")
          .doc(widget.projectId)
          .collection("labor")
          .get(),
    ]).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception("Connection timeout"),
    );

    return {
      ...projectData,
      'materialsData': results[0].docs.map((d) => d.data()).toList(),
      'laborData': results[1].docs.map((d) => d.data()).toList(),
    };
  }

  Future<void> _pickCompletionImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _completionImages.add(File(pickedFile.path)));
    }
  }

  void _markProjectComplete(Map<String, dynamic> projectData) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang.projectFinalization,
            style: TextStyle(color: brandColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.addCompletionPhotos),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._completionImages.map(
                          (img) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(img,
                                width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setDialogState(
                                      () => _completionImages.remove(img)),
                              child: const Icon(Icons.cancel,
                                  color: Colors.red, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _pickCompletionImage();
                        setDialogState(() {});
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo,
                            color: Color(0xFF0D2A6E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isGeneratingReport)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                          color: Color(0xFF0D2A6E)),
                      const SizedBox(height: 10),
                      Text(lang.generatingPdf,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  )
                else
                  Text(lang.readyToGenerate),
              ],
            ),
          ),
          actions: [
            if (!_isGeneratingReport)
              TextButton(
                onPressed: () async {
                  setDialogState(() => _isGeneratingReport = true);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) throw Exception("User not logged in");
                    final fullData =
                    await _fetchFullProjectData(user.uid, projectData);
                    bool success = await PdfService.generateProjectReport(
                      context: context,
                      projectId: widget.projectId,
                      projectName: widget.projectName,
                      projectData: fullData,
                      finalImages: _completionImages,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              success ? lang.reportSaved : lang.reportFailed),
                          backgroundColor: success ? null : Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted)
                      setDialogState(() => _isGeneratingReport = false);
                  }
                },
                child: Text(lang.generateReport,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ElevatedButton(
              onPressed: _isGeneratingReport
                  ? null
                  : () async {
                final uid =
                    FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("projects")
                    .doc(widget.projectId)
                    .update(
                    {"status": "completed", "progress": 1.0});
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child: Text(lang.finishClose,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 50,
    );
    if (pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      Uint8List fileBytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(fileBytes);
      String dataUri = "data:image/jpeg;base64,$base64String";
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("projects")
          .doc(widget.projectId)
          .collection('reports')
          .add({
        'image': dataUri,
        'timestamp': FieldValue.serverTimestamp(),
        'uploadedAt': DateTime.now().toString(),
      });
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    DailyReportScreen(projectId: widget.projectId)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${lang.uploadFailed}: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final hPad = isTablet ? size.width * 0.06 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF0D2A6E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection("projects")
                .doc(widget.projectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              var projectData =
              snapshot.data!.data() as Map<String, dynamic>;
              return IconButton(
                tooltip: lang.generateReport,
                icon: _isGeneratingReport
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white),
                onPressed: _isGeneratingReport
                    ? null
                    : () async {
                  setState(() => _isGeneratingReport = true);
                  try {
                    final user =
                        FirebaseAuth.instance.currentUser;
                    if (user == null)
                      throw Exception("User not logged in");
                    final fullData = await _fetchFullProjectData(
                        user.uid, projectData);

                    // await PdfService.generateProjectReport(
                    //   projectId: widget.projectId,
                    //   projectName: widget.projectName,
                    //   projectData: fullData,
                    //   finalImages: _completionImages,
                    // );
                    bool success = await PdfService.generateProjectReport(
                      context: context,  // ← ye add karo
                      projectId: widget.projectId,
                      projectName: widget.projectName,
                      projectData: fullData,
                      finalImages: _completionImages,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? lang.reportSaved
                              : lang.reportFailed),
                          backgroundColor:
                          success ? null : Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted)
                      setState(() => _isGeneratingReport = false);
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("projects")
            .doc(widget.projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                CircularProgressIndicator(color: Color(0xFF0D2A6E)));
          }

          var projectData =
          snapshot.data!.data() as Map<String, dynamic>;
          double budget = _parseSafe(projectData['budget']);
          double spent = _parseSafe(projectData['spent']);
          double progress = _parseSafe(projectData['progress']);
          double remaining = budget - spent;
          String clientName = projectData['client'] ?? lang.notAdded;
          double profit = _parseSafe(projectData['profit']);
          bool isFinished =
              (projectData['status'] ?? "") == "completed";

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFinished)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          const Color(0xFF2E7D32).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.projectDone,
                            style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                _sectionLabel(lang.clientInfo),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Color(0xFF0D2A6E), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang.primaryClient,
                                style: const TextStyle(
                                    color: Color(0xFF8898AA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(clientName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0D2A6E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if ((projectData['phone'] ?? "")
                                .toString()
                                .isNotEmpty)
                              GestureDetector(
                                onTap: () async {
                                  final Uri phoneUri = Uri(
                                      scheme: 'tel',
                                      path: projectData['phone']
                                          .toString());
                                  if (await canLaunchUrl(phoneUri))
                                    await launchUrl(phoneUri);
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_rounded,
                                        size: 13,
                                        color: Color(0xFF1565C0)),
                                    const SizedBox(width: 4),
                                    Text(
                                        projectData['phone'].toString(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1565C0),
                                            fontWeight:
                                            FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showUpdateDialog(
                            context,
                            budget,
                            clientName,
                            profit,
                            projectData['phone']?.toString() ?? ""),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8EDF8),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.edit_note_rounded,
                              color: Color(0xFF0D2A6E), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _sectionLabel(lang.workProgress),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0D2A6E), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color:
                          const Color(0xFF0D2A6E).withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang.overallComplete,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text("${(progress * 100).toInt()}%",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Stack(
                        children: [
                          Container(
                              height: 10,
                              decoration: BoxDecoration(
                                  color:
                                  Colors.white.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(10))),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius:
                                    BorderRadius.circular(10))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _sectionLabel(lang.financialStats),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isTablet ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.4 : 1.3,
                  children: [
                    GestureDetector(
                      onTap: () => _showUpdateDialog(
                          context,
                          budget,
                          clientName,
                          profit,
                          projectData['phone']?.toString() ?? ""),
                      child: _buildStatCard(
                          lang.totalBudget,
                          "Rs. ${budget.toStringAsFixed(0)}",
                          Icons.account_balance_rounded,
                          brandColor),
                    ),
                    _buildStatCard(
                        lang.totalSpent,
                        "Rs. ${spent.toStringAsFixed(0)}",
                        Icons.shopping_cart_rounded,
                        Colors.red[700]!),
                    _buildStatCard(
                        lang.remainingAmt,
                        "Rs. ${remaining.toStringAsFixed(0)}",
                        Icons.savings_rounded,
                        remaining >= 0
                            ? Colors.green[700]!
                            : Colors.redAccent),
                    GestureDetector(
                      onTap: () => _showUpdateDialog(
                          context,
                          budget,
                          clientName,
                          profit,
                          projectData['phone']?.toString() ?? ""),
                      child: _buildStatCard(
                          lang.profit,
                          "Rs. ${profit.toStringAsFixed(0)}",
                          Icons.trending_up_rounded,
                          Colors.orange[800]!),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _sectionLabel(lang.siteManagement),
                const SizedBox(height: 10),
                _buildActionTile(
                    context,
                    lang.dailyTasks,
                    Icons.assignment_turned_in_rounded,
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TaskScreen(
                                projectId: widget.projectId)))),
                _buildActionTile(
                    context,
                    lang.materialExp,
                    Icons.category_rounded,
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => material_screen(
                                projectId: widget.projectId)))),
                _buildActionTile(
                    context,
                    lang.laborAttend,
                    Icons.groups_rounded,
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LaborScreen(
                                projectId: widget.projectId)))),
                _buildActionTile(
                    context,
                    lang.dailyReports,
                    Icons.photo_library_rounded,
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DailyReportScreen(
                                projectId: widget.projectId)))),
                _buildActionTile(
                  context,
                  lang.uploadEntry,
                  Icons.add_a_photo_rounded,
                  _isLoading ? () {} : _uploadImage,
                  isImportant: true,
                  trailing: _isLoading
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0D2A6E)))
                      : null,
                ),

                const SizedBox(height: 20),

                if (!isFinished)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _markProjectComplete(projectData),
                      icon: const Icon(Icons.done_all_rounded,
                          color: Colors.white, size: 20),
                      label: Text(lang.finishSite,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: brandColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D2A6E))),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4))
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8898AA),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {bool isImportant = false, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isImportant
                ? const Color(0xFFE8EDF8)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isImportant
                      ? const Color(0xFF0D2A6E)
                      : const Color(0xFFE8EDF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isImportant
                        ? Colors.white
                        : const Color(0xFF0D2A6E),
                    size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isImportant
                            ? const Color(0xFF0D2A6E)
                            : const Color(0xFF2D3748))),
              ),
              trailing ??
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, double currentBudget,
      String currentClient, double currentProfit, String currentPhone) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final budgetController =
    TextEditingController(text: currentBudget.toStringAsFixed(0));
    final clientNameController = TextEditingController(
        text: currentClient == lang.notAdded ? "" : currentClient);
    final profitController =
    TextEditingController(text: currentProfit.toStringAsFixed(0));
    final phoneController =
    TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.configProject,
            style:
            TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientNameController,
                decoration: InputDecoration(
                    labelText: lang.clientName,
                    prefixIcon: const Icon(Icons.person_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: lang.phoneNumber,
                    prefixIcon: const Icon(Icons.phone_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: lang.budgetRs,
                    prefixIcon:
                    const Icon(Icons.monetization_on_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: profitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: lang.yourProfit,
                    prefixIcon:
                    const Icon(Icons.trending_up_rounded)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel)),
          ElevatedButton(
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("projects")
                  .doc(widget.projectId)
                  .update({
                "budget":
                double.tryParse(budgetController.text) ?? 0,
                "client": clientNameController.text,
                "profit":
                double.tryParse(profitController.text) ?? 0,
                "phone": phoneController.text,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2A6E)),
            child: Text(lang.saveChanges,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}