import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { english, urdu, roman }

class AppLanguage extends ChangeNotifier {
  AppLang _lang = AppLang.english;
  AppLang get lang => _lang;

  Future<void> loadLanguage() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('appLang') ?? 'english';
    _lang = saved == 'urdu'
        ? AppLang.urdu
        : saved == 'roman'
        ? AppLang.roman
        : AppLang.english;
    notifyListeners();
  }

  Future<void> setLanguage(AppLang newLang) async {
    _lang = newLang;
    final p = await SharedPreferences.getInstance();
    await p.setString('appLang', newLang.name);
    notifyListeners();
  }

  // ═══════════════════════════════════════
  //  STRINGS
  // ═══════════════════════════════════════

  String get welcomeBack => {
    AppLang.english: "Welcome back,",
    AppLang.urdu: "خوش آمدید،",
    AppLang.roman: "Khush Aamdeed,",
  }[_lang]!;

  String get totalProjects => {
    AppLang.english: "Total Projects",
    AppLang.urdu: "کل منصوبے",
    AppLang.roman: "Kul Projects",
  }[_lang]!;

  String get activeSites => {
    AppLang.english: "Active Sites",
    AppLang.urdu: "فعال سائٹس",
    AppLang.roman: "Active Sites",
  }[_lang]!;

  String get budgetUsed => {
    AppLang.english: "Budget Used",
    AppLang.urdu: "بجٹ استعمال",
    AppLang.roman: "Budget Istimaal",
  }[_lang]!;

  String get ourClients => {
    AppLang.english: "Our Clients",
    AppLang.urdu: "ہمارے کلائنٹس",
    AppLang.roman: "Hamare Clients",
  }[_lang]!;

  String get smartTools => {
    AppLang.english: "Smart Construction Tools",
    AppLang.urdu: "سمارٹ تعمیراتی اوزار",
    AppLang.roman: "Smart Tameerati Tools",
  }[_lang]!;

  String get aiEstimator => {
    AppLang.english: "AI Estimator",
    AppLang.urdu: "اے آئی تخمینہ",
    AppLang.roman: "AI Andaza",
  }[_lang]!;

  String get scanner => {
    AppLang.english: "Scanner",
    AppLang.urdu: "اسکینر",
    AppLang.roman: "Scanner",
  }[_lang]!;

  String get managementHub => {
    AppLang.english: "Management Hub",
    AppLang.urdu: "انتظامی مرکز",
    AppLang.roman: "Management Markaz",
  }[_lang]!;

  String get manageProjects => {
    AppLang.english: "Manage Projects Inventory",
    AppLang.urdu: "منصوبوں کا انتظام",
    AppLang.roman: "Projects ka Intezaam",
  }[_lang]!;

  String get addProject => {
    AppLang.english: "Add Project",
    AppLang.urdu: "منصوبہ شامل کریں",
    AppLang.roman: "Project Shamil Karein",
  }[_lang]!;

  String get newSiteEnrollment => {
    AppLang.english: "New Site Enrollment",
    AppLang.urdu: "نئی سائٹ اندراج",
    AppLang.roman: "Nai Site Enrollment",
  }[_lang]!;

  String get projectName => {
    AppLang.english: "Project Name",
    AppLang.urdu: "منصوبے کا نام",
    AppLang.roman: "Project ka Naam",
  }[_lang]!;

  String get clientName => {
    AppLang.english: "Client Name",
    AppLang.urdu: "کلائنٹ کا نام",
    AppLang.roman: "Client ka Naam",
  }[_lang]!;

  String get phoneNumber => {
    AppLang.english: "Phone Number",
    AppLang.urdu: "فون نمبر",
    AppLang.roman: "Phone Number",
  }[_lang]!;

  String get cancel => {
    AppLang.english: "Cancel",
    AppLang.urdu: "منسوخ",
    AppLang.roman: "Cancel",
  }[_lang]!;

  String get startProject => {
    AppLang.english: "Start Project",
    AppLang.urdu: "منصوبہ شروع کریں",
    AppLang.roman: "Project Shuru Karein",
  }[_lang]!;

  String get close => {
    AppLang.english: "Close",
    AppLang.urdu: "بند کریں",
    AppLang.roman: "Band Karein",
  }[_lang]!;

  String get criticalBudget => {
    AppLang.english: "Critical Budget",
    AppLang.urdu: "نازک بجٹ",
    AppLang.roman: "Nazuk Budget",
  }[_lang]!;

  String get budgetBreakdown => {
    AppLang.english: "Budget Breakdown",
    AppLang.urdu: "بجٹ تفصیل",
    AppLang.roman: "Budget Tafseel",
  }[_lang]!;

  String get clientPortfolio => {
    AppLang.english: "Client Portfolio",
    AppLang.urdu: "کلائنٹ پورٹ فولیو",
    AppLang.roman: "Client Portfolio",
  }[_lang]!;

  String get projectsOverview => {
    AppLang.english: "Projects Overview",
    AppLang.urdu: "منصوبوں کا جائزہ",
    AppLang.roman: "Projects ka Jaiza",
  }[_lang]!;

  String get ongoingSites => {
    AppLang.english: "Ongoing Sites",
    AppLang.urdu: "جاری سائٹس",
    AppLang.roman: "Jaari Sites",
  }[_lang]!;

  String get finishedProjects => {
    AppLang.english: "Finished Projects",
    AppLang.urdu: "مکمل منصوبے",
    AppLang.roman: "Mukammal Projects",
  }[_lang]!;

  String get selectLanguage => {
    AppLang.english: "Select Language",
    AppLang.urdu: "زبان منتخب کریں",
    AppLang.roman: "Zaban Muntakhib Karein",
  }[_lang]!;

  String get remaining => {
    AppLang.english: "Remaining",
    AppLang.urdu: "باقی",
    AppLang.roman: "Baqi",
  }[_lang]!;

  String get totalBudget => {
    AppLang.english: "Total Budget",
    AppLang.urdu: "کل بجٹ",
    AppLang.roman: "Kul Budget",
  }[_lang]!;

  String get totalSpent => {
    AppLang.english: "Total Spent",
    AppLang.urdu: "کل خرچ",
    AppLang.roman: "Kul Kharch",
  }[_lang]!;

  String get noProjects => {
    AppLang.english: "No projects available.",
    AppLang.urdu: "کوئی منصوبہ دستیاب نہیں۔",
    AppLang.roman: "Koi project available nahi.",
  }[_lang]!;

  String get noClientData => {
    AppLang.english: "No client data found.",
    AppLang.urdu: "کوئی کلائنٹ ڈیٹا نہیں ملا۔",
    AppLang.roman: "Koi client data nahi mila.",
  }[_lang]!;

  String get noActiveProjects => {
    AppLang.english: "No active projects.",
    AppLang.urdu: "کوئی فعال منصوبہ نہیں۔",
    AppLang.roman: "Koi active project nahi.",
  }[_lang]!;

  String get allSitesFunded => {
    AppLang.english: "All active sites have sufficient funds.",
    AppLang.urdu: "تمام فعال سائٹس کے پاس کافی فنڈز ہیں۔",
    AppLang.roman: "Tamam active sites ke paas kaafi funds hain.",
  }[_lang]!;

  String get progress => {
    AppLang.english: "Progress",
    AppLang.urdu: "پیشرفت",
    AppLang.roman: "Taraqi",
  }[_lang]!;

  String get completed => {
    AppLang.english: "completed",
    AppLang.urdu: "مکمل",
    AppLang.roman: "mukammal",
  }[_lang]!;

  String get used => {
    AppLang.english: "Used",
    AppLang.urdu: "استعمال",
    AppLang.roman: "Istimaal",
  }[_lang]!;

  String get site => {
    AppLang.english: "Site",
    AppLang.urdu: "سائٹ",
    AppLang.roman: "Site",
  }[_lang]!;
  String get activeSitesTitle => {
    AppLang.english: "Active Sites",
    AppLang.urdu: "فعال سائٹس",
    AppLang.roman: "Active Sites",
  }[_lang]!;
  // ═══════════════════════════════════════
  //  ESTIMATION SCREEN STRINGS
  // ═══════════════════════════════════════

  String get smartEstimator => {
    AppLang.english: "Smart Estimator Pro",
    AppLang.urdu: "سمارٹ تخمینہ پرو",
    AppLang.roman: "Smart Estimator Pro",
  }[_lang]!;

  String get configure => {
    AppLang.english: "Details",
    AppLang.urdu: "تفصیلات",
    AppLang.roman: "Details",
  }[_lang]!;

  String get analysis => {
    AppLang.english: "Estimation",
    AppLang.urdu: "تخمینہ",
    AppLang.roman: "Estimation",
  }[_lang]!;

  String get propertyDetails => {
    AppLang.english: "Property Details",
    AppLang.urdu: "جائیداد کی تفصیل",
    AppLang.roman: "Property Details",
  }[_lang]!;

  String get usageType => {
    AppLang.english: "Usage Type",
    AppLang.urdu: "استعمال کی قسم",
    AppLang.roman: "Istemal ki Qisam",
  }[_lang]!;

  String get selectUnit => {
    AppLang.english: "Select Unit",
    AppLang.urdu: "یونٹ منتخب کریں",
    AppLang.roman: "Unit Muntakhib Karein",
  }[_lang]!;

  String get size => {
    AppLang.english: "Size",
    AppLang.urdu: "سائز",
    AppLang.roman: "Size",
  }[_lang]!;

  String get enterValue => {
    AppLang.english: "Enter Value",
    AppLang.urdu: "قدر درج کریں",
    AppLang.roman: "Value Darj Karein",
  }[_lang]!;

  String get lengthFt => {
    AppLang.english: "Length (ft)",
    AppLang.urdu: "لمبائی (فٹ)",
    AppLang.roman: "Lambai (ft)",
  }[_lang]!;

  String get widthFt => {
    AppLang.english: "Width (ft)",
    AppLang.urdu: "چوڑائی (فٹ)",
    AppLang.roman: "Churai (ft)",
  }[_lang]!;

  String get qualityAndFloors => {
    AppLang.english: "Quality & Floors",
    AppLang.urdu: "معیار اور منزلیں",
    AppLang.roman: "Quality aur Floors",
  }[_lang]!;

  String get constructionQuality => {
    AppLang.english: "Construction Quality",
    AppLang.urdu: "تعمیراتی معیار",
    AppLang.roman: "Tameerati Quality",
  }[_lang]!;

  String get numberOfFloors => {
    AppLang.english: "Number of Floors",
    AppLang.urdu: "منزلوں کی تعداد",
    AppLang.roman: "Floors ki Tadaad",
  }[_lang]!;

  String get includeFinishing => {
    AppLang.english: "Include Finishing Costs",
    AppLang.urdu: "فنشنگ اخراجات شامل کریں",
    AppLang.roman: "Finishing Costs Shamil Karein",
  }[_lang]!;

  String get finishingSubtitle => {
    AppLang.english: "Tiles, Paint, Woodwork, Sanitary Fittings",
    AppLang.urdu: "ٹائلز، پینٹ، لکڑی کا کام، سینیٹری",
    AppLang.roman: "Tiles, Paint, Lakri ka Kaam, Sanitary",
  }[_lang]!;

  String get viewCompleteAnalysis => {
    AppLang.english: "VIEW COMPLETE ANALYSIS",
    AppLang.urdu: "مکمل تجزیہ دیکھیں",
    AppLang.roman: "COMPLETE ANALYSIS DEKHEIN",
  }[_lang]!;

  String get updateMaterialRates => {
    AppLang.english: "Update Material Rates",
    AppLang.urdu: "مواد کی قیمتیں اپ ڈیٹ کریں",
    AppLang.roman: "Material Rates Update Karein",
  }[_lang]!;

  String get marketRates => {
    AppLang.english: "2026 Market Rates (Lahore/Gujranwala)",
    AppLang.urdu: "2026 مارکیٹ ریٹس (لاہور/گوجرانوالہ)",
    AppLang.roman: "2026 Market Rates (Lahore/Gujranwala)",
  }[_lang]!;

  String get marketRatesDetail => {
    AppLang.english: "Brick: Rs 15-20 | Cement: Rs 1,250-1,450\nSteel: Rs 260-300 | Sand: Rs 45-65\nCrush: Rs 100-130 | Labor: Rs 280-450/sqft",
    AppLang.urdu: "اینٹ: 15-20 | سیمنٹ: 1,250-1,450\nسٹیل: 260-300 | ریت: 45-65\nبجری: 100-130 | مزدوری: 280-450",
    AppLang.roman: "Eint: Rs 15-20 | Cement: Rs 1,250-1,450\nSteel: Rs 260-300 | Ret: Rs 45-65\nBajri: Rs 100-130 | Mazdoori: Rs 280-450",
  }[_lang]!;

  String get brickRate => {
    AppLang.english: "Brick Rate (per No)",
    AppLang.urdu: "اینٹ ریٹ (فی عدد)",
    AppLang.roman: "Eint Rate (per No)",
  }[_lang]!;

  String get cementRate => {
    AppLang.english: "Cement Rate (per Bag)",
    AppLang.urdu: "سیمنٹ ریٹ (فی بوری)",
    AppLang.roman: "Cement Rate (per Bag)",
  }[_lang]!;

  String get steelRate => {
    AppLang.english: "Steel Rate (per Kg)",
    AppLang.urdu: "سٹیل ریٹ (فی کلو)",
    AppLang.roman: "Steel Rate (per Kg)",
  }[_lang]!;

  String get sandRate => {
    AppLang.english: "Sand Rate (per CFT)",
    AppLang.urdu: "ریت ریٹ (فی سی ایف ٹی)",
    AppLang.roman: "Ret Rate (per CFT)",
  }[_lang]!;

  String get crushRate => {
    AppLang.english: "Crush Rate (per CFT)",
    AppLang.urdu: "بجری ریٹ (فی سی ایف ٹی)",   // کرش → بجری
    AppLang.roman: "Bajri Rate (per CFT)",         // Crush → Bajri
  }[_lang]!;

  String get laborRate => {
    AppLang.english: "Labor Rate (per Sqft)",
    AppLang.urdu: "مزدوری ریٹ (فی مربع فٹ)",
    AppLang.roman: "Mazdoori Rate (per Sqft)",
  }[_lang]!;

  String get update => {
    AppLang.english: "Update",
    AppLang.urdu: "اپ ڈیٹ کریں",
    AppLang.roman: "Update Karein",
  }[_lang]!;

  String get ratesUpdated => {
    AppLang.english: "Rates updated! Calculation refreshed.",
    AppLang.urdu: "ریٹس اپ ڈیٹ ہو گئے!",
    AppLang.roman: "Rates update ho gaye!",
  }[_lang]!;

  String get setBudgetRange => {
    AppLang.english: "Set Budget Range",
    AppLang.urdu: "بجٹ حد مقرر کریں",
    AppLang.roman: "Budget Range Set Karein",
  }[_lang]!;

  String get enterMinMax => {
    AppLang.english: "Enter min & max for estimate",
    AppLang.urdu: "کم از کم اور زیادہ سے زیادہ درج کریں",
    AppLang.roman: "Min aur Max darj karein",
  }[_lang]!;

  String get minimumBudget => {
    AppLang.english: "Minimum Budget (Rs)",
    AppLang.urdu: "کم از کم بجٹ (روپے)",
    AppLang.roman: "Minimum Budget (Rs)",
  }[_lang]!;

  String get maximumBudget => {
    AppLang.english: "Maximum Budget (Rs)",
    AppLang.urdu: "زیادہ سے زیادہ بجٹ (روپے)",
    AppLang.roman: "Maximum Budget (Rs)",
  }[_lang]!;

  String get setAndViewAnalysis => {
    AppLang.english: "Set & View Analysis",
    AppLang.urdu: "سیٹ کریں اور تجزیہ دیکھیں",
    AppLang.roman: "Set karein aur Analysis dekhein",
  }[_lang]!;

  String get pleaseEnterValidAmounts => {
    AppLang.english: "Please enter valid amounts",
    AppLang.urdu: "درست رقم درج کریں",
    AppLang.roman: "Sahi raqam darj karein",
  }[_lang]!;

  String get maxGreaterThanMin => {
    AppLang.english: "Max must be greater than Min",
    AppLang.urdu: "زیادہ سے زیادہ، کم از کم سے زیادہ ہونا چاہیے",
    AppLang.roman: "Max, Min se zyada hona chahiye",
  }[_lang]!;

  String get withinBudget => {
    AppLang.english: "Within Your Budget! ✅",
    AppLang.urdu: "بجٹ کے اندر! ✅",
    AppLang.roman: "Budget ke andar! ✅",
  }[_lang]!;

  String get outsideBudget => {
    AppLang.english: "Outside Your Budget! ⚠️",
    AppLang.urdu: "بجٹ سے باہر! ⚠️",
    AppLang.roman: "Budget se bahar! ⚠️",
  }[_lang]!;

  String get minBudget => {
    AppLang.english: "Min Budget",
    AppLang.urdu: "کم از کم بجٹ",
    AppLang.roman: "Min Budget",
  }[_lang]!;

  String get yourEstimate => {
    AppLang.english: "Your Estimate",
    AppLang.urdu: "آپ کا تخمینہ",
    AppLang.roman: "Aapka Andaza",
  }[_lang]!;

  String get maxBudget => {
    AppLang.english: "Max Budget",
    AppLang.urdu: "زیادہ سے زیادہ بجٹ",
    AppLang.roman: "Max Budget",
  }[_lang]!;

  String get toSpare => {
    AppLang.english: "to spare",
    AppLang.urdu: "بچت",
    AppLang.roman: "bachat",
  }[_lang]!;

  String get overBudget => {
    AppLang.english: "over budget",
    AppLang.urdu: "بجٹ سے زیادہ",
    AppLang.roman: "budget se zyada",
  }[_lang]!;

  String get materialQuantities => {
    AppLang.english: "Material Quantities",
    AppLang.urdu: "مواد کی مقدار",
    AppLang.roman: "Mawad ki Miqdar",
  }[_lang]!;

  String get costBreakdown => {
    AppLang.english: "Cost Breakdown",
    AppLang.urdu: "لاگت کی تفصیل",
    AppLang.roman: "Lagat ki Tafseel",
  }[_lang]!;

  String get floorWiseCost => {
    AppLang.english: "Floor-wise Cost (Gray)",
    AppLang.urdu: "منزل وار لاگت (گرے)",
    AppLang.roman: "Floor-wise Lagat (Gray)",
  }[_lang]!;

  String get floorWiseArea => {
    AppLang.english: "Floor-wise Area & Cost",
    AppLang.urdu: "منزل وار رقبہ اور لاگت",
    AppLang.roman: "Floor-wise Raqba aur Lagat",
  }[_lang]!;

  String get suggestedHousePlans => {
    AppLang.english: "Suggested House Plans",
    AppLang.urdu: "تجویز کردہ گھر کے نقشے",
    AppLang.roman: "Tajweez Karda Ghar ke Naqshay",
  }[_lang]!;

  String get totalGrayCost => {
    AppLang.english: "TOTAL GRAY COST ESTIMATE",
    AppLang.urdu: "کل گرے لاگت کا تخمینہ",
    AppLang.roman: "Kul Gray Lagat ka Andaza",
  }[_lang]!;

  String get totalBudgetGrayFinishing => {
    AppLang.english: "TOTAL BUDGET (GRAY + FINISHING)",
    AppLang.urdu: "کل بجٹ (گرے + فنشنگ)",
    AppLang.roman: "Kul Budget (Gray + Finishing)",
  }[_lang]!;

  String get coveredArea => {
    AppLang.english: "COVERED AREA",
    AppLang.urdu: "احاطہ شدہ رقبہ",
    AppLang.roman: "COVERED AREA",
  }[_lang]!;

  String get costPerSqft => {
    AppLang.english: "COST/SQFT",
    AppLang.urdu: "لاگت/مربع فٹ",
    AppLang.roman: "LAGAT/SQFT",
  }[_lang]!;

  String get grayCost => {
    AppLang.english: "GRAY COST",
    AppLang.urdu: "گرے لاگت",
    AppLang.roman: "GRAY LAGAT",
  }[_lang]!;

  String get grayStructure => {
    AppLang.english: "Gray Structure",
    AppLang.urdu: "گرے ڈھانچہ",
    AppLang.roman: "Gray Structure",
  }[_lang]!;

  String get finishingWork => {
    AppLang.english: "Finishing Work",
    AppLang.urdu: "فنشنگ کا کام",
    AppLang.roman: "Finishing ka Kaam",
  }[_lang]!;

  String get total => {
    AppLang.english: "TOTAL",
    AppLang.urdu: "کل",
    AppLang.roman: "KUL",
  }[_lang]!;

  String get item => {
    AppLang.english: "Item",
    AppLang.urdu: "آئٹم",
    AppLang.roman: "Item",
  }[_lang]!;

  String get amountPKR => {
    AppLang.english: "Amount (PKR)",
    AppLang.urdu: "رقم (روپے)",
    AppLang.roman: "Raqam (PKR)",
  }[_lang]!;

  String get floor => {
    AppLang.english: "Floor",
    AppLang.urdu: "منزل",
    AppLang.roman: "Floor",
  }[_lang]!;

  String get areaFt => {
    AppLang.english: "Area (ft²)",
    AppLang.urdu: "رقبہ (فٹ²)",
    AppLang.roman: "Raqba (ft²)",
  }[_lang]!;

  String get costPKR => {
    AppLang.english: "Cost (PKR)",
    AppLang.urdu: "لاگت (روپے)",
    AppLang.roman: "Lagat (PKR)",
  }[_lang]!;

  String get grayTotal => {
    AppLang.english: "GRAY TOTAL",
    AppLang.urdu: "گرے کل",
    AppLang.roman: "GRAY TOTAL",
  }[_lang]!;

  String get enterDetailsFirst => {
    AppLang.english: "Enter details in Configure tab first",
    AppLang.urdu: "پہلے ترتیب ٹیب میں تفصیل درج کریں",
    AppLang.roman: "Pehle Configure tab mein details darj karein",
  }[_lang]!;

  String get whatCanBeBuilt => {
    AppLang.english: "What can be built in this budget?",
    AppLang.urdu: "اس بجٹ میں کیا بن سکتا ہے؟",
    AppLang.roman: "Is budget mein kya ban sakta hai?",
  }[_lang]!;

  String get estimateExceeds => {
    AppLang.english: "Estimate exceeds your budget range!",
    AppLang.urdu: "تخمینہ آپ کی بجٹ حد سے زیادہ ہے!",
    AppLang.roman: "Estimate aapki budget range se zyada hai!",
  }[_lang]!;

  String get toBringWithin => {
    AppLang.english: "To bring within budget:",
    AppLang.urdu: "بجٹ کے اندر لانے کے لیے:",
    AppLang.roman: "Budget mein lane ke liye:",
  }[_lang]!;

  String get reduceFloors => {
    AppLang.english: "Reduce floors",
    AppLang.urdu: "منزلیں کم کریں",
    AppLang.roman: "Floors kam karein",
  }[_lang]!;

  String get switchToEconomy => {
    AppLang.english: "Switch to B Class (Economy) quality",
    AppLang.urdu: "بی کلاس (اکانومی) معیار پر جائیں",
    AppLang.roman: "B Class (Economy) quality pe jayein",
  }[_lang]!;

  String get removeFinishing => {
    AppLang.english: "Remove finishing — focus on gray structure first",
    AppLang.urdu: "فنشنگ ہٹائیں — پہلے گرے ڈھانچہ",
    AppLang.roman: "Finishing hatayein — pehle gray structure",
  }[_lang]!;

  String get smallerPlot => {
    AppLang.english: "Choose a slightly smaller plot size",
    AppLang.urdu: "تھوڑا چھوٹا پلاٹ منتخب کریں",
    AppLang.roman: "Thoda chhota plot select karein",
  }[_lang]!;

  String get groundFloor => {
    AppLang.english: "Ground Floor",
    AppLang.urdu: "گراؤنڈ فلور",
    AppLang.roman: "Ground Floor",
  }[_lang]!;

  String get firstFloor => {
    AppLang.english: "First Floor",
    AppLang.urdu: "پہلی منزل",
    AppLang.roman: "Pehli Manzil",
  }[_lang]!;

  String get secondFloor => {
    AppLang.english: "Second Floor",
    AppLang.urdu: "دوسری منزل",
    AppLang.roman: "Doosri Manzil",
  }[_lang]!;

  String get yoHaveRs => {
    AppLang.english: "You have Rs",
    AppLang.urdu: "آپ کے پاس",
    AppLang.roman: "Aapke paas Rs",
  }[_lang]!;

  String get rsOverBudget => {
    AppLang.english: "Rs",
    AppLang.urdu: "روپے",
    AppLang.roman: "Rs",
  }[_lang]!;

  String get deleteConfirmPrefix => {
    AppLang.english: "Are you sure you want to delete",
    AppLang.urdu: "کیا آپ واقعی حذف کرنا چاہتے ہیں",
    AppLang.roman: "Kya Aap Waqai Delete Karna Chahte Hain",
  }[_lang]!;

  // ═══════════════════════════════════════
  //  PROJECT SCREEN STRINGS
  // ═══════════════════════════════════════

  String get constructionHub => {
    AppLang.english: "Construction Hub",
    AppLang.urdu: "تعمیراتی مرکز",
    AppLang.roman: "Construction Hub",
  }[_lang]!;

  String get siteInventory => {
    AppLang.english: "Site Inventory",
    AppLang.urdu: "سائٹ انوینٹری",
    AppLang.roman: "Site Inventory",
  }[_lang]!;

  String get siteSubtitle => {
    AppLang.english: "Track and manage your ongoing construction work.",
    AppLang.urdu: "اپنے جاری تعمیراتی کام کو ٹریک کریں۔",
    AppLang.roman: "Apna jaari tameerati kaam track karein.",
  }[_lang]!;

  String get noClient => {
    AppLang.english: "No Client Assigned",
    AppLang.urdu: "کوئی کلائنٹ نہیں",
    AppLang.roman: "Koi Client Nahi",
  }[_lang]!;

  String get activeSite => {
    AppLang.english: "ACTIVE SITE",
    AppLang.urdu: "فعال سائٹ",
    AppLang.roman: "ACTIVE SITE",
  }[_lang]!;

  String get constrProgress => {
    AppLang.english: "Construction Progress",
    AppLang.urdu: "تعمیراتی پیشرفت",
    AppLang.roman: "Tameerati Progress",
  }[_lang]!;

  String get deleteProject => {
    AppLang.english: "Delete Project?",
    AppLang.urdu: "منصوبہ حذف کریں؟",
    AppLang.roman: "Project Delete Karein?",
  }[_lang]!;

  String get delete => {
    AppLang.english: "DELETE",
    AppLang.urdu: "حذف کریں",
    AppLang.roman: "DELETE",
  }[_lang]!;

  String get projectRemoved => {
    AppLang.english: "Project removed successfully",
    AppLang.urdu: "منصوبہ کامیابی سے حذف ہو گیا",
    AppLang.roman: "Project successfully delete ho gaya",
  }[_lang]!;
  //  PROJECT DETAIL SCREEN STRINGS
  // ═══════════════════════════════════════

  String get notAdded => {
    AppLang.english: "Not Added",
    AppLang.urdu: "شامل نہیں",
    AppLang.roman: "Shamil Nahi",
  }[_lang]!;

  String get projectFinalization => {
    AppLang.english: "Project Finalization",
    AppLang.urdu: "منصوبے کی حتمی کاری",
    AppLang.roman: "Project ki Hatmi Kaari",
  }[_lang]!;

  String get addCompletionPhotos => {
    AppLang.english: "Add completion photos for the final report:",
    AppLang.urdu: "حتمی رپورٹ کے لیے تکمیل کی تصاویر شامل کریں:",
    AppLang.roman: "Final report ke liye tasveerein shamil karein:",
  }[_lang]!;

  String get generatingPdf => {
    AppLang.english: "Generating PDF Report...",
    AppLang.urdu: "پی ڈی ایف رپورٹ بن رہی ہے...",
    AppLang.roman: "PDF Report ban rahi hai...",
  }[_lang]!;

  String get readyToGenerate => {
    AppLang.english: "Ready to generate the final PDF and close this project?",
    AppLang.urdu: "کیا آپ حتمی پی ڈی ایف بنانا اور منصوبہ بند کرنا چاہتے ہیں؟",
    AppLang.roman: "Kya aap final PDF banana aur project band karna chahte hain?",
  }[_lang]!;

  String get generateReport => {
    AppLang.english: "GENERATE REPORT",
    AppLang.urdu: "رپورٹ بنائیں",
    AppLang.roman: "Report Banayein",
  }[_lang]!;

  String get reportSaved => {
    AppLang.english: "Report Generated & Saved!",
    AppLang.urdu: "رپورٹ بن گئی اور محفوظ ہو گئی!",
    AppLang.roman: "Report ban gayi aur mehfooz ho gayi!",
  }[_lang]!;

  String get reportFailed => {
    AppLang.english: "Failed to generate report.",
    AppLang.urdu: "رپورٹ بنانے میں ناکامی۔",
    AppLang.roman: "Report banane mein nakami.",
  }[_lang]!;

  String get finishClose => {
    AppLang.english: "FINISH & CLOSE",
    AppLang.urdu: "مکمل اور بند کریں",
    AppLang.roman: "Mukammal aur Band Karein",
  }[_lang]!;

  String get uploadFailed => {
    AppLang.english: "Upload Failed",
    AppLang.urdu: "اپلوڈ ناکام",
    AppLang.roman: "Upload Nakaam",
  }[_lang]!;

  String get clientInfo => {
    AppLang.english: "Client Info",
    AppLang.urdu: "کلائنٹ کی معلومات",
    AppLang.roman: "Client ki Malumaat",
  }[_lang]!;

  String get primaryClient => {
    AppLang.english: "Primary Client",
    AppLang.urdu: "مرکزی کلائنٹ",
    AppLang.roman: "Markazi Client",
  }[_lang]!;

  String get workProgress => {
    AppLang.english: "Work Progress",
    AppLang.urdu: "کام کی پیشرفت",
    AppLang.roman: "Kaam ki Taraqi",
  }[_lang]!;

  String get overallComplete => {
    AppLang.english: "Overall Completion",
    AppLang.urdu: "مجموعی تکمیل",
    AppLang.roman: "Majmui Takmeel",
  }[_lang]!;

  String get financialStats => {
    AppLang.english: "Financial Statistics",
    AppLang.urdu: "مالی اعداد و شمار",
    AppLang.roman: "Maali Aadaad o Shumaar",
  }[_lang]!;

  String get remainingAmt => {
    AppLang.english: "Remaining",
    AppLang.urdu: "باقی رقم",
    AppLang.roman: "Baaqi Raqam",
  }[_lang]!;

  String get profit => {
    AppLang.english: "Profit",
    AppLang.urdu: "منافع",
    AppLang.roman: "Munafa",
  }[_lang]!;

  String get siteManagement => {
    AppLang.english: "Site Management",
    AppLang.urdu: "سائٹ انتظام",
    AppLang.roman: "Site Intezaam",
  }[_lang]!;

  String get dailyTasks => {
    AppLang.english: "Daily Site Tasks",
    AppLang.urdu: "روزانہ کے کام",
    AppLang.roman: "Rozana ke Kaam",
  }[_lang]!;

  String get materialExp => {
    AppLang.english: "Material & Expenses",
    AppLang.urdu: "مواد اور اخراجات",
    AppLang.roman: "Mawad aur Ikhrajaat",
  }[_lang]!;

  String get laborAttend => {
    AppLang.english: "Labor & Attendance",
    AppLang.urdu: "مزدور اور حاضری",
    AppLang.roman: "Mazdoor aur Hazri",
  }[_lang]!;

  String get dailyReports => {
    AppLang.english: "Daily Reports Log",
    AppLang.urdu: "روزانہ رپورٹ لاگ",
    AppLang.roman: "Rozana Report Log",
  }[_lang]!;

  String get uploadEntry => {
    AppLang.english: "Upload New Entry",
    AppLang.urdu: "نئی اندراج اپلوڈ کریں",
    AppLang.roman: "Nai Entry Upload Karein",
  }[_lang]!;

  String get finishSite => {
    AppLang.english: "Finish & Close Site",
    AppLang.urdu: "سائٹ مکمل اور بند کریں",
    AppLang.roman: "Site Mukammal aur Band Karein",
  }[_lang]!;

  String get projectDone => {
    AppLang.english: "This project is marked as COMPLETED",
    AppLang.urdu: "یہ منصوبہ مکمل ہو گیا ہے",
    AppLang.roman: "Yeh project mukammal ho gaya hai",
  }[_lang]!;

  String get configProject => {
    AppLang.english: "Configure Project",
    AppLang.urdu: "منصوبہ ترتیب دیں",
    AppLang.roman: "Project Tarteeb Dein",
  }[_lang]!;

  String get budgetRs => {
    AppLang.english: "Total Budget (Rs)",
    AppLang.urdu: "کل بجٹ (روپے)",
    AppLang.roman: "Kul Budget (Rs)",
  }[_lang]!;

  String get yourProfit => {
    AppLang.english: "Your Profit (Rs)",
    AppLang.urdu: "آپ کا منافع (روپے)",
    AppLang.roman: "Aapka Munafa (Rs)",
  }[_lang]!;

  String get saveChanges => {
    AppLang.english: "Save Changes",
    AppLang.urdu: "تبدیلیاں محفوظ کریں",
    AppLang.roman: "Tabdeeliyaan Mehfooz Karein",
  }[_lang]!;
  // ═══════════════════════════════════════
  //  DAILY REPORT SCREEN STRINGS
  // ═══════════════════════════════════════

  String get dailySiteReports => {
    AppLang.english: "Daily Site Reports",
    AppLang.urdu: "روزانہ سائٹ رپورٹس",
    AppLang.roman: "Rozana Site Reports",
  }[_lang]!;

  String get reports => {
    AppLang.english: "Reports",
    AppLang.urdu: "رپورٹس",
    AppLang.roman: "Reports",
  }[_lang]!;

  String get noReports => {
    AppLang.english: "No reports found for this date",
    AppLang.urdu: "اس تاریخ کی کوئی رپورٹ نہیں ملی",
    AppLang.roman: "Is tareekh ki koi report nahi mili",
  }[_lang]!;

  String get selectOtherDate => {
    AppLang.english: "Select another date to view reports",
    AppLang.urdu: "رپورٹس دیکھنے کے لیے دوسری تاریخ منتخب کریں",
    AppLang.roman: "Reports dekhne ke liye doosri tareekh chunein",
  }[_lang]!;

  String get sitePhoto => {
    AppLang.english: "Site Photo",
    AppLang.urdu: "سائٹ تصویر",
    AppLang.roman: "Site Tasveer",
  }[_lang]!;

  String get siteReport => {
    AppLang.english: "Site Report",
    AppLang.urdu: "سائٹ رپورٹ",
    AppLang.roman: "Site Report",
  }[_lang]!;
  // ═══════════════════════════════════════
  //  MATERIAL SCREEN STRINGS
  // ═══════════════════════════════════════

  String get materialExpenses => {
    AppLang.english: "Material Expenses",
    AppLang.urdu: "مواد کے اخراجات",
    AppLang.roman: "Mawad ke Ikhrajaat",
  }[_lang]!;

  String get itemName => {
    AppLang.english: "Item Name",
    AppLang.urdu: "چیز کا نام",
    AppLang.roman: "Cheez ka Naam",
  }[_lang]!;

  String get qty => {
    AppLang.english: "Qty",
    AppLang.urdu: "مقدار",
    AppLang.roman: "Miqdar",
  }[_lang]!;

  String get price => {
    AppLang.english: "Price",
    AppLang.urdu: "قیمت",
    AppLang.roman: "Qeemat",
  }[_lang]!;

  String get addExpenseManually => {
    AppLang.english: "Add Expense Manually",
    AppLang.urdu: "خرچ خود شامل کریں",
    AppLang.roman: "Kharch Khud Shamil Karein",
  }[_lang]!;

  String get recentMaterialLogs => {
    AppLang.english: "Recent Material Logs",
    AppLang.urdu: "حالیہ مواد کا ریکارڈ",
    AppLang.roman: "Halia Mawad ka Record",
  }[_lang]!;

  String get noRecords => {
    AppLang.english: "No records found",
    AppLang.urdu: "کوئی ریکارڈ نہیں ملا",
    AppLang.roman: "Koi record nahi mila",
  }[_lang]!;

  String get fillAllFields => {
    AppLang.english: "Please fill all fields",
    AppLang.urdu: "براہ کرم سارے خانے بھریں",
    AppLang.roman: "Meherbani se saare khaane bharein",
  }[_lang]!;

  String get budgetExceeded => {
    AppLang.english: "This expense exceeds your budget!",
    AppLang.urdu: "یہ خرچ بجٹ سے زیادہ ہے!",
    AppLang.roman: "Yeh kharch budget se zyada hai!",
  }[_lang]!;
  // ═══════════════════════════════════════
