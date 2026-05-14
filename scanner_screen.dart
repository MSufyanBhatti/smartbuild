import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'app_language.dart';

class RoomDetail {
  final String name;
  final double length;
  final double width;
  final double area;
  final int floor;

  RoomDetail({
    required this.name,
    required this.length,
    required this.width,
    required this.area,
    this.floor = 1
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    final l = (json['length'] as num?)?.toDouble() ?? 0;
    final w = (json['width'] as num?)?.toDouble() ?? 0;
    return RoomDetail(
      name: json['name']?.toString() ?? 'Room',
      length: l,
      width: w,
      area: (json['area'] as num?)?.toDouble() ?? (l * w),
      floor: (json['floor'] as num?)?.toInt() ?? 1,
    );
  }
}

class BlueprintAnalysis {
  final List<RoomDetail> rooms;
  final double totalArea;
  final String notes;
  final int floors;

  BlueprintAnalysis({
    required this.rooms,
    required this.totalArea,
    required this.notes,
    this.floors = 1,
  });
}

class ScannerScreen extends StatefulWidget {
  final String? projectId;
  const ScannerScreen({super.key, this.projectId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  static const List<String> _apiKeys = [
    'AIzaSyCSLpBnNQekxqLX9CXQ16yKrQtiaxNv-_E',
    'AIzaSyARdZpWqcAeluqkoEQGyG19kHmAX0SHzZ0',
    'AIzaSyDRe50ND9O8TuIxlfaaNpHWHtCbkRa3Mho',

  ];

  static const String _model = 'gemini-2.5-flash';
  bool isProcessing = false;
  String processingStatus = '';
  final Color brandColor = const Color(0xFF0D47A1);

  double cementRate = 1250,
      steelRate = 265,
      brickRate = 15,
      sandRate = 45,
      crushRate = 110,
      laborRate = 450;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadRates();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      cementRate = p.getDouble('cementRate') ?? 1250;
      steelRate = p.getDouble('steelRate') ?? 265;
      brickRate = p.getDouble('brickRate') ?? 15;
      sandRate = p.getDouble('sandRate') ?? 45;
      crushRate = p.getDouble('crushRate') ?? 110;
      laborRate = p.getDouble('laborRate') ?? 450;
    });
  }

