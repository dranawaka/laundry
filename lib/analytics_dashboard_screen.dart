import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final int laundryId;
  
  const AnalyticsDashboardScreen({Key? key, required this.laundryId}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';

  // Data storage
  Map<String, dynamic> _summaryData = {};
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _orderData = {};
  Map<String, dynamic> _serviceData = {};
  Map<String, dynamic> _customerData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load all analytics data in parallel
      final results = await Future.wait([
        ApiService.getAnalyticsSummary(widget.laundryId),
        ApiService.getRevenueAnalytics(widget.laundryId),
        ApiService.getOrderAnalytics(widget.laundryId),
        ApiService.getServiceAnalytics(widget.laundryId),
        ApiService.getCustomerAnalytics(widget.laundryId),
      ]);

      setState(() {
        _summaryData = results[0]['success'] ? results[0]['data'] : {};
        _revenueData = results[1]['success'] ? results[1]['data'] : {};
        _orderData = results[2]['success'] ? results[2]['data'] : {};
        _serviceData = results[3]['success'] ? results[3]['data'] : {};
        _customerData = results[4]['success'] ? results[4]['data'] : {};
        _isLoading = false;
      });

      // Check for any errors
      final errors = results.where((result) => !result['success']).toList();
      if (errors.isNotEmpty) {
        setState(() {
          _errorMessage = 'Some data could not be loaded: ${errors.first['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
      Fluttertoast.showToast(
        msg: "Error loading analytics: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.dashboard)),
            Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Services', icon: Icon(Icons.local_laundry_service)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF424242)),
                  SizedBox(height: 16),
                  Text('Loading analytics data...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildRevenueTab(),
                    _buildOrdersTab(),
                    _buildServicesTab(),
                    _buildCustomersTab(),
                  ],
                ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summaryData.isEmpty) {
      return const Center(child: Text('No summary data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildPerformanceMetrics(),
            const SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Total Revenue',
          value: '\$${_formatNumber(_summaryData['totalRevenue'] ?? 0)}',
          subtitle: 'This month: \$${_formatNumber(_summaryData['revenueLastMonth'] ?? 0)}',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'Total Orders',
          value: '${_summaryData['totalOrders'] ?? 0}',
          subtitle: 'This month: ${_summaryData['ordersLastMonth'] ?? 0}',
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'Total Customers',
          value: '${_summaryData['totalCustomers'] ?? 0}',
          subtitle: 'New this month: ${_summaryData['newCustomersLastMonth'] ?? 0}',
          icon: Icons.people,
          color: Colors.purple,
        ),
        _buildMetricCard(
          title: 'Pending Orders',
          value: '${_summaryData['pendingOrders'] ?? 0}',
          subtitle: 'Completed: ${_summaryData['completedOrders'] ?? 0}',
          icon: Icons.pending,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Performance Indicators',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Most Popular Service', _summaryData['mostPopularService'] ?? 'N/A'),
            const Divider(height: 24),
            _buildMetricRow('Most Profitable Service', _summaryData['mostProfitableService'] ?? 'N/A'),
            const Divider(height: 24),
            _buildMetricRow('Average Order Value', '\$${_formatNumber(_summaryData['averageOrderValue'] ?? 0)}'),
            const Divider(height: 24),
            _buildMetricRow('Average Processing Time', _formatProcessingTime(_summaryData['averageProcessingTimeHours'] ?? 0)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF616161),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    if (_revenueData.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueCards(),
            const SizedBox(height: 20),
            _buildRevenueByService(),
            const SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Today',
          value: '\$${_formatNumber(_revenueData['revenueToday'] ?? 0)}',
          subtitle: 'Revenue today',
          icon: Icons.today,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'This Week',
          value: '\$${_formatNumber(_revenueData['revenueThisWeek'] ?? 0)}',
          subtitle: 'Revenue this week',
          icon: Icons.calendar_view_week,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'This Month',
          value: '\$${_formatNumber(_revenueData['revenueThisMonth'] ?? 0)}',
          subtitle: 'Revenue this month',
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
        _buildMetricCard(
          title: 'This Year',
          value: '\$${_formatNumber(_revenueData['revenueThisYear'] ?? 0)}',
          subtitle: 'Revenue this year',
          icon: Icons.calendar_today,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRevenueByService() {
    final serviceRevenue = _revenueData['revenueByService'] as Map<String, dynamic>? ?? {};
    
    if (serviceRevenue.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue by Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            ...serviceRevenue.entries.map((entry) => 
              _buildServiceRevenueItem(entry.key, entry.value.toDouble())
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRevenueItem(String serviceName, double revenue) {
    final totalRevenue = (_revenueData['totalRevenue'] ?? 0).toDouble();
    final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${_formatNumber(revenue)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Text(
            '${percentage.toStringAsFixed(1)}% of total revenue',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orderData.isEmpty) {
      return const Center(child: Text('No order data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderCards(),
            const SizedBox(height: 20),
            _buildOrdersByStatus(),
            const SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Today',
          value: '${_orderData['ordersToday'] ?? 0}',
          subtitle: 'Orders today',
          icon: Icons.today,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'This Week',
          value: '${_orderData['ordersThisWeek'] ?? 0}',
          subtitle: 'Orders this week',
          icon: Icons.calendar_view_week,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'This Month',
          value: '${_orderData['ordersThisMonth'] ?? 0}',
          subtitle: 'Orders this month',
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
        _buildMetricCard(
          title: 'Completion Rate',
          value: '${(_orderData['orderCompletionRate'] ?? 0).toStringAsFixed(1)}%',
          subtitle: 'Order completion rate',
          icon: Icons.check_circle,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildOrdersByStatus() {
    final ordersByStatus = _orderData['ordersByStatus'] as Map<String, dynamic>? ?? {};
    
    if (ordersByStatus.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders by Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            ...ordersByStatus.entries.map((entry) => 
              _buildOrderStatusItem(entry.key, entry.value)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusItem(String status, int count) {
    final statusColors = {
      'PLACED': const Color(0xFFFF9800),
      'IN_PROGRESS': const Color(0xFF2196F3),
      'READY_FOR_PICKUP': const Color(0xFF4CAF50),
      'OUT_FOR_DELIVERY': const Color(0xFF9C27B0),
      'COMPLETED': const Color(0xFF4CAF50),
      'CANCELED': const Color(0xFFF44336),
    };

    final statusLabels = {
      'PLACED': 'Placed',
      'IN_PROGRESS': 'In Progress',
      'READY_FOR_PICKUP': 'Ready for Pickup',
      'OUT_FOR_DELIVERY': 'Out for Delivery',
      'COMPLETED': 'Completed',
      'CANCELED': 'Canceled',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: statusColors[status] ?? Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusLabels[status] ?? status.toLowerCase().replaceAll('_', ' '),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (statusColors[status] ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: statusColors[status] ?? Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_serviceData.isEmpty) {
      return const Center(child: Text('No service data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildServicesByPopularity(),
            const SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildServicesByPopularity() {
    final servicesByPopularity = _serviceData['servicesByPopularity'] as List<dynamic>? ?? [];
    
    if (servicesByPopularity.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services by Popularity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            ...servicesByPopularity.map((service) => 
              _buildServiceItem(service)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(dynamic service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  service['serviceName'] ?? 'Unknown Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${service['orderCount'] ?? 0} orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Revenue: \$${_formatNumber(service['totalRevenue'] ?? 0)} • ${(service['percentageOfTotalOrders'] ?? 0).toStringAsFixed(1)}% of orders',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    if (_customerData.isEmpty) {
      return const Center(child: Text('No customer data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomerCards(),
            const SizedBox(height: 20),
            _buildTopCustomers(),
            const SizedBox(height: 16), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Total Customers',
          value: '${_customerData['totalCustomers'] ?? 0}',
          subtitle: 'Active customers',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'New This Month',
          value: '${_customerData['newCustomersThisMonth'] ?? 0}',
          subtitle: 'New customers',
          icon: Icons.person_add,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'Retention Rate',
          value: '${(_customerData['customerRetentionRate'] ?? 0).toStringAsFixed(1)}%',
          subtitle: 'Customer retention',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
        _buildMetricCard(
          title: 'Avg Revenue',
          value: '\$${_formatNumber(_customerData['averageRevenuePerCustomer'] ?? 0)}',
          subtitle: 'Per customer',
          icon: Icons.attach_money,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTopCustomers() {
    final topCustomers = _customerData['topCustomersByRevenue'] as List<dynamic>? ?? [];
    
    if (topCustomers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Customers by Revenue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            ...topCustomers.map((customer) => 
              _buildCustomerItem(customer)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(dynamic customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  customer['customerName'] ?? 'Unknown Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${_formatNumber(customer['totalSpent'] ?? 0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${customer['orderCount'] ?? 0} orders • Most ordered: ${customer['mostOrderedService'] ?? 'N/A'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = double.tryParse(number.toString()) ?? 0;
    if (value == value.floor()) {
      // If it's a whole number, don't show decimals
      final formatter = NumberFormat('#,##0');
      return formatter.format(value);
    } else {
      // If it has decimals, show up to 2 decimal places
      final formatter = NumberFormat('#,##0.##');
      return formatter.format(value);
    }
  }

  String _formatProcessingTime(dynamic hours) {
    if (hours == null) return 'N/A';
    final value = double.tryParse(hours.toString()) ?? 0;
    
    if (value == 0) return 'N/A';
    
    if (value < 1) {
      // Less than an hour, show minutes
      final minutes = (value * 60).round();
      return '$minutes min';
    } else if (value < 24) {
      // Less than a day, show hours
      if (value == value.floor()) {
        return '${value.toInt()} hrs';
      } else {
        return '${value.toStringAsFixed(1)} hrs';
      }
    } else {
      // More than a day, show days and hours
      final days = (value / 24).floor();
      final remainingHours = (value % 24).round();
      if (remainingHours == 0) {
        return '$days day${days > 1 ? 's' : ''}';
      } else {
        return '$days day${days > 1 ? 's' : ''} ${remainingHours}hrs';
      }
    }
  }
} 