//  LABOR SCREEN STRINGS
// ═══════════════════════════════════════

  String get laborDashboard => {
    AppLang.english: "Labor Dashboard",
    AppLang.urdu: "مزدور ڈیش بورڈ",
    AppLang.roman: "Mazdoor Dashboard",
  }[_lang]!;

  String get noWorkersYet => {
    AppLang.english: "No Workers Added Yet",
    AppLang.urdu: "ابھی کوئی مزدور نہیں",
    AppLang.roman: "Abhi koi mazdoor nahi",
  }[_lang]!;

  String get tapToAddWorker => {
    AppLang.english: "Tap + button to add first worker",
    AppLang.urdu: "مزدور شامل کرنے کے لیے + دبائیں",
    AppLang.roman: "Mazdoor shamil karne ke liye + dabayein",
  }[_lang]!;

  String get workerDeleted => {
    AppLang.english: "Worker Deleted",
    AppLang.urdu: "مزدور حذف ہو گیا",
    AppLang.roman: "Mazdoor delete ho gaya",
  }[_lang]!;

  String get markedPresent => {
    AppLang.english: "Marked Present",
    AppLang.urdu: "حاضر درج کیا گیا",
    AppLang.roman: "Haazir darj kiya gaya",
  }[_lang]!;

  String get markedAbsent => {
    AppLang.english: "Marked Absent",
    AppLang.urdu: "غیر حاضر درج کیا گیا",
    AppLang.roman: "Ghair haazir darj kiya gaya",
  }[_lang]!;

  String get addWorker => {
    AppLang.english: "Add Worker",
    AppLang.urdu: "مزدور شامل کریں",
    AppLang.roman: "Mazdoor Shamil Karein",
  }[_lang]!;

  String get workerName => {
    AppLang.english: "Name",
    AppLang.urdu: "نام",
    AppLang.roman: "Naam",
  }[_lang]!;

  String get workerRole => {
    AppLang.english: "Role",
    AppLang.urdu: "کردار",
    AppLang.roman: "Kirdar",
  }[_lang]!;

  String get workerPhone => {
    AppLang.english: "Phone",
    AppLang.urdu: "فون",
    AppLang.roman: "Phone",
  }[_lang]!;

  String get workerWage => {
    AppLang.english: "Wage",
    AppLang.urdu: "اجرت",
    AppLang.roman: "Ujrat",
  }[_lang]!;

  String get workersCount => {
    AppLang.english: "Workers",
    AppLang.urdu: "مزدور",
    AppLang.roman: "Mazdoor",
  }[_lang]!;

  String get nameRequired => {
    AppLang.english: "Name required",
    AppLang.urdu: "نام ضروری ہے",
    AppLang.roman: "Naam zaroori hai",
  }[_lang]!;

  String get roleRequired => {
    AppLang.english: "Role required",
    AppLang.urdu: "کردار ضروری ہے",
    AppLang.roman: "Kirdar zaroori hai",
  }[_lang]!;

  String get phoneRequired => {
    AppLang.english: "Phone required",
    AppLang.urdu: "فون ضروری ہے",
    AppLang.roman: "Phone zaroori hai",
  }[_lang]!;

  String get wageRequired => {
    AppLang.english: "Wage required",
    AppLang.urdu: "اجرت ضروری ہے",
    AppLang.roman: "Ujrat zaroori hai",
  }[_lang]!;

  String get onlyAlphabets => {
    AppLang.english: "Only alphabets allowed",
    AppLang.urdu: "صرف حروف درج کریں",
    AppLang.roman: "Sirf huroof darj karein",
  }[_lang]!;

  String get onlyNumbers => {
    AppLang.english: "Only numbers allowed",
    AppLang.urdu: "صرف نمبر درج کریں",
    AppLang.roman: "Sirf number darj karein",
  }[_lang]!;

  String get save => {
    AppLang.english: "Save",
    AppLang.urdu: "محفوظ کریں",
    AppLang.roman: "Mehfooz Karein",
  }[_lang]!;
  // ═══════════════════════════════════════
