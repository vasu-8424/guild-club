class AdminStatsModel {
  final double totalRevenue;
  final int totalOrders;
  final int activeProducts;
  final int registeredUsers;
  final List<double> weeklySales;
  final List<double> monthlyRevenue;

  const AdminStatsModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeProducts,
    required this.registeredUsers,
    required this.weeklySales,
    required this.monthlyRevenue,
  });
}
