import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../models/admin_stats_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(adminStatsProvider);
    final products = ref.watch(productsProvider);
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Row(
            children: [
              // Desktop/Web Sidebar Navigation
              Container(
                width: 240,
                color: Colors.white.withOpacity(0.85),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: ToyVerseTheme.primaryPurple, size: 28),
                          const SizedBox(width: 8),
                          Text('Guild Club Admin', style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Divider(),
                    _buildSidebarItem(0, 'Dashboard Analytics', Icons.dashboard_rounded),
                    _buildSidebarItem(1, 'Product Catalog (${products.length})', Icons.inventory_2_rounded),
                    _buildSidebarItem(2, 'Orders (${orders.length})', Icons.local_shipping_rounded),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.primaryRoyalBlue),
                      title: Text('Back to Store', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Main Dashboard Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      // TAB 0: Analytics Overview & FL Chart
                      _buildAnalyticsTab(stats),

                      // TAB 1: Product Inventory CRUD Table
                      _buildProductsTab(products),

                      // TAB 2: Orders Processing Center
                      _buildOrdersTab(orders),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? ToyVerseTheme.primaryOrange : ToyVerseTheme.textMuted),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? ToyVerseTheme.primaryOrange : ToyVerseTheme.textDark,
        ),
      ),
      onTap: () => setState(() => _selectedTab = index),
    );
  }

  Widget _buildAnalyticsTab(AdminStatsModel stats) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Executive Analytics Dashboard 📊', style: AppTypography.displayMedium.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 4 Metric Stats Cards Grid
          Row(
            children: [
              _buildStatCard('Total Sales Revenue', '₹${stats.totalRevenue.toInt()}', Icons.attach_money_rounded, ToyVerseTheme.primaryMintGreen),
              _buildStatCard('Total Orders', '${stats.totalOrders}', Icons.shopping_bag_rounded, ToyVerseTheme.primaryRoyalBlue),
              _buildStatCard('Active Products', '${stats.activeProducts}', Icons.toys_rounded, ToyVerseTheme.primaryOrange),
              _buildStatCard('Registered Parents', '${stats.registeredUsers}', Icons.people_rounded, ToyVerseTheme.primaryPurple),
            ],
          ),

          const SizedBox(height: 24),

          // Revenue Chart using FL Chart
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue Growth (INR)', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 240000),
                            FlSpot(1, 290000),
                            FlSpot(2, 310000),
                            FlSpot(3, 380000),
                            FlSpot(4, 428900),
                          ],
                          isCurved: true,
                          color: ToyVerseTheme.primaryOrange,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: ToyVerseTheme.primaryOrange.withOpacity(0.15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
              const SizedBox(height: 12),
              Text(value, style: AppTypography.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab(List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product Inventory Manager 🧸', style: AppTypography.displayMedium.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryOrange),
              onPressed: () {
                _showAddProductDialog(context);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add New Product', style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: CircleAvatar(backgroundImage: NetworkImage(p.imageUrls.first)),
                  title: Text(p.title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Category: ${p.categorySlug} • Stock: ${p.stockQuantity}'),
                  trailing: Text('₹${p.price.toInt()}', style: AppTypography.priceNumeral.copyWith(color: ToyVerseTheme.primaryOrange)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(List<OrderModel> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Processing & Dispatch 📦',
                  style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Change stage here to trigger live Supabase Realtime updates on customer tracking screen.',
                  style: AppTypography.bodySmall.copyWith(color: ToyVerseTheme.textMuted),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ToyVerseTheme.primaryNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${orders.length} Active Orders',
                style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: orders.isEmpty
              ? GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: ToyVerseTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('No active orders in processing queue', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      o.orderNumber,
                                      style: AppTypography.displayMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    SparkleBadge(
                                      label: o.status.label.toUpperCase(),
                                      backgroundColor: o.status == OrderStatus.delivered
                                          ? ToyVerseTheme.primaryMintGreen
                                          : o.status == OrderStatus.outForDelivery
                                              ? ToyVerseTheme.primaryOrange
                                              : ToyVerseTheme.primaryRoyalBlue,
                                      fontSize: 8.5,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Open Tracking Screen',
                                      icon: const Icon(Icons.open_in_new_rounded, size: 18, color: ToyVerseTheme.primaryRoyalBlue),
                                      onPressed: () => context.push('/tracking/${o.id}'),
                                    ),
                                    PopupMenuButton<OrderStatus>(
                                      icon: const Icon(Icons.more_vert_rounded, color: ToyVerseTheme.textDark),
                                      tooltip: 'Update Order Stage',
                                      onSelected: (newStatus) async {
                                        await ref.read(ordersProvider.notifier).updateOrderStatus(o.id, newStatus);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Order ${o.orderNumber} updated to ${newStatus.label} ⚡'),
                                              backgroundColor: ToyVerseTheme.primaryNavy,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        for (final s in OrderStatus.values)
                                          PopupMenuItem(
                                            value: s,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  s == o.status ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                                  size: 16,
                                                  color: s == o.status ? ToyVerseTheme.primaryRed : Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  s.label,
                                                  style: TextStyle(
                                                    fontWeight: s == o.status ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Total: ₹${o.totalAmount.toInt()} (${o.items.length} items) • ${o.deliveryAddress}',
                              style: AppTypography.bodySmall.copyWith(color: ToyVerseTheme.textMuted, fontSize: 11.5),
                            ),
                            const SizedBox(height: 10),
                            // Quick Stage Advancement Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final stage in [
                                    OrderStatus.placed,
                                    OrderStatus.preparing,
                                    OrderStatus.dispatched,
                                    OrderStatus.outForDelivery,
                                    OrderStatus.delivered,
                                  ]) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        backgroundColor: o.status == stage
                                            ? ToyVerseTheme.primaryNavy
                                            : Colors.grey.shade100,
                                        label: Text(
                                          stage.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: o.status == stage ? FontWeight.bold : FontWeight.w500,
                                            color: o.status == stage ? Colors.white : ToyVerseTheme.textDark,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await ref.read(ordersProvider.notifier).updateOrderStatus(o.id, stage);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Order ${o.orderNumber} advanced to ${stage.label} ⚡'),
                                                backgroundColor: ToyVerseTheme.primaryNavy,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final titleController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add New Toy Product 🧸', style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Toy Title')),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (INR)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryOrange),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newProd = ProductModel(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text,
                    subtitle: 'Newly Added Toy',
                    description: 'Created via Guild Club Admin Dashboard.',
                    price: double.tryParse(priceController.text) ?? 999.0,
                    originalPrice: 1299.0,
                    discountPercentage: 20,
                    rating: 5.0,
                    reviewCount: 1,
                    stockQuantity: 50,
                    categorySlug: 'stem',
                    brandName: 'Guild Club Prime',
                    minAge: 3,
                    maxAge: 10,
                    material: 'Eco Wood',
                    educationalType: 'STEM',
                    imageUrls: ['https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop'],
                  );
                  ref.read(productsProvider.notifier).addProduct(newProd);
                  Navigator.pop(context);
                }
              },
              child: Text('Save Product', style: AppTypography.bodyLarge.copyWith(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