//  TASK SCREEN STRINGS
// ═══════════════════════════════════════

  String get dailySiteTasks => {
    AppLang.english: "Daily Site Tasks",
    AppLang.urdu: "روزانہ سائٹ کے کام",
    AppLang.roman: "Rozana Site ke Kaam",
  }[_lang]!;

  String get whatNeedsDone => {
    AppLang.english: "What needs to be done?",
    AppLang.urdu: "کیا کرنا ہے؟",
    AppLang.roman: "Kya karna hai?",
  }[_lang]!;

  String get noTasksForDay => {
    AppLang.english: "No tasks for this day",
    AppLang.urdu: "اس دن کا کوئی کام نہیں",
    AppLang.roman: "Is din ka koi kaam nahi",
  }[_lang]!;

  String get errorAddingTask => {
    AppLang.english: "Error adding task",
    AppLang.urdu: "کام شامل کرنے میں خرابی",
    AppLang.roman: "Kaam shamil karne mein kharabi",
  }[_lang]!;
  // ═══════════════════════════════════════
//  WORKER DETAIL SCREEN STRINGS
// ═══════════════════════════════════════

  String get workerInfo => {
    AppLang.english: "Worker Info",
    AppLang.urdu: "مزدور کی معلومات",
    AppLang.roman: "Mazdoor ki Malumaat",
  }[_lang]!;

  String get dailyWageRs => {
    AppLang.english: "Daily Wage (Rs)",
    AppLang.urdu: "روزانہ اجرت (روپے)",
    AppLang.roman: "Rozana Ujrat (Rs)",
  }[_lang]!;

  String get workerInfoUpdated => {
    AppLang.english: "Worker info updated!",
    AppLang.urdu: "مزدور کی معلومات اپ ڈیٹ ہو گئی!",
    AppLang.roman: "Mazdoor ki malumaat update ho gayi!",
  }[_lang]!;

  String get daysPresent => {
    AppLang.english: "Days Present",
    AppLang.urdu: "حاضر دن",
    AppLang.roman: "Haazir Din",
  }[_lang]!;

  String get totalEarned => {
    AppLang.english: "Total Earned",
    AppLang.urdu: "کل کمائی",
    AppLang.roman: "Kul Kamai",
  }[_lang]!;

  String get attendanceCalendar => {
    AppLang.english: "Attendance Calendar",
    AppLang.urdu: "حاضری کیلنڈر",
    AppLang.roman: "Hazri Calendar",
  }[_lang]!;

  String get present => {
    AppLang.english: "Present",
    AppLang.urdu: "حاضر",
    AppLang.roman: "Haazir",
  }[_lang]!;

  String get absent => {
    AppLang.english: "Absent",
    AppLang.urdu: "غیر حاضر",
    AppLang.roman: "Ghair Haazir",
  }[_lang]!;

  String get workerDetail => {
    AppLang.english: "Worker Detail",
    AppLang.urdu: "مزدور کی تفصیل",
    AppLang.roman: "Mazdoor ki Tafseel",
  }[_lang]!;
  // ═══════════════════════════════════════
