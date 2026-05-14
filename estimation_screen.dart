import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

// ─────────────────────────────────────────────
//  Labor Mode Enum
//  3 options jo user select kare ga
// ─────────────────────────────────────────────
enum LaborMode {
  withoutPlaster,   // Gray structure WITHOUT plaster
  withPlaster,      // Gray structure WITH plaster
  fullFinishing,    // Gray + Plaster + Tiles + Paint etc.
}

class EstimationScreen extends StatefulWidget {
  final String? projectId;
  const EstimationScreen({super.key, this.projectId});

  @override
  State<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _unitValueController = TextEditingController();
  final TextEditingController _lengthController    = TextEditingController();
  final TextEditingController _widthController     = TextEditingController();

  // ── Rates ────────────────────────────────────────────────────────────
  double cementRate    = 1350;
  double steelRate     = 285;
  double brickRate     = 17;
  double sandRate      = 55;
  double crushRate     = 120;
  double laborRateSqft = 350;  // base gray labor (without plaster)

  // ── Labor Mode ────────────────────────────────────────────────────────
  LaborMode _laborMode = LaborMode.withoutPlaster;

  // ── UI State ──────────────────────────────────────────────────────────
  String _projectType  = "Residential (Home)";
  String _selectedUnit = "Marla";
  String _quality      = "A Class (Standard)";
  String _floorCount   = "1";
  double _marlaSize    = 225;
  bool   _includeFinishing = false;
  double _minBudget    = 0;
  double _maxBudget    = 0;
  bool   _budgetSet    = false;

  final List<String> _projectTypes = [
    "Residential (Home)",
    "Commercial (Shop)",
    "Plaza / Building",
  ];
  final List<String> _units = ["Marla", "Kanal", "Sq. Ft", "Dimensions"];
  final List<String> _qualities = [
    "A+ Class (Premium)",
    "A Class (Standard)",
    "B Class (Economy)",
  ];
  final List<String> _floors = ["1","2","3","4","5","6","7","8","9","10"];
  final Map<double, String> _marlaSizes = {
    225.0:  "225 sqft (LDA)",
    250.0:  "250 sqft (Bahria)",
    272.25: "272 sqft (Old Standard)",
  };

  // ── Results ───────────────────────────────────────────────────────────
  double _totalArea     = 0;
  double _totalBudget   = 0;
  double _grayCost      = 0;
  double _finishingCost = 0;
  double _costPerSqft   = 0;

  Map<String, double> _matQty        = {};
  Map<String, double> _matCost       = {};
  List<Map<String, dynamic>> _floorBreakdown = [];
  Map<String, dynamic> _housePlan    = {};
  List<String> _planImages           = [];

  final Color brandColor = const Color(0xFF0D47A1);

