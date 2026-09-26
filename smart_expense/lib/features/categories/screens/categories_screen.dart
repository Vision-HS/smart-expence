import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../expenses/repositories/transaction_repository.dart';
import '../../transactions/screens/transaction_details_screen.dart';
import '../../transactions/screens/sms_detection_screen.dart';
import '../../settings/screens/profile_screen.dart';

class CategoryItemData {
  final String name;
  final String description;
  final int txns;
  final IconData icon;

  const CategoryItemData({
    required this.name,
    required this.description,
    required this.txns,
    required this.icon,
  });
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late List<CategoryItemData> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      const CategoryItemData(
        name: 'Food & Dining',
        description: 'Daily meals, coffee & takeouts',
        txns: 0,
        icon: Icons.restaurant_rounded,
      ),
      const CategoryItemData(
        name: 'Travel',
        description: 'Cabs, transit passes & flights',
        txns: 0,
        icon: Icons.directions_car_outlined,
      ),
      const CategoryItemData(
        name: 'Shopping',
        description: 'Clothing, gear & electronics',
        txns: 0,
        icon: Icons.shopping_bag_outlined,
      ),
      const CategoryItemData(
        name: 'Bills & Utilities',
        description: 'Electric, internet & subscriptions',
        txns: 0,
        icon: Icons.article_outlined,
      ),
      const CategoryItemData(
        name: 'Rent',
        description: 'Apartment lease & parking stall',
        txns: 0,
        icon: Icons.home_outlined,
      ),
      const CategoryItemData(
        name: 'Entertainment',
        description: 'Cinema, events & gaming',
        txns: 0,
        icon: Icons.movie_creation_outlined,
      ),
      const CategoryItemData(
        name: 'Health',
        description: 'Pharmacy, clinic & fitness',
        txns: 0,
        icon: Icons.show_chart_rounded,
      ),
      const CategoryItemData(
        name: 'Education',
        description: 'Courses, books & materials',
        txns: 0,
        icon: Icons.menu_book_outlined,
      ),
      const CategoryItemData(
        name: 'Groceries',
        description: 'Supermarket, bakery & produce',
        txns: 0,
        icon: Icons.storefront_outlined,
      ),
      const CategoryItemData(
        name: 'Fuel',
        description: 'Petrol, diesel & EV charging',
        txns: 0,
        icon: Icons.local_gas_station_outlined,
      ),
      const CategoryItemData(
        name: 'Other',
        description: 'Miscellaneous & uncategorized',
        txns: 0,
        icon: Icons.more_horiz_rounded,
      ),
    ];

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _loadCategoryCounts();
  }

  Future<void> _loadCategoryCounts() async {
    final updatedList = <CategoryItemData>[];
    for (final cat in _categories) {
      final count = await TransactionRepository.instance.getCategoryTransactionCount(cat.name);
      updatedList.add(CategoryItemData(
        name: cat.name,
        description: cat.description,
        txns: count,
        icon: cat.icon,
      ));
    }
    if (mounted) {
      setState(() {
        _categories = updatedList;
      });
    }
  }

  void _showCategoryTransactionsSheet(String categoryName) async {
    final txs = await TransactionRepository.instance.getTransactionsByCategory(categoryName);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text('${txs.length} transactions', style: const TextStyle(fontFamily: 'Inter', color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: txs.isEmpty
                    ? const Center(
                        child: Text('No recorded transactions in this category.', style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: txs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final item = txs[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(color: item.iconBgColor, borderRadius: BorderRadius.circular(10)),
                              child: Icon(item.icon, color: item.iconColor, size: 18),
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('${item.dateGroup} • ${item.paymentType}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            trailing: Text(
                              '${item.isIncome ? '+' : '-'}₹${item.amount.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: item.isIncome ? const Color(0xFF006C49) : const Color(0xFFBA1A1A),
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailsScreen(
                                    transaction: item,
                                    id: item.id,
                                  ),
                                ),
                              );
                              _loadCategoryCounts();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryItemData> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories.where((cat) {
      return cat.name.toLowerCase().contains(_searchQuery) ||
          cat.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  int get _totalTransactions {
    return _categories.fold(0, (sum, cat) => sum + cat.txns);
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;

    final icons = [
      Icons.fastfood_rounded,
      Icons.flight_takeoff_rounded,
      Icons.shopping_cart_rounded,
      Icons.fitness_center_rounded,
      Icons.work_rounded,
      Icons.pets_rounded,
      Icons.sports_esports_rounded,
      Icons.card_giftcard_rounded,
      Icons.receipt_long_rounded,
      Icons.savings_rounded,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add New Category',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Subscriptions, Pet Care',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Streaming, magazines & software',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Icon',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: icons.map((ic) {
                    final isSel = ic == selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedIcon = ic;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primaryContainer : const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(10),
                          border: isSel
                              ? Border.all(color: AppTheme.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          ic,
                          color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _categories.add(CategoryItemData(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? 'Custom category'
                                : descCtrl.text.trim(),
                            txns: 0,
                            icon: selectedIcon,
                          ));
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "${nameCtrl.text.trim()}" created'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Category',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  void _showCategoryDetails(CategoryItemData category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: AppTheme.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category.description,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recorded Transactions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${category.txns} txns',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCategoryTransactionsSheet(category.name);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'View Txns',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildPageHeader(context),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildMetricCards(),
              const SizedBox(height: 16),
              _buildCategoriesCard(filtered),
              const SizedBox(height: 16),
              _buildSmartRuleBanner(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // 1. Top Bar: "Settings" title + Notification icon + User Avatar
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.textPrimary,
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmsDetectionScreen()),
                );
              },
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Sub-Header: Back arrow + "Categories" title + "+ Add Category" button
  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
        ),
        const Text(
          'Categories',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showAddCategoryDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEDFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Add Category',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF767586),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF767586),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF767586),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // 4. Summary Metric Cards
  Widget _buildMetricCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Folders',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF767586),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_categories.length} Active',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFF006C49),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Logged This Mo.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF767586),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_totalTransactions Txns',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 5. Categories List Card
  Widget _buildCategoriesCard(List<CategoryItemData> list) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No matching categories found',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF767586),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(list.length, (index) {
          final cat = list[index];
          final isLast = index == list.length - 1;

          return Column(
            children: [
              _buildCategoryRow(cat),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 64,
                  endIndent: 14,
                  color: Color(0xFFF1F5F9),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCategoryRow(CategoryItemData category) {
    final txnText = category.txns == 1 ? '1 txn' : '${category.txns} txns';

    return InkWell(
      onTap: () => _showCategoryDetails(category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF767586),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                txnText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF767586),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // 6. Smart Rule Notice Banner
  Widget _buildSmartRuleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Smart rule active: Regular transfers labeled "Lease" or "Apt" automatically assign to ',
                children: [
                  TextSpan(
                    text: 'Rent.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Bottom Navigation Bar matching modern fintech engine
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.grid_view_rounded,
            label: 'Home',
            isActive: false,
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Expenses',
            isActive: false,
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Reports',
            isActive: false,
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            icon: Icons.tune_rounded,
            label: 'Settings',
            isActive: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFFEAEDFF),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

