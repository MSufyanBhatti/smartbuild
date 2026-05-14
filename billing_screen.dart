import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final Color brandColor = const Color(0xFF0D47A1);
  bool isYearly = false;
  String _selectedMethod = "easypaisa";
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _txnController = TextEditingController();
  bool _isSubmitting = false;

  // ════════════════════════════════════════
  // ✏️  YAHAN APNA DATA UPDATE KARO
  // ════════════════════════════════════════
  final String ownerName      = "UMAR HABIB";  // apna naam
  final String easypaisaNum   = "03007143763 ";       // EasyPaisa number
  final String jazzcashNum    = "03007143763 ";       // JazzCash number
  final String bankName       = " National Bank Of Pakistan";                // bank naam
  final String bankAccount    = "03334255554357";     // account number
  final String bankIban       = "PK20NBPA0333004255554357"; // IBAN
  final int    monthlyPrice   = 1;
  final int    yearlyPrice    = 8999;
  // ════════════════════════════════════════

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text("$label copy ho gaya!"),
      ]),
      backgroundColor: Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Color get _methodColor {
    if (_selectedMethod == "easypaisa") return const Color(0xFF6ABF4B);
    if (_selectedMethod == "jazzcash") return const Color(0xFFD50032);
    return const Color(0xFF0D47A1);
  }

  String get _methodNumber {
    if (_selectedMethod == "easypaisa") return easypaisaNum;
    if (_selectedMethod == "jazzcash") return jazzcashNum;
    return bankAccount;
  }

  Future<void> _submitRequest() async {
    if (_selectedMethod != "bank" && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Apna phone number darj karein"),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_txnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Transaction ID zarori hai"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("paymentRequests").add({
        "uid": uid,
        "phone": _phoneController.text,
        "txnId": _txnController.text,
        "method": _selectedMethod,
        "plan": isYearly ? "yearly" : "monthly",
        "amount": isYearly ? yearlyPrice : monthlyPrice,
        "status": "pending",
        "submittedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Request Bhej Di!"),
          ]),
          content: const Text(
              "Aapki payment request admin ko mil gayi.\n\n"
                  "24 ghante mein account activate ho jayega."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: brandColor),
              child: const Text("Theek Hai",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int price = isYearly ? yearlyPrice : monthlyPrice;
    final int saving = (monthlyPrice * 12) - yearlyPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Premium Subscription",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: brandColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.amber, size: 40),
                  ),
                  const SizedBox(height: 14),
                  const Text("AI Map Scanner",
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text("For Blueprint analysis activate this plan" ,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Plan Toggle ──
            const Text("Choose Plan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isYearly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isYearly ? brandColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("Monthly",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: !isYearly ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isYearly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isYearly ? brandColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Yearly",
                                style: TextStyle(
                                    color: isYearly ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            if (!isYearly) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text("SAVE",
                                    style: TextStyle(color: Colors.white,
                                        fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Price Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: brandColor.withOpacity(0.2)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Rs. $price",
                          style: TextStyle(fontSize: 36,
                              fontWeight: FontWeight.w900, color: brandColor)),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(isYearly ? "/ year" : "/ month",
                            style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ],
                  ),
                  if (isYearly) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text("🎉 Rs. $saving bachao!",
                          style: TextStyle(color: Colors.green[700],
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  _featureTile(Icons.architecture_rounded, "Blueprint AI Analysis"),
                  _featureTile(Icons.calculate_rounded, "Material Auto Estimation"),

                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Payment Method ──
            const Text("Payment Method",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1))),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _methodCard(
                  method: "easypaisa",
                  label: "EasyPaisa",
                  shortLabel: "EP",
                  color: const Color(0xFF6ABF4B),
                )),
                const SizedBox(width: 10),
                Expanded(child: _methodCard(
                  method: "jazzcash",
                  label: "JazzCash",
                  shortLabel: "JC",
                  color: const Color(0xFFD50032),
                )),
                const SizedBox(width: 10),
                Expanded(child: _methodCard(
                  method: "bank",
                  label: "Bank",
                  shortLabel: "BK",
                  color: const Color(0xFF0D47A1),
                )),
              ],
            ),

            const SizedBox(height: 16),

            // ── Payment Details Box ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _methodColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _methodColor.withOpacity(0.3)),
              ),
              child: _selectedMethod == "bank"
                  ? _bankDetails()
                  : _mobileDetails(),
            ),

            const SizedBox(height: 16),

            // ── Phone Field (EasyPaisa/JazzCash only) ──
            if (_selectedMethod != "bank")
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Enter ${_selectedMethod == 'easypaisa' ? 'EasyPaisa' : 'JazzCash'} Number",
                    hintText: "03XX-XXXXXXX",
                    prefixIcon: Icon(Icons.phone_android_rounded, color: _methodColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _methodColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),


            TextField(
              controller: _txnController,
              decoration: InputDecoration(
                labelText: _selectedMethod == "bank"
                    ? "Transaction Reference Number"
                    : "Transaction ID",
                hintText: " After Payment ",
                prefixIcon: Icon(Icons.receipt_long_rounded, color: _methodColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _methodColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // ── Submit Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRequest,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                    _isSubmitting
                        ? "Bhej raha hai..."
                        : "Rs. $price —  Send Request ",
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _methodColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // // ── Instructions ──
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: Colors.orange[50],
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: Colors.orange[200]!),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(children: [
            //         Icon(Icons.info_outline_rounded,
            //             color: Colors.orange[700], size: 20),
            //         const SizedBox(width: 8),
            //         Text("Payment ke baad kya karein?",
            //             style: TextStyle(fontWeight: FontWeight.bold,
            //                 color: Colors.orange[800], fontSize: 14)),
            //       ]),
            //       const SizedBox(height: 10),
            //       _step("1", "Rs. $price transfer karein upar diye account mein"),
            //       _step("2", "Transaction ID note karein"),
            //       _step("3", "Neeche form fill karke Request Bhejein"),
            //       _step("4", "24 ghante mein account activate ho jayega"),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Mobile payment details (EP/JC) ──
  Widget _mobileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedMethod == "easypaisa" ? "EasyPaisa Account" : "JazzCash Account",
          style: const TextStyle(fontSize: 12, color: Colors.grey,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedMethod == "easypaisa" ? easypaisaNum : jazzcashNum,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                  color: _methodColor),
            ),
            GestureDetector(
              onTap: () => _copy(
                _selectedMethod == "easypaisa"
                    ? easypaisaNum.replaceAll("-", "")
                    : jazzcashNum.replaceAll("-", ""),
                "Number",
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.copy_rounded, size: 14, color: _methodColor),
                  const SizedBox(width: 4),
                  Text("Copy", style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.bold, color: _methodColor)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text("Account Name: $ownerName",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ── Bank details ──
  Widget _bankDetails() {
    return Column(
      children: [
        _bankRow(Icons.account_balance_rounded, "Bank", bankName, false),
        const Divider(height: 16),
        _bankRow(Icons.person_rounded, "Account Name", ownerName, true),
        const Divider(height: 16),
        _bankRow(Icons.credit_card_rounded, "Account Number", bankAccount, true),
        const Divider(height: 16),
        _bankRow(Icons.tag_rounded, "IBAN", bankIban, true),
      ],
    );
  }

  Widget _bankRow(IconData icon, String label, String value, bool copyable) {
    return Row(
      children: [
        Icon(icon, color: brandColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
            ],
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () => _copy(value, label),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.copy_rounded, color: brandColor, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _methodCard({required String method, required String label,
    required String shortLabel, required Color color}) {
    final bool selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? color : Colors.grey[300]!, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(shortLabel,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 13))),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12,
                color: selected ? color : Colors.black87)),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _featureTile(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: brandColor, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
      ]),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
              color: Colors.orange[700], shape: BoxShape.circle),
          child: Center(child: Text(number,
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.black87))),
      ]),
    );
  }
}