  // ════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _unitValueController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════
  //  RATE PERSISTENCE
  // ════════════════════════════════════════════════════════════════════
  Future<void> _loadRates() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      cementRate    = p.getDouble('cementRate') ?? 1350;
      steelRate     = p.getDouble('steelRate')  ?? 285;
      brickRate     = p.getDouble('brickRate')  ?? 17;
      sandRate      = p.getDouble('sandRate')   ?? 55;
      crushRate     = p.getDouble('crushRate')  ?? 120;
      laborRateSqft = p.getDouble('laborRate')  ?? 350;
      _laborMode    = LaborMode.values[p.getInt('laborMode') ?? 0];
    });
    _calculate();
  }

  Future<void> _saveRates() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('cementRate', cementRate);
    await p.setDouble('steelRate',  steelRate);
    await p.setDouble('brickRate',  brickRate);
    await p.setDouble('sandRate',   sandRate);
    await p.setDouble('crushRate',  crushRate);
    await p.setDouble('laborRate',  laborRateSqft);
    await p.setInt('laborMode',     _laborMode.index);
    _calculate();
  }

  // ════════════════════════════════════════════════════════════════════
  //  LABOR MODE — Effective rates
  //
  //  withoutPlaster  → labor = Rs 280–380/sqft (sirf gray bغير plaster)
  //                    Plaster = ~Rs 55–75/sqft extra (added separately)
  //
  //  withPlaster     → labor = Rs 350–450/sqft (gray + plaster included)
  //                    User ka rate sab cover karta hai except tiles/paint
  //
  //  fullFinishing   → labor = Rs 500–700/sqft (gray + plaster + tiles + paint)
  //                    Sab kuch andar — finishing alag charge nahi
  // ════════════════════════════════════════════════════════════════════

  // Plaster extra cost per sqft (added when mode = withoutPlaster)
  double get _plasterCostPerSqft {
    // Plaster: ~1.5 bags cement + labor per 100 sqft = ~Rs 55–75/sqft
    return _quality.contains("A+") ? 75 : _quality.contains("B") ? 45 : 60;
  }

  // Finishing multiplier on gray cost
  double get _finishingMultiplier {
    // fullFinishing mode: finishing already in rate → 0
    if (_laborMode == LaborMode.fullFinishing) return 0;
    return _quality.contains("A+") ? 0.70 : _quality.contains("B") ? 0.40 : 0.55;
  }

  // ════════════════════════════════════════════════════════════════════
  //  CALCULATE
  // ════════════════════════════════════════════════════════════════════
  void _calculate() {
    double inputVal = double.tryParse(_unitValueController.text) ?? 0;
    double plotArea = 0;

    switch (_selectedUnit) {
      case "Dimensions":
        plotArea = (double.tryParse(_lengthController.text) ?? 0) *
            (double.tryParse(_widthController.text) ?? 0);
        break;
      case "Marla":
        plotArea = inputVal * _marlaSize;
        break;
      case "Kanal":
        plotArea = inputVal * 20 * _marlaSize;
        break;
      default:
        plotArea = inputVal;
    }

    if (plotArea <= 0) {
      setState(() {
        _totalBudget = 0; _housePlan = {}; _planImages = [];
        _floorBreakdown = []; _matQty = {}; _matCost = {};
      });
      return;
    }

    int floors   = int.tryParse(_floorCount) ?? 1;
    double qMult = _quality.contains("A+") ? 1.12 : _quality.contains("B") ? 0.90 : 1.0;

    if (_projectType == "Residential (Home)") {
      _calcResidential(plotArea, floors, qMult);
    } else if (_projectType == "Commercial (Shop)") {
      _calcCommercial(plotArea, floors, qMult);
    } else {
      _calcPlaza(plotArea, floors, qMult);
    }

    final plan = _getHousePlan(_selectedUnit, inputVal);
    setState(() {
      _housePlan  = plan;
      _planImages = List<String>.from(plan["images"] ?? []);
    });
  }

  // ════════════════════════════════════════════════════════════════════
  //  RESIDENTIAL
  // ════════════════════════════════════════════════════════════════════
  void _calcResidential(double plotArea, int floors, double qMult) {
    double gf = plotArea * _resCoverageGF(plotArea);
    double ff = gf * 0.85;
    double sf = gf * 0.40;
    List<double> floorAreas = [gf];
    if (floors >= 2) floorAreas.add(ff);
    if (floors >= 3) floorAreas.add(sf);
    for (int i = 3; i < floors; i++) floorAreas.add(gf * 0.40);
    double totalArea = floorAreas.fold(0.0, (a, b) => a + b);

    double bricks = totalArea * 18.0 * qMult;

    // Cement — without plaster mode mein kam (no plaster cement)
    double cementPerSqft;
    if (_laborMode == LaborMode.withoutPlaster) {
      cementPerSqft = floors == 1 ? 0.35 : floors == 2 ? 0.38 : 0.42;
    } else {
      cementPerSqft = floors == 1 ? 0.40 : floors == 2 ? 0.44 : 0.48;
    }
    double cement = totalArea * cementPerSqft * qMult;

    double steel = totalArea * (floors == 1 ? 2.8 : floors == 2 ? 3.2 : floors == 3 ? 3.8 : 4.2) * qMult;
    double sand  = totalArea * 1.2;
    double crush = totalArea * 0.70;

    _applyCalculation(
      totalArea: totalArea, bricks: bricks, cement: cement,
      steel: steel, sand: sand, crush: crush,
      miscPct: 0.07, foundationPremium: 0,
      floorAreas: floorAreas,
      getFloorName: (i) {
        final lang = Provider.of<AppLanguage>(context, listen: false);
        return i == 0 ? lang.groundFloor : i == 1 ? lang.firstFloor
            : i == 2 ? lang.secondFloor : "${lang.floorNum} ${i + 1}";
      },
    );
  }
  double _resCoverageGF(double plotArea) {
    if (plotArea < 1125) return 0.85;
    if (plotArea < 2250) return 0.80;
    if (plotArea < 4500) return 0.75;
    return 0.65;
  }

  // ════════════════════════════════════════════════════════════════════
  //  COMMERCIAL
  // ════════════════════════════════════════════════════════════════════
  void _calcCommercial(double plotArea, int floors, double qMult) {
    double floorArea = plotArea * 0.95;
    double totalArea = floorArea * floors;

    double bricks = totalArea * 14.0 * qMult;
    double cement = totalArea * (0.42 + (floors > 3 ? 0.03 : 0.0)) * qMult;
    double steel  = totalArea * (floors <= 2 ? 4.2 : floors <= 4 ? 4.8 : 5.5) * qMult;
    double sand   = totalArea * 1.1;
    double crush  = totalArea * 0.90;

    List<double> fAreas = List.generate(floors, (_) => floorArea);
    _applyCalculation(
      totalArea: totalArea, bricks: bricks, cement: cement,
      steel: steel, sand: sand, crush: crush,
      miscPct: 0.10, foundationPremium: 0,
      floorAreas: fAreas,
      getFloorName: (i) {
        final lang = Provider.of<AppLanguage>(context, listen: false);
        return i == 0 ? lang.groundFloor : "${lang.floorNum} ${i + 1}";
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  PLAZA
  // ════════════════════════════════════════════════════════════════════
  void _calcPlaza(double plotArea, int floors, double qMult) {
    double covFactor = floors <= 4 ? 0.80 : 0.75;
    double floorArea = plotArea * covFactor;
    double totalArea = floorArea * floors;

    double bricks = totalArea * (floors <= 4 ? 12.0 : 10.0) * qMult;

    // Cement — without plaster mode mein kam
    double cementPerSqft;
    if (_laborMode == LaborMode.withoutPlaster) {
      cementPerSqft = floors <= 2 ? 0.42 : floors <= 4 ? 0.46 : floors <= 6 ? 0.50 : 0.56;
    } else {
      cementPerSqft = floors <= 2 ? 0.48 : floors <= 4 ? 0.52 : floors <= 6 ? 0.56 : 0.62;
    }
    double cement = totalArea * cementPerSqft * qMult;

    double steel = totalArea * (floors <= 2 ? 5.5 : floors <= 4 ? 6.5 : floors <= 6 ? 7.5 : 8.5) * qMult;
    double sand  = totalArea * 1.1;
    double crush = totalArea * 1.1;

    double rawMat = (bricks * brickRate) + (cement * cementRate) +
        (steel * steelRate) + (sand * sandRate) + (crush * crushRate);
    double fp = floors <= 3 ? rawMat * 0.06 : floors <= 6 ? rawMat * 0.10 : rawMat * 0.15;

    List<double> fAreas = List.generate(floors, (_) => floorArea);
    _applyCalculation(
      totalArea: totalArea, bricks: bricks, cement: cement,
      steel: steel, sand: sand, crush: crush,
      miscPct: 0.12, foundationPremium: fp,
      floorAreas: fAreas,
      getFloorName: (i) {
        final lang = Provider.of<AppLanguage>(context, listen: false);
        return i == 0 ? lang.groundFloor : "${lang.floorNum} ${i + 1}";
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  CORE APPLY — labor mode logic here
  // ════════════════════════════════════════════════════════════════════
  void _applyCalculation({
    required double totalArea,
    required double bricks, required double cement,
    required double steel, required double sand, required double crush,
    required double miscPct,
    required double foundationPremium,
    required List<double> floorAreas,
    required String Function(int) getFloorName,
  }) {
    double rawMatCost = (bricks * brickRate) + (cement * cementRate) +
        (steel * steelRate) + (sand * sandRate) + (crush * crushRate);

    double laborCost = totalArea * laborRateSqft;
    double miscCost  = rawMatCost * miscPct;

    // withoutPlaster: plaster is NOT in the user's labor rate, so add it separately
    double plasterCost = 0;
    // withPlaster: user rate already includes plaster — no extra
    // fullFinishing: user rate includes everything — no extra

    double grayCost = rawMatCost + miscCost + laborCost + foundationPremium;

    // Finishing cost — only applicable for withoutPlaster and withPlaster modes
    // fullFinishing: already inside labor rate
    double finishingCost = 0;
    if (_laborMode != LaborMode.fullFinishing) {
      finishingCost = grayCost * _finishingMultiplier;
    }

    double totalBudget = grayCost + (_includeFinishing ? finishingCost : 0);

    // Build floor breakdown
    final lang = Provider.of<AppLanguage>(context, listen: false);
    List<Map<String, dynamic>> breakdown = [];
    if (foundationPremium > 0) {
      breakdown.add({"floor": lang.foundationFootings, "area": floorAreas[0], "cost": foundationPremium});
    }
    for (int i = 0; i < floorAreas.length; i++) {
      double share = floorAreas[i] / totalArea;
      breakdown.add({"floor": getFloorName(i), "area": floorAreas[i], "cost": share * grayCost});
    }

    // Build matCost map
    Map<String, double> matCostMap = {
      "Bricks": bricks * brickRate,
      "Cement": cement * cementRate,
      "Steel":  steel  * steelRate,
      "Sand":   sand   * sandRate,
      "Crush":  crush  * crushRate,
      if (foundationPremium > 0) "Foundation Premium": foundationPremium,
      "Misc / Contingency": miscCost,
      // "Plaster (Extra)" — BILKUL NAHI
      "Labor": laborCost,
    };

    setState(() {
      _totalArea     = totalArea;
      _grayCost      = grayCost;
      _finishingCost = finishingCost;
      _totalBudget   = totalBudget;
      _costPerSqft   = totalArea > 0 ? totalBudget / totalArea : 0;
      _matQty = {
        "Bricks": bricks, "Cement": cement, "Steel": steel,
        "Sand": sand, "Crush": crush, "Labor": laborCost,
      };
      _matCost        = matCostMap;
      _floorBreakdown = breakdown;
    });
  }

  // ════════════════════════════════════════════════════════════════════
  //  HOUSE PLAN
  // ════════════════════════════════════════════════════════════════════
  Map<String, dynamic> _getHousePlan(String unit, double val) {
    if (_projectType != "Residential (Home)") return {};
    if (unit == "Marla") {
      if (val == 5)  return {"title": "5 Marla Plan Options", "images": ["assets/images/img.png", "assets/images/img_1.png"]};
      if (val == 10) return {"title": "10 Marla Plan",        "images": ["assets/images/5marla.jpg"]};
    } else if (unit == "Kanal" && val == 1) {
      return {"title": "1 Kanal Plan", "images": ["assets/images/1 kanal.png"]};
    }
    return {};
  }

  void _showFullImage(String path) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => FullImageScreen(imagePath: path)));

  // ════════════════════════════════════════════════════════════════════
  //  RATE DIALOG — with labor mode selector
  // ════════════════════════════════════════════════════════════════════
  void _showRateDialog() {
    final cCtrl  = TextEditingController(text: cementRate.toStringAsFixed(0));
    final sCtrl  = TextEditingController(text: steelRate.toStringAsFixed(0));
    final bCtrl  = TextEditingController(text: brickRate.toStringAsFixed(0));
    final saCtrl = TextEditingController(text: sandRate.toStringAsFixed(0));
    final crCtrl = TextEditingController(text: crushRate.toStringAsFixed(0));
    final lCtrl  = TextEditingController(text: laborRateSqft.toStringAsFixed(0));
    LaborMode selectedMode = _laborMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final lang = Provider.of<AppLanguage>(ctx, listen: false);

          String modeDesc, modeRange;
          Color modeColor;
          IconData modeIcon;
          switch (selectedMode) {
            case LaborMode.withoutPlaster:
              modeDesc  = "Gray structure labor only (without plaster). Plaster cost will be added separately.";
              modeRange = "Typical: Rs 280–380/sqft";
              modeColor = Colors.orange.shade700;
              modeIcon  = Icons.construction_rounded;
              break;
            case LaborMode.withPlaster:
              modeDesc  = "Gray structure + plaster both included. Tiles and paint are separate.";
              modeRange = "Typical: Rs 350–450/sqft";
              modeColor = Colors.blue.shade700;
              modeIcon  = Icons.format_paint_rounded;
              break;
            case LaborMode.fullFinishing:
              modeDesc  = "Full finishing included — gray, plaster, tiles, paint, woodwork. No separate charge.";
              modeRange = "Typical: Rs 500–700/sqft";
              modeColor = Colors.green.shade700;
              modeIcon  = Icons.home_work_rounded;
              break;
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Header ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    color: brandColor,
                    child: Row(children: [
                      const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text("Material & Labor Rates",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      ),
                    ]),
                  ),

                  // ── Scrollable body ──────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [

                        // Market rates hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.info_outline_rounded, size: 15, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(child: Text(lang.marketRatesDetail,
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade800, height: 1.5))),
                          ]),
                        ),
                        const SizedBox(height: 18),

                        // ── Material rates section ─────────────────────
                        _sectionLabel2("Material Rates", Icons.inventory_2_outlined),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(child: _compactRateField(bCtrl,  "Brick", "per No",  Icons.grid_view_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _compactRateField(cCtrl,  "Cement", "per Bag", Icons.architecture_rounded)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _compactRateField(sCtrl,  "Steel",  "per Kg",  Icons.reorder_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _compactRateField(saCtrl, "Sand",   "per CFT", Icons.grain_rounded)),
                        ]),
                        const SizedBox(height: 10),
                        _compactRateField(crCtrl, "Bajri / Crush", "per CFT", Icons.landscape_rounded),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // ── Labor mode section ─────────────────────────
                        _sectionLabel2("Labor Rate Type", Icons.engineering_rounded),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("What does your labor rate cover?",
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ),
                        const SizedBox(height: 12),

                        _laborModeCard(
                          mode: LaborMode.withoutPlaster, selected: selectedMode,
                          icon: Icons.construction_rounded, color: Colors.orange.shade700,
                          label: "Gray — Without Plaster",
                          sublabel: "Gray structure labor only. Plaster cost added separately.",
                          onTap: () => setLocal(() => selectedMode = LaborMode.withoutPlaster),
                        ),
                        const SizedBox(height: 8),
                        _laborModeCard(
                          mode: LaborMode.withPlaster, selected: selectedMode,
                          icon: Icons.format_paint_rounded, color: Colors.blue.shade700,
                          label: "Gray + Plaster",
                          sublabel: "Gray + plaster both included. Tiles/paint not included.",
                          onTap: () => setLocal(() => selectedMode = LaborMode.withPlaster),
                        ),
                        const SizedBox(height: 8),
                        _laborModeCard(
                          mode: LaborMode.fullFinishing, selected: selectedMode,
                          icon: Icons.home_work_rounded, color: Colors.green.shade700,
                          label: "Gray + Plaster + Tiles + Paint",
                          sublabel: "Everything included — no separate finishing charge.",
                          onTap: () => setLocal(() => selectedMode = LaborMode.fullFinishing),
                        ),
                        const SizedBox(height: 16),

                        // ── Labor rate field ───────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(modeIcon, size: 16, color: modeColor),
                              const SizedBox(width: 6),
                              Text("Labor Rate (per Sqft)",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            ]),
                            const SizedBox(height: 10),
                            TextField(
                              controller: lCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                prefixText: "Rs  ",
                                suffixText: "/ sqft",
                                suffixStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: modeColor.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: modeColor.withOpacity(0.2)),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 13, color: modeColor),
                                const SizedBox(width: 6),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(modeDesc,  style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w500, height: 1.4)),
                                  const SizedBox(height: 2),
                                  Text(modeRange, style: TextStyle(fontSize: 10, color: modeColor.withOpacity(0.7), fontStyle: FontStyle.italic)),
                                ])),
                              ]),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  // ── Footer buttons ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(lang.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              cementRate    = double.tryParse(cCtrl.text)  ?? cementRate;
                              steelRate     = double.tryParse(sCtrl.text)  ?? steelRate;
                              brickRate     = double.tryParse(bCtrl.text)  ?? brickRate;
                              sandRate      = double.tryParse(saCtrl.text) ?? sandRate;
                              crushRate     = double.tryParse(crCtrl.text) ?? crushRate;
                              laborRateSqft = double.tryParse(lCtrl.text)  ?? laborRateSqft;
                              _laborMode    = selectedMode;
                            });
                            _saveRates();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lang.ratesUpdated)));
                          },
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(lang.update, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Compact 2-column rate field
  Widget _compactRateField(TextEditingController ctrl, String label, String suffix, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          prefixText: "Rs ",
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    ]);
  }

