import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AiWasteScanScreen extends StatefulWidget {
  const AiWasteScanScreen({super.key});

  @override
  State<AiWasteScanScreen> createState() => _AiWasteScanScreenState();
}

class _AiWasteScanScreenState extends State<AiWasteScanScreen> {
  XFile? _selectedImage;
  bool _isPickingImage = false;
  bool _isAnalyzing = false;
  String? _analysisResult;

  String _selectedCategory = 'اختر التصنيف (اختياري - أو التحليل التلقائي)';

  final List<String> _categories = [
    'اختر التصنيف (اختياري - أو التحليل التلقائي)',
    'نفايات إلكترونية',
    'بلاستيك',
    'معادن',
    'الأدوات التعليمية',
    'الأدوات المنزلية',
    'الزجاج والعبوات الزجاجية',
    'نفايات عضوية',
  ];

  String _getGuidanceForCategory(String cat) {
    if (cat.contains('إلكترونية')) {
      return '''
• القسم / التصنيف: قسم النفايات الإلكترونية والتقنية.
• شرح إعادة التدوير: يتم تفكيك الأجهزة واستخلاص المعادن الثمينة (كالذهب، الفضة، والنحاس) وفصل بطاريات الليثيوم بأمان معالجة كيميائية لمنع التلوث.
• ماذا تفعل بها والخطوات العملية: افصل الملحقات، لا ترمها في القمامة العادية، وسلمها لجهات التجميع لضمان عدم حدوث احتراق.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **شركة ريكلوبيكيا (Recyclobekia):** لتدوير المخلفات الإلكترونية (تطبيق الهاتف أو الموقع الإلكتروني).
  2. **تطبيق إي تدوير (e-Tadweer):** مخصص للتخلص الآمن والحصول على قسائم تخفيض.
  3. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: استرداد المعادن الثمينة، حماية البيئة، وكسب مكافآت خضراء.
''';
    } else if (cat.contains('بلاستيك')) {
      return '''
• القسم / التصنيف: قسم البوليمرات والعبوات البلاستيكية.
• شرح إعادة التدوير: يتم فرم البلاستيك وغسله وصهره لإنتاج حبيبات بلاستيكية جديدة تُستخدم في صناعة عبوات وخيوط نسيجية أخرى.
• ماذا تفعل بها والخطوات العملية: اغسل العبوة جيداً، أزل الأغطية، واضغطها لتوفير مساحة في صندوق التدوير.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **شركة باريق للتدوير (Bariq):** من أكبر مصانع تدوير البلاستيك (التواصل عبر الموقع الرسمي).
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: تقليل النفايات البلاستيكية في المدافن ودعم الاقتصاد الدائري.
''';
    } else if (cat.contains('معادن')) {
      return '''
• القسم / التصنيف: قسم المعادن والخردة الصلبة.
• شرح إعادة التدوير: تُصهر المعادن والألومنيوم في درجات حرارة عالية لإعادة تشكيلها إلى سبائك جديدة دون فقدان جودتها.
• ماذا تفعل بها والخطوات العملية: اشطف العلب المعدنية واضغطها لتقليل الحجم قبل تسليمها.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **مراكز تجميع الخردة والمخلفات الصلبة المعتمدة.**
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: توفير طاقة هائلة والحصول على عائد مادي أو نقاط مكافأة.
''';
    } else if (cat.contains('الأدوات التعليمية')) {
      return '''
• القسم / التصنيف: قسم الأدوات التعليمية والمستلزمات المدرسية.
• شرح إعادة التدوير: تُفرز الأوراق والكتب لإعادة لبها وتصنيع كرتون وورق معاد تدويره، بينما تُفرز الأقلام البلاستيكية لتدوير أجزائها الصلبة.
• ماذا تفعل بها والخطوات العملية: تبرع بالكتب السليمة للمكتبات، واجمع الأوراق للتجميع المنظم، وتخلص من الأقلام التالفة في نقاط التجميع المخصصة.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **مبادرات إعادة تدوير الكتب المدرسية والورق المحلية.**
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: نشر المعرفة، تقليل قطع الأشجار، والحفاظ على نظافة البيئة المدرسية والمكتبية.
''';
    } else if (cat.contains('الأدوات المنزلية')) {
      return '''
• القسم / التصنيف: قسم الأدوات المنزلية والمفروشات.
• شرح إعادة التدوير: تُصنف حسب الخامة (بلاستيك، معدن، أواني، أو أقمشة) لتوجيه كل جزء إلى المصنع المختص بإعادة صهره أو تدويره.
• ماذا تفعل بها والخطوات العملية: نظف الأدوات جيداً، تبرع بما هو صالح للاستخدام، وسلم التالف لمراكز إعادة التدوير الشاملة.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **جمعيات إعادة التدوير المدني ومراكز تجميع الأجهزة والأدوات المنزلية.**
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: إعادة استخدامها عبر التبرع أو تقليل الهدر المنزلي.
''';
    } else if (cat.contains('الزجاج')) {
      return '''
• القسم / التصنيف: قسم الزجاج والعبوات الزجاجية.
• شرح إعادة التدوير: يُغسل الزجاج، يُفرز حسب اللون، ثُم يُصهر في درجات حرارة عالية لإنتاج زجاجات وبرطمانات جديدة.
• ماذا تفعل بها والخطوات العملية: تخلص من الأغطية، اغسل الزجاجة جيداً، وتجنب كسرها في سلة النفايات العامة.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **مصانع الزجاج المحلية ومنافذ تجميع العبوات الزجاجية.**
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: إعادة تدوير غير محدودة دون فقدان نقاء الزجاج.
''';
    } else {
      return '''
• القسم / التصنيف: قسم النفايات العضوية والحيوية.
• شرح إعادة التدوير: تُخضع النفايات العضوية لعملية التسميد الحيوي (Composting) لتحويلها إلى سماد طبيعي غني للتربة.
• ماذا تفعل بها والخطوات العملية: اجمع بقايا الطعام والخضار بمعزل عن البلاستيك والمعادن، واستخدمها للزراعة أو سلمها لمشاريع السماد.
• شركات وجهات إعادة التدوير وطرق التواصل:
  1. **مبادرات الزراعة العضوية وإنتاج السماد المنزلي والزراعي.**
  2. **الخط الساخن لوزارة البيئة:** **19808**.
• كيف تستفيد منها: إنتاج سماد طبيعي مجاني للنباتات وتقليل انبعاثات المدافن الصحية.
''';
    }
  }

  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage || _isAnalyzing) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _analysisResult = null;
        });
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not open the camera. Check camera permissions.'
                : 'Could not open the image gallery.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _analyzeWaste() async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final bytes = await File(_selectedImage!.path).readAsBytes();
      final extension =
      _selectedImage!.path.split('.').last.toLowerCase();

      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
      );

      final prompt = Content.multi([
        TextPart(
          'أنت مساعد خبير في تصنيف وإدارة النفايات لتطبيق GreenPulse AI. '
              'قم بتحليل هذه الصورة بدقة شديدة وتعرف على نوع المنتج أو النفايات الظاهرة (سواء كانت نفايات إلكترونية مثل الباور بانك والبطاريات والأجهزة، أو بلاستيك، ورق، زجاج، معادن، أو نفايات عضوية). '
              'أجب باللغة العربية الفصحى الواضحة والمنظمة. '
              'استخدم العناوين التالية بدقة: '
              '1. نوع النفايات (حدد بدقة هل هي إلكترونية، بلاستيك، معدن، ورق، إلخ). '
              '2. الأدلة البصرية (ما الذي يظهر في الصورة ويدل على ذلك). '
              '3. إمكانية إعادة التدوير (هل هي قابلة للتدوير أم تحتوي على مواد خطرة مثل بطاريات الليثيوم). '
              '4. ماذا تفعل بها والخطوات العملية (كيف تتخلص منها أو تعيد استخدامها بشكل آمن). '
              '5. شركات وجهات إعادة التدوير وطرق التواصل (اقترح أسماء المصانع والشركات المتخصصة، واذكر **طرق التواصل معها** مثل الخط الساخن، التطبيقات مثل e-Tadweer أو Recyclobekia، المواقع الرسمية، أو أرقام الهواتف المعتمدة). '
              '6. كيف تستفيد منها (نقاط مكافآت، حماية البيئة، أو استبدال نقاط).',
        ),
        InlineDataPart(mimeType, bytes),
      ]);

      String? result;
      try {
        final response = await model.generateContent([prompt]);
        result = response.text?.trim();
      } catch (_) {
        result = _getGuidanceForCategory(_selectedCategory);
      }

      if (!mounted) return;

      setState(() {
        _analysisResult = (result == null || result.isEmpty)
            ? 'لم يرجع الذكاء الاصطناعي بنتيجة. يرجى تجربة صورة أخرى.'
            : result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _analysisResult = _getGuidanceForCategory(_selectedCategory);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'AI Waste Scan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover what your waste is made of.',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Take a photo or choose one from your gallery '
                    'for AI-powered identification.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF617267),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0EAE1),
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedImage == null)
                      Container(
                        width: double.infinity,
                        height: 230,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 76,
                              color: green,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Your image will appear here',
                              style: TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(_selectedImage!.path),
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: (_isPickingImage || _isAnalyzing)
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          side: const BorderSide(color: green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'اختر التصنيف (اختياري - أو اتركه للتحليل التلقائي)',
                        labelStyle: const TextStyle(fontSize: 13, color: darkGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FBF9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: (_isPickingImage || _isAnalyzing)
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose from Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          side: const BorderSide(color: green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                        (_selectedImage == null || _isAnalyzing)
                            ? null
                            : _analyzeWaste,
                        icon: _isAnalyzing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isAnalyzing
                              ? 'Analyzing Image...'
                              : 'Analyze Waste',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFFD5E1D8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_analysisResult != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE0EAE1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: green,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'AI Analysis Result',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        _analysisResult!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Color(0xFF34483B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F2E7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: darkGreen,
                      size: 26,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use a clear photo with good lighting '
                            'and keep the waste item visible.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}