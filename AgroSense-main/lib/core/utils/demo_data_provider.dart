import 'dart:convert';
import '../../data/local/database/app_database.dart';

/// Provides demo/fake data for prototype demonstration when using developer login
class DemoDataProvider {
  // Demo Schemes Data
  static List<Scheme> getDemoSchemes({String language = 'en'}) {
    final schemes = [
      Scheme(
        id: 'demo_scheme_1',
        title: language == 'hi' 
            ? 'प्रधानमंत्री किसान सम्मान निधि (PM-KISAN)'
            : 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
        description: language == 'hi'
            ? 'छोटे और सीमांत किसानों को वित्तीय सहायता प्रदान करने के लिए केंद्र सरकार की योजना। पात्र किसानों को ₹6,000 प्रति वर्ष तीन समान किस्तों में मिलते हैं।'
            : 'Central government scheme to provide financial assistance to small and marginal farmers. Eligible farmers receive ₹6,000 per year in three equal installments.',
        benefits: language == 'hi'
            ? '₹6,000 प्रति वर्ष सीधे बैंक खाते में'
            : '₹6,000 per year directly to bank account',
        eligibilityCriteria: jsonEncode({
          'Land Ownership': language == 'hi' ? '2 हेक्टेयर तक' : 'Up to 2 hectares',
          'Category': language == 'hi' ? 'सभी किसान' : 'All farmers',
          'Documents': language == 'hi' ? 'आधार, बैंक विवरण, भूमि रिकॉर्ड' : 'Aadhaar, Bank details, Land records',
        }),
        applyUrl: 'https://pmkisan.gov.in',
        language: language,
        cachedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Scheme(
        id: 'demo_scheme_2',
        title: language == 'hi'
            ? 'प्रधानमंत्री फसल बीमा योजना (PMFBY)'
            : 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
        description: language == 'hi'
            ? 'फसल के नुकसान के खिलाफ बीमा योजना। प्राकृतिक आपदाओं, कीटों और बीमारियों से फसल क्षति के लिए व्यापक कवरेज।'
            : 'Crop insurance scheme against crop losses. Comprehensive coverage for crop damage due to natural calamities, pests, and diseases.',
        benefits: language == 'hi'
            ? 'फसल नुकसान पर 100% तक मुआवजा'
            : 'Up to 100% compensation for crop loss',
        eligibilityCriteria: jsonEncode({
          'Farmers': language == 'hi' ? 'सभी किसान (मालिक और किरायेदार)' : 'All farmers (owner & tenant)',
          'Crops': language == 'hi' ? 'खाद्य फसलें, तिलहन, वाणिज्यिक फसलें' : 'Food crops, Oilseeds, Commercial crops',
          'Premium': language == 'hi' ? 'खरीफ: 2%, रबी: 1.5%' : 'Kharif: 2%, Rabi: 1.5%',
        }),
        applyUrl: 'https://pmfby.gov.in',
        language: language,
        cachedAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Scheme(
        id: 'demo_scheme_3',
        title: language == 'hi'
            ? 'किसान क्रेडिट कार्ड (KCC)'
            : 'Kisan Credit Card (KCC)',
        description: language == 'hi'
            ? 'किसानों को कृषि और संबंधित गतिविधियों के लिए समय पर और पर्याप्त ऋण सुविधा। कम ब्याज दरों पर आसान ऋण।'
            : 'Timely and adequate credit facility for farmers for agriculture and allied activities. Easy loans at lower interest rates.',
        benefits: language == 'hi'
            ? '₹3 लाख तक का ऋण @ 4% ब्याज'
            : 'Loan up to ₹3 lakh @ 4% interest',
        eligibilityCriteria: jsonEncode({
          'Eligibility': language == 'hi' ? 'सभी किसान' : 'All farmers',
          'Collateral': language == 'hi' ? '₹1.6 लाख तक के लिए नहीं' : 'Not required up to ₹1.6 lakh',
          'Repayment': language == 'hi' ? 'फसल कटाई के बाद लचीला' : 'Flexible post-harvest',
        }),
        applyUrl: 'https://kcc.gov.in',
        language: language,
        cachedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Scheme(
        id: 'demo_scheme_4',
        title: language == 'hi'
            ? 'मृदा स्वास्थ्य कार्ड योजना'
            : 'Soil Health Card Scheme',
        description: language == 'hi'
            ? 'किसानों को मिट्टी की पोषक स्थिति और उर्वरक की सिफारिशों के साथ मृदा स्वास्थ्य कार्ड जारी करना। मिट्टी की गुणवत्ता में सुधार और उर्वरक की लागत कम करें।'
            : 'Issuing soil health cards to farmers with nutrient status and fertilizer recommendations. Improve soil quality and reduce fertilizer costs.',
        benefits: language == 'hi'
            ? 'मुफ्त मिट्टी परीक्षण और उर्वरक सलाह'
            : 'Free soil testing and fertilizer advice',
        eligibilityCriteria: jsonEncode({
          'Target': language == 'hi' ? 'सभी किसान' : 'All farmers',
          'Frequency': language == 'hi' ? 'हर 3 साल' : 'Every 3 years',
          'Cost': language == 'hi' ? 'निःशुल्क' : 'Free',
        }),
        applyUrl: 'https://soilhealth.dac.gov.in',
        language: language,
        cachedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Scheme(
        id: 'demo_scheme_5',
        title: language == 'hi'
            ? 'राष्ट्रीय कृषि बाजार (e-NAM)'
            : 'National Agriculture Market (e-NAM)',
        description: language == 'hi'
            ? 'ऑनलाइन ट्रेडिंग प्लेटफॉर्म जो कृषि उपज के लिए एकीकृत राष्ट्रीय बाजार बनाता है। किसानों को बेहतर मूल्य खोज और पारदर्शिता।'
            : 'Online trading platform creating unified national market for agricultural produce. Better price discovery and transparency for farmers.',
        benefits: language == 'hi'
            ? 'बेहतर कीमतें, कम मध्यस्थ, ऑनलाइन भुगतान'
            : 'Better prices, Fewer middlemen, Online payment',
        eligibilityCriteria: jsonEncode({
          'Registration': language == 'hi' ? 'ऑनलाइन पंजीकरण आवश्यक' : 'Online registration required',
          'Documents': language == 'hi' ? 'आधार, बैंक खाता' : 'Aadhaar, Bank account',
          'Access': language == 'hi' ? 'मोबाइल ऐप या वेब' : 'Mobile app or web',
        }),
        applyUrl: 'https://www.enam.gov.in',
        language: language,
        cachedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    return schemes;
  }

  // Demo AI Response for "What should I plant?"
  static String getDemoAIPlantingAdvice({String language = 'en'}) {
    if (language == 'hi') {
      return '''🌾 फसल सलाह - जनवरी/फरवरी

वर्तमान मौसम की स्थिति और मिट्टी के स्वास्थ्य के आधार पर, यहां मेरी सिफारिशें हैं:

**रबी फसलें (सर्दी की फसलें):**
1. **गेहूं** - अभी भी रोपण के लिए उपयुक्त समय
   - किस्में: HD-2967, PBW-343, WH-1105
   - बीज दर: 100 किग्रा/हेक्टेयर
   - उर्वरक: 120:60:40 NPK
   - सिंचाई: CRI, late jointing, flowering, दाना भरने के समय

2. **चना (Chana/Chickpea)**
   - किस्में: Pusa-256, JG-11, Vijay
   - बीज दर: 75-80 किग्रा/हेक्टेयर
   - फसल अवधि: 100-120 दिन

3. **सरसों (Mustard)**
   - किस्में: Pusa Bold, RH-30, Varuna
   - बीज दर: 5-6 किग्रा/हेक्टेयर
   - उच्च तेल सामग्री और अच्छा बाजार मूल्य

**सब्जियाँ:**
- टमाटर, बैंगन, मिर्च की पौध
- मटर, फूलगोभी, पत्तागोभी

**सिफारिशें:**
✓ मिट्टी परीक्षण करें
✓ बीज उपचार करें
✓ उचित जल निकासी सुनिश्चित करें
✓ एकीकृत कीट प्रबंधन का उपयोग करें

क्या आप किसी विशिष्ट फसल के बारे में अधिक जानकारी चाहते हैं?''';
    } else {
      return '''🌾 Crop Advisory - January/February Season

Based on current weather conditions and soil health, here are my recommendations:

**Rabi Crops (Winter Crops):**
1. **Wheat** - Still optimal time for planting
   - Varieties: HD-2967, PBW-343, WH-1105
   - Seed rate: 100 kg/hectare
   - Fertilizer: 120:60:40 NPK
   - Irrigation: At CRI, late jointing, flowering, grain filling stages

2. **Chickpea (Chana)**
   - Varieties: Pusa-256, JG-11, Vijay
   - Seed rate: 75-80 kg/hectare
   - Crop duration: 100-120 days

3. **Mustard**
   - Varieties: Pusa Bold, RH-30, Varuna
   - Seed rate: 5-6 kg/hectare
   - High oil content and good market price

**Vegetables:**
- Tomato, Brinjal, Chili seedlings
- Peas, Cauliflower, Cabbage

**Recommendations:**
✓ Conduct soil test before sowing
✓ Use treated seeds
✓ Ensure proper drainage
✓ Implement integrated pest management

Would you like more details about any specific crop?''';
    }
  }

  // Demo Diary Entries - Using correct schema fields
  static List<DiaryEntry> getDemoDiaryEntries() {
    return [
      DiaryEntry(
        id: 'demo_diary_1',
        userId: 'demo_user',
        fieldId: 'demo_field_1',
        title: 'Wheat Field Irrigation',
        content: 'Applied first irrigation at CRI stage. Checked for weed growth. Plants looking healthy with good tillering.',
        imagePaths: null,
        category: 'observation',
        amount: null,
        entryDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isSynced: false,
        isDeleted: false,
      ),
      DiaryEntry(
        id: 'demo_diary_2',
        userId: 'demo_user',
        fieldId: 'demo_field_2',
        title: 'Mustard Fertilizer Application',
        content: 'Applied urea @ 50 kg/acre. Soil moisture good. Observed some aphid infestation, will monitor closely.',
        imagePaths: null,
        category: 'expense',
        amount: 850.0,
        entryDate: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        isSynced: false,
        isDeleted: false,
      ),
      DiaryEntry(
        id: 'demo_diary_3',
        userId: 'demo_user',
        fieldId: 'demo_field_3',
        title: 'Tomato Pest Control',
        content: 'Sprayed neem-based pesticide for whitefly control. Removed diseased leaves. Added organic manure around plants.',
        imagePaths: null,
        category: 'observation',
        amount: null,
        entryDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isSynced: false,
        isDeleted: false,
      ),
      DiaryEntry(
        id: 'demo_diary_4',
        userId: 'demo_user',
        fieldId: 'demo_field_1',
        title: 'Wheat Germination Check',
        content: 'Checked for proper germination. 90% germination rate achieved. Minor weed growth observed, will remove manually.',
        imagePaths: null,
        category: 'observation',
        amount: null,
        entryDate: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        isSynced: false,
        isDeleted: false,
      ),
      DiaryEntry(
        id: 'demo_diary_5',
        userId: 'demo_user',
        fieldId: null,
        title: 'Chickpea Sowing Completed',
        content: 'Completed sowing of Pusa-256 variety. Used treated seeds. Applied basal fertilizer DAP @ 50 kg/acre.',
        imagePaths: null,
        category: 'expense',
        amount: 2400.0,
        entryDate: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        isSynced: false,
        isDeleted: false,
      ),
    ];
  }

  // Demo Fields - Using correct schema fields
  static List<Field> getDemoFields() {
    return [
      Field(
        id: 'demo_field_1',
        userId: 'demo_user',
        name: 'North Field',
        coordinates: jsonEncode([
          {'lat': 28.7041, 'lng': 77.1025},
          {'lat': 28.7051, 'lng': 77.1035},
          {'lat': 28.7061, 'lng': 77.1025},
          {'lat': 28.7051, 'lng': 77.1015},
        ]),
        area: 2.5,
        cropType: 'Wheat',
        soilType: 'Loamy',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
        isSynced: false,
        isDeleted: false,
      ),
      Field(
        id: 'demo_field_2',
        userId: 'demo_user',
        name: 'South Field',
        coordinates: jsonEncode([
          {'lat': 28.7031, 'lng': 77.1025},
          {'lat': 28.7041, 'lng': 77.1035},
          {'lat': 28.7051, 'lng': 77.1025},
          {'lat': 28.7041, 'lng': 77.1015},
        ]),
        area: 1.8,
        cropType: 'Mustard',
        soilType: 'Sandy Loam',
        createdAt: DateTime.now().subtract(const Duration(days: 65)),
        updatedAt: DateTime.now(),
        isSynced: false,
        isDeleted: false,
      ),
      Field(
        id: 'demo_field_3',
        userId: 'demo_user',
        name: 'East Vegetable Plot',
        coordinates: jsonEncode([
          {'lat': 28.7021, 'lng': 77.1035},
          {'lat': 28.7031, 'lng': 77.1045},
          {'lat': 28.7041, 'lng': 77.1035},
          {'lat': 28.7031, 'lng': 77.1025},
        ]),
        area: 0.5,
        cropType: 'Mixed Vegetables',
        soilType: 'Clay Loam',
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
        updatedAt: DateTime.now(),
        isSynced: false,
        isDeleted: false,
      ),
    ];
  }

  // Demo Community Posts
  static List<Map<String, dynamic>> getDemoCommunityPosts({String language = 'en'}) {
    if (language == 'hi') {
      return [
        {
          'id': 'demo_post_1',
          'userId': 'demo_user_1',
          'userName': 'राजेश कुमार',
          'userAvatar': null,
          'title': 'गेहूं में कीट प्रबंधन',
          'content': 'इस साल माहू (Aphid) का प्रकोप बढ़ रहा है। मैं नीम-आधारित कीटनाशक का उपयोग कर रहा हूं और अच्छे परिणाम मिल रहे हैं। क्या किसी और के पास सुझाव हैं?',
          'imageUrl': null,
          'likes': 24,
          'comments': 8,
          'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
          'isLiked': false,
        },
        {
          'id': 'demo_post_2',
          'userId': 'demo_user_2',
          'userName': 'सुरेश पटेल',
          'userAvatar': null,
          'title': 'सरसों की अच्छी कीमत',
          'content': 'आज मंडी में सरसों ₹6,800/क्विंटल मिल रही है। मैं अगले हफ्ते तक इंतजार करूंगा, कीमत और बढ़ने की उम्मीद है।',
          'imageUrl': null,
          'likes': 42,
          'comments': 15,
          'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
          'isLiked': true,
        },
        {
          'id': 'demo_post_3',
          'userId': 'demo_user_3',
          'userName': 'विक्रम सिंह',
          'userAvatar': null,
          'title': 'ड्रिप सिंचाई का अनुभव',
          'content': 'मैंने इस साल ड्रिप सिंचाई लगाई है। पानी की 40% बचत हो रही है और फसल भी बेहतर है। सरकार की 50% सब्सिडी भी मिली। सभी को सलाह दूंगा।',
          'imageUrl': null,
          'likes': 67,
          'comments': 23,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'isLiked': false,
        },
        {
          'id': 'demo_post_4',
          'userId': 'demo_user_4',
          'userName': 'अनिल वर्मा',
          'userAvatar': null,
          'title': 'जैविक खाद का उपयोग',
          'content': 'मैं पिछले 2 सालों से जैविक खाद का उपयोग कर रहा हूं। मिट्टी की गुणवत्ता में काफी सुधार आया है। रासायनिक उर्वरक कम लग रहे हैं।',
          'imageUrl': null,
          'likes': 38,
          'comments': 12,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'isLiked': true,
        },
      ];
    } else {
      return [
        {
          'id': 'demo_post_1',
          'userId': 'demo_user_1',
          'userName': 'Rajesh Kumar',
          'userAvatar': null,
          'title': 'Pest Management in Wheat',
          'content': 'This year, aphid infestation is increasing in wheat crops. I\'m using neem-based pesticide and getting good results. Anyone else has suggestions?',
          'imageUrl': null,
          'likes': 24,
          'comments': 8,
          'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
          'isLiked': false,
        },
        {
          'id': 'demo_post_2',
          'userId': 'demo_user_2',
          'userName': 'Suresh Patel',
          'userAvatar': null,
          'title': 'Good Mustard Prices Today',
          'content': 'Mustard is fetching ₹6,800/quintal in the mandi today. I\'ll wait till next week, expecting prices to rise further.',
          'imageUrl': null,
          'likes': 42,
          'comments': 15,
          'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
          'isLiked': true,
        },
        {
          'id': 'demo_post_3',
          'userId': 'demo_user_3',
          'userName': 'Vikram Singh',
          'userAvatar': null,
          'title': 'Drip Irrigation Experience',
          'content': 'Installed drip irrigation this year. Saving 40% water and crop quality is better. Got 50% government subsidy. Highly recommend to all.',
          'imageUrl': null,
          'likes': 67,
          'comments': 23,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'isLiked': false,
        },
        {
          'id': 'demo_post_4',
          'userId': 'demo_user_4',
          'userName': 'Anil Verma',
          'userAvatar': null,
          'title': 'Organic Manure Benefits',
          'content': 'Using organic manure for past 2 years. Soil quality has improved significantly. Chemical fertilizer requirement has reduced.',
          'imageUrl': null,
          'likes': 38,
          'comments': 12,
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'isLiked': true,
        },
      ];
    }
  }

  // Check if we're in demo mode (developer login used)
  static bool isDemoMode() {
    // In a real app, you'd check if user authenticated through developer login
    // For now, we'll check if developer mode is enabled
    return true; // Always return demo data when isDeveloperMode is true
  }
}