// Section label helper
  Widget _sectionLabel2(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: brandColor),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandColor)),
    ]);
  }

  // Labor mode card widget
  Widget _laborModeCard({
    required LaborMode mode, required LaborMode selected,
    required IconData icon, required Color color,
    required String label, required String sublabel,
    required VoidCallback onTap,
  }) {
    bool isSelected = selected == mode;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.8 : 1),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: isSelected ? color : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? color : Colors.black87)),
            Text(sublabel, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ])),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.smartEstimator, style: TextStyle(fontWeight: FontWeight.w900, color: brandColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: brandColor),
        actions: const [ ],
          // // Settings icon — tap karo to update rates
          // IconButton(
          //   onPressed: _showRateDialog,
          //   icon: Icon(Icons.settings_suggest_rounded, color: brandColor),
          //   tooltip: "Update Rates",
          // ),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: brandColor,
          indicatorWeight: 3,
          labelColor: brandColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "Details"), Tab(text: "Estimation")],
        ),
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: [_buildInputTab(lang), _buildAnalysisTab(lang)],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  INPUT TAB
  // ════════════════════════════════════════════════════════════════════
  Widget _buildInputTab(AppLanguage lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── RATE HINT BANNER ─────────────────────────────────────────
          GestureDetector(
            onTap: _showRateDialog,
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandColor.withOpacity(0.08), brandColor.withOpacity(0.03)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brandColor.withOpacity(0.18)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: brandColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.settings_suggest_rounded, color: brandColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Update Material & Labor Rates",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandColor)),
                  const SizedBox(height: 2),
                  Text("Tap here to set brick, cement, steel & labor rates before estimating",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: brandColor.withOpacity(0.5)),
              ]),
            ),
          ),

          // ── Labor mode status chip ────────────────────────────────────
          // _buildLaborModeChip(),
          // const SizedBox(height: 16),

          _buildHeader(lang.propertyDetails, Icons.home_work_rounded),
          const SizedBox(height: 15),
          _buildCard(child: Column(children: [
            _buildDropdown(lang.usageType, _projectType, _projectTypes,
                    (v) => setState(() { _projectType = v!; _calculate(); })),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildDropdown(lang.selectUnit, _selectedUnit, _units,
                      (v) => setState(() { _selectedUnit = v!; _calculate(); }))),
              if (_selectedUnit == "Marla") ...[
                const SizedBox(width: 10),
                Expanded(child: _buildDropdown(
                  lang.size, _marlaSize.toString(),
                  _marlaSizes.keys.map((e) => e.toString()).toList(),
                      (v) => setState(() { _marlaSize = double.parse(v!); _calculate(); }),
                  itemsLabels: _marlaSizes.values.toList(),
                )),
              ],
            ]),
            const SizedBox(height: 20),
            _selectedUnit == "Dimensions"
                ? Row(children: [
              Expanded(child: _buildTextField(_lengthController, lang.lengthFt)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_widthController, lang.widthFt)),
            ])
                : _buildTextField(_unitValueController, lang.enterValue),
          ])),

          const SizedBox(height: 25),
          _buildHeader(lang.qualityAndFloors, Icons.layers_rounded),
          const SizedBox(height: 15),
          _buildCard(child: Column(children: [
            _buildDropdown(lang.constructionQuality, _quality, _qualities,
                    (v) => setState(() { _quality = v!; _calculate(); })),
            const SizedBox(height: 20),
            if (_selectedUnit != "Dimensions") ...[
              _buildDropdown(lang.numberOfFloors, _floorCount, _floors,
                      (v) => setState(() { _floorCount = v!; _calculate(); })),
              const SizedBox(height: 14),
            ],
            _buildProjectTypeInfo(lang),
          ])),

          const SizedBox(height: 20),
          // Include finishing switch (hidden if fullFinishing mode — already included)
          if (_laborMode != LaborMode.fullFinishing)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: brandColor.withOpacity(0.1)),
              ),
              child: SwitchListTile(
                title: Text(lang.includeFinishing, style: TextStyle(fontWeight: FontWeight.bold, color: brandColor)),
                subtitle: Text(lang.finishingSubtitle),
                value: _includeFinishing,
                activeColor: brandColor,
                onChanged: (v) => setState(() { _includeFinishing = v; _calculate(); }),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  "Finishing already included in your labor rate (Gray + Plaster + Tiles + Paint)",
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                )),
              ]),
            ),

          const SizedBox(height: 30),
          if (_totalBudget > 0)
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(lang.viewCompleteAnalysis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
    );
  }

  // Labor mode current status chip
  Widget _buildLaborModeChip() {
    String label;
    Color color;
    IconData icon;
    switch (_laborMode) {
      case LaborMode.withoutPlaster:
        label = "Labor Mode: Gray Only (Without Plaster)";
        color = Colors.orange.shade700;
        icon  = Icons.construction_rounded;
        break;
      case LaborMode.withPlaster:
        label = "Labor Mode: Gray + Plaster";
        color = Colors.blue.shade700;
        icon  = Icons.format_paint_rounded;
        break;
      case LaborMode.fullFinishing:
        label = "Labor Mode: Full (Gray + Plaster + Tiles + Paint)";
        color = Colors.green.shade700;
        icon  = Icons.home_work_rounded;
        break;
    }
    return GestureDetector(
      onTap: _showRateDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 12, color: color.withOpacity(0.6)),
        ]),
      ),
    );
  }

  Widget _buildProjectTypeInfo(AppLanguage lang) {
    String info; IconData icon;
    if (_projectType == "Residential (Home)") {
      info = "Brick-mortar load bearing + RCC slab. Coverage: 85% GF, 78% FF, 40% SF.";
      icon = Icons.home_outlined;
    } else if (_projectType == "Commercial (Shop)") {
      info = "RCC frame (columns+beams) + brick infill. 95% coverage per floor.";
      icon = Icons.store_outlined;
    } else {
      info = "Full RCC frame + shear walls. Raft/deep foundation. 75-80% coverage.";
      icon = Icons.apartment_outlined;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandColor.withOpacity(0.1)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: brandColor),
        const SizedBox(width: 10),
        Expanded(child: Text(info, style: TextStyle(fontSize: 11, color: Colors.grey[700]))),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  ANALYSIS TAB
  // ════════════════════════════════════════════════════════════════════
  Widget _buildAnalysisTab(AppLanguage lang) {
    if (_totalBudget <= 0) return Center(child: Text(lang.enterDetailsFirst));
    final isSmall = MediaQuery.of(context).size.width < 380;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _buildSummaryCard(lang),
        const SizedBox(height: 25),
        if (_includeFinishing && _laborMode != LaborMode.fullFinishing) ...[
          _buildCostSplitCard(lang),
          const SizedBox(height: 25),
        ],
        _buildHeader(lang.materialQuantities, Icons.inventory_2_rounded),
        const SizedBox(height: 15),
        _buildMaterialGrid(lang, isSmall),
        const SizedBox(height: 25),
        _buildHeader(lang.costBreakdown, Icons.receipt_long_rounded),
        const SizedBox(height: 15),
        _buildCostBreakdownTable(lang, isSmall),
        const SizedBox(height: 25),
        if (_floorBreakdown.isNotEmpty && _selectedUnit != "Dimensions") ...[
          _buildHeader(
            _projectType == "Plaza / Building" ? lang.floorWiseCost : lang.floorWiseArea,
            Icons.layers_rounded,
          ),
          const SizedBox(height: 15),
          _buildFloorBreakdownTable(lang, isSmall),
          const SizedBox(height: 25),
        ],
        if (_housePlan.isNotEmpty) ...[
          _buildHeader(lang.suggestedHousePlans, Icons.map_rounded),
          const SizedBox(height: 15),
          _buildHousePlanSection(),
          const SizedBox(height: 25),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildSummaryCard(AppLanguage lang) {
    final isSmall = MediaQuery.of(context).size.width < 380;

    // Summary label based on labor mode
    String summaryLabel;
    if (_laborMode == LaborMode.fullFinishing) {
      summaryLabel = "TOTAL COST (GRAY + PLASTER + TILES + PAINT)";
    } else if (_includeFinishing) {
      summaryLabel = lang.totalBudgetGrayFinishing;
    } else if (_laborMode == LaborMode.withPlaster) {
      summaryLabel = "TOTAL GRAY + PLASTER COST";
    } else {
      summaryLabel = lang.totalGrayCost;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 18 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [brandColor, const Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: brandColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Text(summaryLabel, style: TextStyle(color: Colors.white70, fontSize: isSmall ? 8 : 10, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FittedBox(child: Text("PKR ${_formatNum(_totalBudget)}", style: TextStyle(color: Colors.white, fontSize: isSmall ? 28 : 36, fontWeight: FontWeight.w900))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statMini(lang.coveredArea, "${_totalArea.toInt()} ft²", isSmall),
          _statMini(lang.costPerSqft, "Rs ${_costPerSqft.toStringAsFixed(0)}", isSmall),
          _statMini(lang.grayCost, "PKR ${_formatNum(_grayCost)}", isSmall),
        ]),
      ]),
    );
  }

  Widget _buildCostSplitCard(AppLanguage lang) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lang.costBreakdown, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 13 : 15)),
        const SizedBox(height: 16),
        _costSplitRow(lang.grayStructure, _grayCost, Colors.blue.shade700, isSmall: isSmall),
        const SizedBox(height: 10),
        _costSplitRow(lang.finishingWork, _finishingCost, Colors.green.shade700, isSmall: isSmall),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        _costSplitRow(lang.total, _totalBudget, brandColor, bold: true, isSmall: isSmall),
      ]),
    );
  }

  Widget _costSplitRow(String label, double amount, Color color, {bool bold = false, bool isSmall = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(fontSize: bold ? (isSmall ? 13:15):(isSmall?11:13), fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: bold ? Colors.black : Colors.grey[700]), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        FittedBox(child: Text("PKR ${_formatNum(amount)}", style: TextStyle(fontSize: bold ? (isSmall?13:15):(isSmall?11:13), fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color))),
      ]);

  Widget _buildMaterialGrid(AppLanguage lang, bool isSmall) {
    final items = _matQty.entries.toList();
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: isSmall ? 1.0 : 0.9, mainAxisSpacing: isSmall?10:15, crossAxisSpacing: isSmall?10:15),
      itemCount: items.length,
      itemBuilder: (c, i) {
        String key = items[i].key; double value = items[i].value;
        String? img; String unit = "";
        if (key.contains("Bricks"))  { img = "assets/images/bimg.jpg";   unit = "Nos"; }
        else if (key.contains("Cement")) { img = "assets/images/cnimg.jpg";  unit = "Bags"; }
        else if (key.contains("Steel"))  { img = "assets/images/simg.jpg";   unit = "Kg"; }
        else if (key.contains("Sand"))   { img = "assets/images/snnimg.jpg"; unit = "CFT"; }
        else if (key.contains("Crush"))  { img = "assets/images/ccimg.jpg";  unit = "CFT"; }
        else { img = "assets/images/llimg.png"; unit = "PKR"; }
        return Container(
          padding: EdgeInsets.all(isSmall?8:12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0,6))], border: Border.all(color: Colors.grey.withOpacity(0.08))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: isSmall?28:35, backgroundColor: Colors.grey[50],
                child: ClipOval(child: Image.asset(img!, width: isSmall?56:70, height: isSmall?56:70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image_not_supported, color: Colors.grey, size: isSmall?24:30)))),
            SizedBox(height: isSmall?8:12),
            FittedBox(child: Text(key == "Labor" ? _formatNum(value) : value.toStringAsFixed(0), style: TextStyle(fontSize: isSmall?14:18, fontWeight: FontWeight.w900, color: brandColor))),
            Text("${_translateMatKey(key, lang)} ($unit)", style: TextStyle(fontSize: isSmall?9:10, color: Colors.grey[700], fontWeight: FontWeight.w700), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }

  Widget _buildCostBreakdownTable(AppLanguage lang, bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(children: [
        Row(children: [
          Expanded(flex:3, child: Text(lang.item,      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
          Expanded(flex:2, child: Text(lang.amountPKR, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
          Expanded(child: Text("%", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
        ]),
        const Divider(height: 12),
        ..._matCost.entries.map((e) {
          double pct = _grayCost > 0 ? (e.value / _grayCost * 100) : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(flex:3, child: Text(_translateMatKey(e.key, lang), style: TextStyle(fontSize: isSmall?11:13), overflow: TextOverflow.ellipsis)),
              Expanded(flex:2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(_formatNum(e.value), style: TextStyle(fontSize: isSmall?11:13, fontWeight: FontWeight.w600)))),
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text("${pct.toStringAsFixed(1)}%", style: TextStyle(fontSize: isSmall?10:12, color: Colors.grey[500])))),
            ]),
          );
        }),
        const Divider(height: 20),
        Row(children: [
          Expanded(flex:3, child: Text(lang.grayTotal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?12:14))),
          Expanded(flex:3, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text("PKR ${_formatNum(_grayCost)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?12:14, color: brandColor)))),
        ]),
      ]),
    );
  }

  Widget _buildFloorBreakdownTable(AppLanguage lang, bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(children: [
        Row(children: [
          Expanded(flex:3, child: Text(lang.floor,   style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
          Expanded(flex:2, child: Text(lang.areaFt,  textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
          Expanded(flex:2, child: Text(lang.costPKR, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?10:12, color: Colors.grey[600]))),
        ]),
        const Divider(height: 16),
        ..._floorBreakdown.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(flex:3, child: Text(row["floor"], style: TextStyle(fontSize: isSmall?11:13), overflow: TextOverflow.ellipsis)),
            Expanded(flex:2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text((row["area"] as double).toStringAsFixed(0), style: TextStyle(fontSize: isSmall?11:13)))),
            Expanded(flex:2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(_formatNum(row["cost"] as double), style: TextStyle(fontSize: isSmall?11:13, fontWeight: FontWeight.w600, color: brandColor)))),
          ]),
        )),
        const Divider(height: 16),
        Row(children: [
          Expanded(flex:3, child: Text(lang.total, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?12:14))),
          Expanded(flex:2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(_totalArea.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?12:14)))),
          Expanded(flex:2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(_formatNum(_grayCost), style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall?12:14, color: brandColor)))),
        ]),
      ]),
    );
  }

  Widget _buildHousePlanSection() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
    child: Column(children: [
      Text(_housePlan["title"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandColor)),
      const SizedBox(height: 15),
      SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _planImages.length,
          itemBuilder: (c, i) => Container(
            width: 300, margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(borderRadius: BorderRadius.circular(15),
                child: GestureDetector(onTap: () => _showFullImage(_planImages[i]),
                    child: Hero(tag: _planImages[i], child: Image.asset(_planImages[i], fit: BoxFit.cover)))),
          ),

        ),
      ),
    ]),
  );

  // ── Keep existing _showBudgetRangeDialog, _getBudgetWhatCanBuild,
  //    _buildWhatCanBuildCard etc. from original file unchanged ──

  void _showBudgetRangeDialog() {
    final minController = TextEditingController();
    final maxController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final lang = Provider.of<AppLanguage>(dialogContext, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_balance_wallet_rounded, color: brandColor, size: 36),
            const SizedBox(height: 8),
            Text(lang.setBudgetRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(lang.enterMinMax, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
          ]),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: minController, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.minimumBudget, prefixIcon: const Icon(Icons.arrow_downward_rounded, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(controller: maxController, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.maximumBudget, prefixIcon: const Icon(Icons.arrow_upward_rounded, color: Colors.red), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(lang.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandColor),
              onPressed: () {
                double min = double.tryParse(minController.text) ?? 0;
                double max = double.tryParse(maxController.text) ?? 0;
                if (min <= 0 || max <= 0) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(lang.pleaseEnterValidAmounts))); return; }
                if (min >= max) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(lang.maxGreaterThanMin))); return; }
                setState(() { _minBudget = min; _maxBudget = max; _budgetSet = true; });
                Navigator.pop(dialogContext);
                _tabController.animateTo(1);
              },
              child: Text(lang.setAndViewAnalysis, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────
  String _translateMatKey(String key, AppLanguage lang) {
    if (key.contains("Bricks"))     return lang.matBricks;
    if (key.contains("Cement"))     return lang.matCement;
    if (key.contains("Steel"))      return lang.matSteel;
    if (key.contains("Sand"))       return lang.matSand;
    if (key.contains("Crush"))      return lang.matCrush;
    if (key.contains("Labor"))      return lang.matLabor;
    if (key.contains("Misc"))       return lang.matMisc;
    if (key.contains("Foundation")) return lang.matFoundation;
    if (key.contains("Plaster"))    return "Plaster";
    return key;
  }

  String _formatNum(double v) {
    if (v >= 10000000) return "${(v / 10000000).toStringAsFixed(2)} Cr";
    if (v >= 100000)   return "${(v / 100000).toStringAsFixed(2)} Lac";
    return v.toStringAsFixed(0);
  }

  Widget _statMini(String l, String v, [bool isSmall = false]) => Column(children: [
    Text(l, style: TextStyle(color: Colors.white60, fontSize: isSmall?7:9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    const SizedBox(height: 4),
    FittedBox(child: Text(v, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: isSmall?11:14))),
  ]);

  Widget _buildRateField(TextEditingController c, String l, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l, prefixIcon: Icon(icon, size: 20), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
  );

  Widget _buildTextField(TextEditingController c, String l) => TextField(
    controller: c, keyboardType: TextInputType.number, onChanged: (_) => _calculate(),
    decoration: InputDecoration(labelText: l, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
  );

  Widget _buildDropdown(String l, String v, List<String> items, Function(String?) onChanged, {List<String>? itemsLabels}) =>
      DropdownButtonFormField<String>(
        value: v, isExpanded: true,
        items: List.generate(items.length, (idx) => DropdownMenuItem(value: items[idx], child: Text(itemsLabels != null ? itemsLabels[idx] : items[idx], style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))),
        onChanged: onChanged, decoration: InputDecoration(labelText: l),
      );

  Widget _buildHeader(String t, IconData i) => Row(children: [
    Icon(i, color: brandColor, size: 22), const SizedBox(width: 10),
    Text(t, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: brandColor)),
  ]);

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))],
        border: Border.all(color: Colors.grey.withOpacity(0.05))),
    child: child,
  );
}

class FullImageScreen extends StatelessWidget {
  final String imagePath;
  const FullImageScreen({super.key, required this.imagePath});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
    body: Center(child: InteractiveViewer(child: Hero(tag: imagePath, child: Image.asset(imagePath)))),
  );
}