//  ROLE DETAIL SCREEN STRINGS
// ═══════════════════════════════════════

  String get noWorkersAdded => {
    AppLang.english: "No workers added",
    AppLang.urdu: "کوئی مزدور شامل نہیں",
    AppLang.roman: "Koi mazdoor shamil nahi",
  }[_lang]!;

  String get failedToOpenDialer => {
    AppLang.english: "Failed to open dialer",
    AppLang.urdu: "ڈائلر کھولنے میں ناکامی",
    AppLang.roman: "Dialer kholne mein nakami",
  }[_lang]!;
  // ═══════════════════════════════════════
//  SCANNER SCREEN STRINGS
// ═══════════════════════════════════════

  String get aiMapScanner => {
    AppLang.english: "AI Map Scanner",
    AppLang.urdu: "اے آئی نقشہ اسکینر",
    AppLang.roman: "AI Naqsha Scanner",
  }[_lang]!;

  String get smartArchScanner => {
    AppLang.english: "Smart Architecture Scanner",
    AppLang.urdu: "سمارٹ تعمیراتی اسکینر",
    AppLang.roman: "Smart Tameerati Scanner",
  }[_lang]!;

  String get detectingArea => {
    AppLang.english: "Detecting Total Covered Area",
    AppLang.urdu: "کل احاطہ شدہ رقبہ تلاش ہو رہا ہے",
    AppLang.roman: "Kul Covered Area Talash Ho Raha Hai",
  }[_lang]!;

  String get scanFromCamera => {
    AppLang.english: "Scan Map from Camera",
    AppLang.urdu: "کیمرے سے نقشہ اسکین کریں",
    AppLang.roman: "Camera se Naqsha Scan Karein",
  }[_lang]!;

  String get uploadFromGallery => {
    AppLang.english: "Upload from Gallery",
    AppLang.urdu: "گیلری سے اپلوڈ کریں",
    AppLang.roman: "Gallery se Upload Karein",
  }[_lang]!;

  String get analyzingMap => {
    AppLang.english: "Analyzing Map details...",
    AppLang.urdu: "نقشے کی تفصیل جانچی جا رہی ہے...",
    AppLang.roman: "Naqshay ki tafseel janchi ja rahi hai...",
  }[_lang]!;

  String get areaNotDetected => {
    AppLang.english: "AI could not detect area. Please enter manually.",
    AppLang.urdu: "اے آئی رقبہ نہ پہچان سکا۔ خود درج کریں۔",
    AppLang.roman: "AI raqba nahi pehchan saka. Khud darj karein.",
  }[_lang]!;

  String get properGrayEstimate => {
    AppLang.english: "Proper Gray Estimate",
    AppLang.urdu: "درست گرے تخمینہ",
    AppLang.roman: "Durust Gray Andaza",
  }[_lang]!;

  String get totalCoveredArea => {
    AppLang.english: "Total Covered Area",
    AppLang.urdu: "کل احاطہ شدہ رقبہ",
    AppLang.roman: "Kul Covered Area",
  }[_lang]!;

  String get materialBreakdown => {
    AppLang.english: "Material Breakdown:",
    AppLang.urdu: "مواد کی تفصیل:",
    AppLang.roman: "Mawad ki Tafseel:",
  }[_lang]!;

  String get estimatedTotal => {
    AppLang.english: "ESTIMATED TOTAL",
    AppLang.urdu: "کل تخمینہ",
    AppLang.roman: "KUL ANDAZA",
  }[_lang]!;

  String get saveToProject => {
    AppLang.english: "SAVE TO PROJECT",
    AppLang.urdu: "منصوبے میں محفوظ کریں",
    AppLang.roman: "Project mein Mehfooz Karein",
  }[_lang]!;

  String get estimateSaved => {
    AppLang.english: "Estimate saved!",
    AppLang.urdu: "تخمینہ محفوظ ہو گیا!",
    AppLang.roman: "Andaza mehfooz ho gaya!",
  }[_lang]!;

  String get correctArea => {
    AppLang.english: "Correct Area",
    AppLang.urdu: "رقبہ درست کریں",
    AppLang.roman: "Raqba Durust Karein",
  }[_lang]!;

  String get sqftArea => {
    AppLang.english: "Sqft Area",
    AppLang.urdu: "مربع فٹ رقبہ",
    AppLang.roman: "Sqft Raqba",
  }[_lang]!;

  String get recalculate => {
    AppLang.english: "Recalculate",
    AppLang.urdu: "دوبارہ حساب کریں",
    AppLang.roman: "Dobara Hisaab Karein",
  }[_lang]!;
  // ═══════════════════════════════════════