  Future<void> _pickBlueprint(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;

    setState(() {
      isProcessing = true;
      processingStatus = 'Uploading...';
    });

    try {
      final bytes = await File(file.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() => processingStatus = 'AI analyiz map');

      final analysis = await _analyzeBlueprint(base64Image);

      if (!mounted) return;

      if (analysis.rooms.isEmpty && analysis.totalArea <= 0) {
        _showError('No rooms found.');
        _manualEntry(0);
      } else {
        _showEstimate(analysis);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('quota_exceeded') || errorMsg.contains('429')) {
        _showError('Tamam keys ka quota khatam. Kal try karein.');
      } else if (errorMsg.contains('503')) {
        _showError('Server busy hai. Thodi der baad try karein.');
      } else if (errorMsg.contains('404')) {
        _showError('AI model error.');
      } else {
        _showError('Error: $errorMsg');
      }
    }finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<BlueprintAnalysis> _analyzeBlueprint(String base64Image) async {
    const prompt = '''
You are a blueprint analyzer. Look at this floor plan image carefully.

Find all rooms and their sizes. Return ONLY JSON:
{
  "floors": 2,
  "rooms": [
    {"name": "Bedroom 1", "length": 14, "width": 12, "area": 168, "floor": 0},
    {"name": "Living Room", "length": 20, "width": 15, "area": 300, "floor": 1},
    {"name": "Kitchen", "length": 10, "width": 8, "area": 80, "floor": 2}
  ],
  "total_area": 548,
  "notes": "Ground floor + 1st floor detected"
}

Instructions:
- floor 0 = Ground Floor
- floor 1 = 1st Floor  
- floor 2 = 2nd Floor
- floor 3 = 3rd Floor
- Read room names written in the blueprint
- Read dimensions written near each room (convert meters to feet if needed)
- If dimension not visible, estimate from proportions
- total_area = sum of all rooms
- Return valid JSON only, nothing else
''';

    // ✅ 3 attempts retry logic
    for (int attempt = 0; attempt < 3; attempt++) {

      for (int i = 0; i < _apiKeys.length; i++) {
        final key = _apiKeys[i];
        if (key.contains('YAHAN')) continue;

        try {
          setState(() => processingStatus =
          attempt > 0 ? 'Retry ${attempt}...' : 'AI analyze Map...');

          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key',
          );

          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}},
                    {'text': prompt},
                  ]
                }
              ],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 8192},
            }),
          ).timeout(const Duration(seconds: 30)); // ✅ timeout

          if (response.statusCode == 429) {
            debugPrint('Key ${i + 1} quota khatam, next...');
            continue;
          }

          // ✅ 503 pe 3 sec wait karo
          if (response.statusCode == 503) {
            debugPrint('Key ${i + 1} server busy, 3 sec wait...');
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = (data['candidates'][0]['content']['parts'][0]['text'] as String)
                .replaceAll('```json', '').replaceAll('`', '').trim();

            try {
              final start = text.indexOf('{');
              final end = text.lastIndexOf('}');
              final clean = text.substring(start, end + 1);
              final parsed = jsonDecode(clean) as Map<String, dynamic>;
              final roomsList = (parsed['rooms'] as List? ?? [])
                  .map((r) => RoomDetail.fromJson(r as Map<String, dynamic>))
                  .toList();
              double totalArea = (parsed['total_area'] as num?)?.toDouble() ?? 0;
              if (totalArea <= 0 && roomsList.isNotEmpty) {
                totalArea = roomsList.fold(0.0, (s, r) => s + r.area);
              }
              return BlueprintAnalysis(
                rooms: roomsList,
                totalArea: totalArea,
                notes: parsed['notes']?.toString() ?? '',
                floors: (parsed['floors'] as num?)?.toInt() ?? 1,
              );
            } catch (e) {
              return BlueprintAnalysis(rooms: [], totalArea: 0, notes: 'Parse failed', floors: 1);
            }
          }

          debugPrint('Key ${i + 1} error ${response.statusCode}, next...');
          continue;

        } catch (e) {
          debugPrint('Key ${i + 1} exception: $e');
          continue;
        }
      }

      // ✅ Attempt ke beech 2 sec wait
      if (attempt < 2) {
        debugPrint('Attempt ${attempt + 1} failed, 2 sec baad retry...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception('quota_exceeded');
  }

  void _showEstimate(BlueprintAnalysis analysis) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final totalArea = analysis.totalArea > 0
        ? analysis.totalArea
        : analysis.rooms.fold(0.0, (s, r) => s + r.area);

    final bricks = totalArea * 21;
    final cement = totalArea * 0.38;
    final steel = totalArea * 3.5;
    final sand = totalArea * 1.5;
    final crush = totalArea * 0.9;
    final labor = totalArea * laborRate;
    final total = (bricks * brickRate) +
        (cement * cementRate) +
        (steel * steelRate) +
        (sand * sandRate) +
        (crush * crushRate) +
        labor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: sc,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Analysis Results',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: brandColor)),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: brandColor),
                    onPressed: () {
                      Navigator.pop(context);
                      _manualEntry(totalArea);
                    },
                  )
                ],
              ),
              const Divider(),
              if (analysis.rooms.isNotEmpty) ...[
                _secHeader('Detected Rooms', Icons.meeting_room),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: analysis.rooms.length,
                  itemBuilder: (_, i) => _roomCard(analysis.rooms[i]),
                ),
              ],
              const SizedBox(height: 20),
              _matSummaryCard(lang.totalCoveredArea, '${totalArea.toInt()} Sqft',
                  brandColor, Colors.white),
              const SizedBox(height: 15),
              _secHeader(lang.materialBreakdown, Icons.list_alt),
              const SizedBox(height: 10),
              LayoutBuilder(builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _matCard(lang.bricks, '${bricks.toInt()}', 'Nos',
                        Icons.grid_4x4, Colors.brown),
                    _matCard(lang.cement, '${cement.toInt()}', 'Bags',
                        Icons.work, Colors.blueGrey),
                    _matCard(lang.steel, '${steel.toInt()}', 'Kg', Icons.reorder,
                        Colors.indigo),
                    _matCard(lang.sand, '${sand.toInt()}', 'CFT', Icons.grain,
                        Colors.orange),
                    _matCard(lang.crush, '${crush.toInt()}', 'CFT',
                        Icons.scatter_plot, Colors.grey),
                    _matCard(lang.laborCost, 'Rs ${labor.toInt()}', '',
                        Icons.engineering, Colors.teal),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: brandColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(lang.estimatedTotal,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Text('Rs ${total.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: brandColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (widget.projectId != null)
                ElevatedButton(
                  onPressed: () => _saveToFirebase(total, totalArea, analysis),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(lang.saveToProject,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matSummaryCard(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: text, fontWeight: FontWeight.w600, fontSize: 16)),
          Text(value,
              style: TextStyle(
                  color: text, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _matCard(
      String label, String val, String unit, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            child: Text('$val $unit',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: col)),
          ),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _secHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: brandColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _floorName(int floor) {
    switch (floor) {
      case 0: return 'Ground';
      case 1: return '1st Floor';
      case 2: return '2nd Floor';
      case 3: return '3rd Floor';
      default: return '${floor}th Floor';
    }
  }

  Color _floorColor(int floor) {
    switch (floor) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.green;
      case 3: return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _roomCard(RoomDetail room) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _floorColor(room.floor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _floorName(room.floor),
              style: TextStyle(
                fontSize: 9,
                color: _floorColor(room.floor),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(room.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('${room.length.toInt()}x${room.width.toInt()} ft',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('${room.area.toInt()} sqft',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: brandColor)),
        ],
      ),
    );
  }

  Future<void> _saveToFirebase(
      double amount, double area, BlueprintAnalysis analysis) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(widget.projectId)
        .update({
      'detected_estimate': amount,
      'detected_area': area,
      'last_scan': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  void _manualEntry(double current) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.correctArea),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: lang.sqftArea),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEstimate(BlueprintAnalysis(
                  rooms: [], totalArea: double.tryParse(ctrl.text) ?? 0, notes: ""));
            },
            child: Text(lang.recalculate),
          )
        ],
      ),
    );
  }

  void _showError(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(lang.aiMapScanner,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: brandColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isProcessing
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
                scale: _pulseAnim,
                child: Icon(Icons.auto_awesome,
                    size: 80, color: brandColor)),
            const SizedBox(height: 20),
            Text(processingStatus,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: brandColor)),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Text(lang.smartArchScanner,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload blueprint for instant estimation',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.1),
            Icon(Icons.architecture,
                size: 100, color: brandColor.withOpacity(0.1)),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  _btn(Icons.camera_alt, lang.scanFromCamera,
                          () => _pickBlueprint(ImageSource.camera)),
                  const SizedBox(height: 15),
                  _btn(Icons.photo_library, lang.uploadFromGallery,
                          () => _pickBlueprint(ImageSource.gallery),
                      outline: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData iconData, String label, VoidCallback onTap, {bool outline = false}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: outline
          ? OutlinedButton.icon(
        onPressed: onTap,
        // Yahan 'iconData' use karein
        icon: Icon(iconData, color: brandColor),
        label: Text(label,
            style: TextStyle(
                color: brandColor, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: brandColor),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
      )
          : ElevatedButton.icon(
        onPressed: onTap,
        // Yahan bhi 'iconData' use karein
        icon: Icon(iconData, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}