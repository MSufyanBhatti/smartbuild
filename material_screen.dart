import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class material_screen extends StatefulWidget {
  final String projectId;
  const material_screen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<material_screen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<material_screen> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference get _projectRef =>
      FirebaseFirestore.instance
          .collection("users")
          .doc(_uid)
          .collection("projects")
          .doc(widget.projectId);

  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  Future<void> _updateFinancialProgress(double newExpense) async {
    var projectSnap = await _projectRef.get();
    var data = projectSnap.data() as Map<String, dynamic>;

    double budget = (data['budget'] ?? 0).toDouble();
    double currentSpent = (data['spent'] ?? 0).toDouble();
    double newTotalSpent = currentSpent + newExpense;

    double newProgress = 0.0;
    if (budget > 0) {
      newProgress = newTotalSpent / budget;
      if (newProgress > 1.0) newProgress = 1.0;
    }

    await _projectRef.update({
      "spent": newTotalSpent,
      "progress": newProgress,
    });
  }

  void addMaterial() async {

    final lang = Provider.of<AppLanguage>(context, listen: false);

    if (nameController.text.isEmpty ||
        quantityController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.fillAllFields)));
      return;
    }

    double quantity = double.tryParse(quantityController.text) ?? 0;
    double unitPrice = double.tryParse(priceController.text) ?? 0;
    double totalExpense = quantity * unitPrice;

    if (totalExpense <= 0) return;

    var projectSnap = await _projectRef.get();
    var projectData = projectSnap.data() as Map<String, dynamic>;
    double budget = (projectData['budget'] ?? 0).toDouble();
    double currentSpent = (projectData['spent'] ?? 0).toDouble();

    if ((currentSpent + totalExpense) > budget && budget > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang.budgetExceeded),
          backgroundColor: Colors.red));
      return;
    }

    await _projectRef.collection("materials").add({
      "name": nameController.text,
      "quantity": quantity,
      "unitPrice": unitPrice,
      "totalPrice": totalExpense,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await _updateFinancialProgress(totalExpense);

    nameController.clear();
    quantityController.clear();
    priceController.clear();
    FocusScope.of(context).unfocus();
  }
  Future<void> deleteMaterial(String docId, double totalPrice) async {
    await _projectRef.collection("materials").doc(docId).delete();

    // spent wapas kam karo
    var projectSnap = await _projectRef.get();
    var data = projectSnap.data() as Map<String, dynamic>;

    double currentSpent = (data['spent'] ?? 0).toDouble();
    double budget = (data['budget'] ?? 0).toDouble();

    double newSpent = currentSpent - totalPrice;
    if (newSpent < 0) newSpent = 0;

    double newProgress = 0;
    if (budget > 0) {
      newProgress = newSpent / budget;
    }

    await _projectRef.update({
      "spent": newSpent,
      "progress": newProgress,
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(lang.materialExpenses,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          return Column(
            children: [
              // input fields
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isLandscape
                      ? constraints.maxHeight *
                      0.45 // landscape mein kam height
                      : constraints.maxHeight * 0.35, // portrait mein
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: lang.itemName,
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: lang.qty,
                                  border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: lang.price,
                                  border: const OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: addMaterial,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                            backgroundColor: Colors.blue[900]),
                        child: Text(lang.addExpenseManually,
                            style: const TextStyle(color: Colors.white)),
                      ),
                      const Divider(height: 24, thickness: 1.5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(lang.recentMaterialLogs,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── List View ──
              // ── List View ──
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _projectRef
                      .collection("materials")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var materials = snapshot.data!.docs;

                    if (materials.isEmpty)
                      return Center(child: Text(lang.noRecords));

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        var item = materials[index].data() as Map<
                            String,
                            dynamic>;
                        double total = (item['totalPrice'] ?? 0).toDouble();
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item['name'] ?? "Unknown"),
                            subtitle: Text(
                                "${lang
                                    .qty}: ${item['quantity']} × Rs. ${item['unitPrice']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Rs. ${total.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    deleteMaterial(materials[index].id, total);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ); // <-- closes Column
        }, // <-- closes LayoutBuilder builder
      ), // <-- closes LayoutBuilder
    );
  }
}