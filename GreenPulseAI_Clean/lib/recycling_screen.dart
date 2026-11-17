import 'package:flutter/material.dart';
import 'collection_points_screen.dart';
import 'partner_company_detail_screen.dart';
import 'partner_models.dart';
import 'partner_service.dart';

class RecyclingScreen extends StatefulWidget {
  const RecyclingScreen({super.key});

  @override
  State<RecyclingScreen> createState() => _RecyclingScreenState();
}

class _RecyclingScreenState extends State<RecyclingScreen> {
  static const Color green = Color(0xFF16865C);
  static const Color darkGreen = Color(0xFF145A3A);
  static const Color background = Color(0xFFF4F8F3);

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedCategory = 'All';
  String _search = '';

  static const List<_WasteCategory> _categories = [
    _WasteCategory(
      name: 'Plastic',
      icon: Icons.local_drink_outlined,
      color: Color(0xFFDDF3E5),
      description: 'Plastic bottles, containers, and polymer packaging.',
      preparation: 'Rinse containers, remove caps, and flatten to save space.',
      examples: ['Water & soda bottles', 'Detergent containers', 'Plastic packaging'],
      tip: 'Check local recycling numbers (PET #1, HDPE #2) on the bottom.',
    ),
    _WasteCategory(
      name: 'Paper',
      icon: Icons.description_outlined,
      color: Color(0xFFFFF0D9),
      description: 'Paper products, cardboard, newspapers, and educational books.',
      preparation: 'Keep paper dry and separate from food or grease.',
      examples: ['Newspapers & magazines', 'Cardboard boxes', 'Books & office paper'],
      tip: 'Flatten cardboard boxes to optimize collection space.',
    ),
    _WasteCategory(
      name: 'Glass',
      icon: Icons.wine_bar_outlined,
      color: Color(0xFFDDEFFC),
      description: 'Glass bottles and food jars accepted locally.',
      preparation: 'Rinse thoroughly, remove metal/plastic lids, and handle safely.',
      examples: ['Glass beverage bottles', 'Food & sauce jars'],
      tip: '100% recyclable infinitely without losing quality.',
    ),
    _WasteCategory(
      name: 'Metal',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFFF0E5FC),
      description: 'Aluminium cans, steel food tins, and metal items.',
      preparation: 'Rinse food cans clean and crush beverage cans.',
      examples: ['Aluminium beverage cans', 'Tin food cans', 'Metal lids'],
      tip: 'Recycling aluminium saves up to 95% of energy compared to raw production.',
    ),
    _WasteCategory(
      name: 'Electronics',
      icon: Icons.devices_outlined,
      color: Color(0xFFFFE5E5),
      description: 'Electronic devices, power banks, chargers, and small appliances.',
      preparation: 'Use specialized e-waste collection services; do not place in trash.',
      examples: ['Power banks & chargers', 'Mobile phones & tablets', 'Small appliances'],
      tip: 'E-waste contains valuable metals as well as hazardous battery components.',
    ),
    _WasteCategory(
      name: 'Batteries',
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFFFFEAD5),
      description: 'Household alkaline, lithium, and rechargeable batteries.',
      preparation: 'Store safely in a dry container and take to a battery drop-off point.',
      examples: ['AA & AAA batteries', 'Lithium power bank cells', 'Rechargeable packs'],
      tip: 'Never incinerate or puncture used batteries.',
    ),
    _WasteCategory(
      name: 'Organic',
      icon: Icons.compost_rounded,
      color: Color(0xFFE7F0D7),
      description: 'Vegetable scraps, fruit peels, and compostable organic waste.',
      preparation: 'Keep separate from inorganic waste for composting.',
      examples: ['Fruit peels & scraps', 'Coffee grounds', 'Yard & leaf waste'],
      tip: 'Composting enriches soil and diverts organic waste from landfills.',
    ),
  ];

  List<_WasteCategory> get _filteredCategories {
    final query = _search.trim().toLowerCase();

    return _categories.where((category) {
      final matchesCategory = _selectedCategory == 'All' ||
          category.name == _selectedCategory;

      final searchableText = [
        category.name,
        category.description,
        category.preparation,
        category.tip,
        ...category.examples,
      ].join(' ').toLowerCase();

      return matchesCategory &&
          (query.isEmpty || searchableText.contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategoryDetails(_WasteCategory category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          category.icon,
                          size: 32,
                          color: green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    category.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF617267),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Examples',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...category.examples.map(
                    (example) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: green,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              example,
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBox(
                    icon: Icons.cleaning_services_outlined,
                    title: 'How to prepare',
                    description: category.preparation,
                  ),
                  const SizedBox(height: 12),
                  _InfoBox(
                    icon: Icons.lightbulb_outline,
                    title: 'Recycling tip',
                    description: category.tip,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'الشركات الشريكة المعتمدة لاستلام هذا النوع:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<PartnerCompany>>(
                    future: PartnerService.instance.getApprovedCompaniesForWasteType(category.name),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: green));
                      }
                      final companies = snapshot.data ?? [];
                      if (companies.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('لا توجد شركات شريكة معتمدة لهذا النوع حالياً.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: companies.length,
                        itemBuilder: (context, index) {
                          final comp = companies[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8F3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2EAE3)),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFDCF3E5),
                                child: Icon(Icons.business_rounded, color: green),
                              ),
                              title: Text(comp.companyName, style: const TextStyle(fontWeight: FontWeight.bold, color: darkGreen)),
                              subtitle: Text(comp.activityDescription, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: green),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartnerCompanyDetailScreen(company: comp),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CollectionPointsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_outlined),
                      label: Text(
                        'Find Nearby ${category.name} Collection Points',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'Recycling',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [green, Color(0xFF0D6948)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.recycling_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Give waste a\nsecond life.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Explore waste types, learn how to sort them, '
                            'and make more informed recycling choices.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Explore waste types',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Select a category to learn how to prepare it.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718276),
                      ),
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search waste types...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: green,
                        ),
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _search = '';
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EAE3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2EAE3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          'All',
                          ..._categories.map((item) => item.name),
                        ].map((name) {
                          final selected = name == _selectedCategory;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(name),
                              selected: selected,
                              showCheckmark: false,
                              selectedColor: darkGreen,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : darkGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = name;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recycling guide',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                        ),
                        Text(
                          '${categories.length} types',
                          style: const TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (categories.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No matching waste types found.',
                      style: TextStyle(color: Color(0xFF718276)),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19),
                            onTap: () => _showCategoryDetails(category),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: const Color(0xFFE2EAE3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: category.color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      category.icon,
                                      size: 29,
                                      color: green,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: darkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          category.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: Color(0xFF718276),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WasteCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String preparation;
  final List<String> examples;
  final String tip;

  const _WasteCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.preparation,
    required this.examples,
    required this.tip,
  });
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF16865C), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF145A3A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 13,
                    color: Color(0xFF617267),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