//  MATERIAL NAMES
// ═══════════════════════════════════════

  String get bricks => {
    AppLang.english: "Bricks",
    AppLang.urdu: "اینٹیں",
    AppLang.roman: "Eintein",
  }[_lang]!;

  String get cement => {
    AppLang.english: "Cement",
    AppLang.urdu: "سیمنٹ",
    AppLang.roman: "Cement",
  }[_lang]!;

  String get steel => {
    AppLang.english: "Steel",
    AppLang.urdu: "سریا",
    AppLang.roman: "Saria",
  }[_lang]!;

  String get sand => {
    AppLang.english: "Sand (CFT)",
    AppLang.urdu: "ریت (سی ایف ٹی)",
    AppLang.roman: "Ret (CFT)",
  }[_lang]!;

  String get crush => {
    AppLang.english: "Crush (CFT)",
    AppLang.urdu: "بجری (سی ایف ٹی)",
    AppLang.roman: "Bajri (CFT)",
  }[_lang]!;

  String get laborCost => {
    AppLang.english: "Labor Cost",
    AppLang.urdu: "مزدوری",
    AppLang.roman: "Mazdoori",
  }[_lang]!;
  // ═══════════════════════════════════════
//  MATERIAL KEY TRANSLATIONS
// ═══════════════════════════════════════

  String get miscContingency => {
    AppLang.english: "Misc / Contingency",
    AppLang.urdu: "متفرق / غیر متوقع",
    AppLang.roman: "Mutafarriq / Ghair Mutawaqqa",
  }[_lang]!;

  String get foundationPremium => {
    AppLang.english: "Foundation Premium",
    AppLang.urdu: "بنیاد پریمیم",
    AppLang.roman: "Bunyaad Premium",
  }[_lang]!;

  String get laborKey => {
    AppLang.english: "Labor",
    AppLang.urdu: "مزدوری",
    AppLang.roman: "Mazdoori",
  }[_lang]!;
  String get matBricks => {
    AppLang.english: "Bricks",
    AppLang.urdu: "اینٹیں",
    AppLang.roman: "Eintein",
  }[_lang]!;

  String get matCement => {
    AppLang.english: "Cement",
    AppLang.urdu: "سیمنٹ",
    AppLang.roman: "Cement",
  }[_lang]!;

  String get matSteel => {
    AppLang.english: "Steel",
    AppLang.urdu: "سٹیل",
    AppLang.roman: "Steel",
  }[_lang]!;

  String get matSand => {
    AppLang.english: "Sand",
    AppLang.urdu: "ریت",
    AppLang.roman: "Ret",
  }[_lang]!;

  String get matCrush => {
    AppLang.english: "Crush",
    AppLang.urdu: "بجری",
    AppLang.roman: "bajri",
  }[_lang]!;

  String get matLabor => {
    AppLang.english: "Labor",
    AppLang.urdu: "مزدوری",
    AppLang.roman: "Mazdoori",
  }[_lang]!;

  String get matMisc => {
    AppLang.english: "Misc / Contingency",
    AppLang.urdu: "متفرق اخراجات",
    AppLang.roman: "Misc / Contingency",
  }[_lang]!;

  String get matFoundation => {
    AppLang.english: "Foundation Premium",
    AppLang.urdu: "بنیاد پریمیم",
    AppLang.roman: "Foundation Premium",
  }[_lang]!;
  String get minBudgetLabel => {
    AppLang.english: "Min Budget",
    AppLang.urdu: "کم از کم بجٹ",
    AppLang.roman: "Min Budget",
  }[_lang]!;

  String get maxBudgetLabel => {
    AppLang.english: "Max Budget",
    AppLang.urdu: "زیادہ سے زیادہ بجٹ",
    AppLang.roman: "Max Budget",
  }[_lang]!;

  String get perFloor => {
    AppLang.english: "Per floor",
    AppLang.urdu: "فی منزل",
    AppLang.roman: "Har Floor",
  }[_lang]!;

  String get drawingRoom => {
    AppLang.english: "Drawing Room",
    AppLang.urdu: "ڈرائنگ روم",
    AppLang.roman: "Drawing Room",
  }[_lang]!;

  String get diningRoom => {
    AppLang.english: "Dining Room",
    AppLang.urdu: "ڈائننگ روم",
    AppLang.roman: "Dining Room",
  }[_lang]!;

  String get kitchen => {
    AppLang.english: "Kitchen",
    AppLang.urdu: "باورچی خانہ",
    AppLang.roman: "Rasoi",
  }[_lang]!;

  String get storeRoom => {
    AppLang.english: "Store Room",
    AppLang.urdu: "اسٹور روم",
    AppLang.roman: "Store Room",
  }[_lang]!;

  String get bedroom => {
    AppLang.english: "Bedroom",
    AppLang.urdu: "کمرہ",
    AppLang.roman: "Kamra",
  }[_lang]!;

  String get bedrooms => {
    AppLang.english: "Bedrooms",
    AppLang.urdu: "کمرے",
    AppLang.roman: "Kamray",
  }[_lang]!;

  String get bathroom => {
    AppLang.english: "Bathroom",
    AppLang.urdu: "باتھ روم",
    AppLang.roman: "Bathroom",
  }[_lang]!;

  String get bathrooms => {
    AppLang.english: "Bathrooms",
    AppLang.urdu: "باتھ رومز",
    AppLang.roman: "Bathrooms",
  }[_lang]!;

  String get floorNum => {
    AppLang.english: "Floor",
    AppLang.urdu: "منزل",
    AppLang.roman: "Manzil",
  }[_lang]!;

  String get foundationFootings => {
    AppLang.english: "Foundation / Footings",
    AppLang.urdu: "بنیاد",
    AppLang.roman: "Bunyaad",
  }[_lang]!;

  String get smallHouseNote => {
    AppLang.english: "Small house — Studio/1 bedroom style",
    AppLang.urdu: "چھوٹا گھر — اسٹوڈیو/1 کمرہ",
    AppLang.roman: "Chhota ghar — Studio/1 Kamra",
  }[_lang]!;

  String get marla5Note => {
    AppLang.english: "5 Marla range — suitable for a small family",
    AppLang.urdu: "5 مرلہ — چھوٹے خاندان کے لیے",
    AppLang.roman: "5 Marla — chhote family ke liye",
  }[_lang]!;

  String get marla7Note => {
    AppLang.english: "5-7 Marla style — comfortable family layout",
    AppLang.urdu: "5-7 مرلہ — آرام دہ گھر",
    AppLang.roman: "5-7 Marla — aaraam dah ghar",
  }[_lang]!;

  String get marla10Note => {
    AppLang.english: "7-10 Marla range — spacious family home",
    AppLang.urdu: "7-10 مرلہ — کشادہ خاندانی گھر",
    AppLang.roman: "7-10 Marla — kushada family ghar",
  }[_lang]!;

  String get marla10UpperNote => {
    AppLang.english: "10 Marla style — upper-middle class home",
    AppLang.urdu: "10 مرلہ — اعلیٰ متوسط طبقہ",
    AppLang.roman: "10 Marla — upper-middle class ghar",
  }[_lang]!;

  String get kanalNote => {
    AppLang.english: "1 Kanal+ range — luxury family home",
    AppLang.urdu: "1 کنال+ — پرتعیش گھر",
    AppLang.roman: "1 Kanal+ — luxury ghar",
  }[_lang]!;



}