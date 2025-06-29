import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? userRole;
  int? userId;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final userData = await ApiService.getCurrentUser();
      final idString = userData['id'];
      setState(() {
        userRole = userData['role'];
        userId = int.tryParse(idString ?? '');
      });

      if (userId == null) {
        throw Exception('Invalid user ID');
      }

      Map<String, dynamic> result;
      if (userRole?.toUpperCase() == 'LAUNDRY') {
        result = await ApiService.getLaundryOrders(userId!);
      } else {
        result = await ApiService.getCustomerOrders(userId!);
      }

      setState(() {
        isLoading = false;
        if (result['success']) {
          orders = result['data'] ?? [];
        } else {
          orders = [];
          Fluttertoast.showToast(
            msg: result['message'],
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        orders = [];
      });
      Fluttertoast.showToast(
        msg: "Error loading orders: "+e.toString(),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  String _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return '#FFA500'; // Orange
      case 'IN_PROGRESS':
        return '#2196F3'; // Blue
      case 'READY_FOR_PICKUP':
        return '#4CAF50'; // Green
      case 'OUT_FOR_DELIVERY':
        return '#9C27B0'; // Purple
      case 'COMPLETED':
        return '#4CAF50'; // Green
      case 'CANCELED':
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return 'Placed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELED':
        return 'Canceled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Orders',
          style: TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF424242),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Color(0xFF424242),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Active Orders'),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF424242),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${orders.where((order) {
                        final status = order['status']?.toString().toUpperCase() ?? '';
                        return status != 'COMPLETED' && status != 'CANCELED';
                      }).length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Completed Orders'),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF424242),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${orders.where((order) {
                        final status = order['status']?.toString().toUpperCase() ?? '';
                        return status == 'COMPLETED' || status == 'CANCELED';
                      }).length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF424242)),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF424242),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrders(),
                _buildCompletedOrders(),
              ],
            ),
    );
  }

  Widget _buildActiveOrders() {
    final activeOrders = orders.where((order) {
      final status = order['status']?.toString().toUpperCase() ?? '';
      return status != 'COMPLETED' && status != 'CANCELED';
    }).toList();

    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pending_actions,
                size: 40,
                color: Color(0xFF424242),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No active orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              userRole?.toUpperCase() == 'LAUNDRY' 
                  ? 'No pending orders from customers'
                  : 'You have no active orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: Column(
        children: [
          // Summary section
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${activeOrders.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      Text(
                        'Active Orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${activeOrders.fold<double>(0, (sum, order) => sum + (order['totalPrice'] ?? 0.0)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedOrders() {
    final completedOrders = orders.where((order) {
      final status = order['status']?.toString().toUpperCase() ?? '';
      return status == 'COMPLETED' || status == 'CANCELED';
    }).toList();

    if (completedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 40,
                color: Color(0xFF424242),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No completed orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              userRole?.toUpperCase() == 'LAUNDRY' 
                  ? 'No completed orders from customers'
                  : 'You have no completed orders yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final completedCount = completedOrders.where((order) {
      final status = order['status']?.toString().toUpperCase() ?? '';
      return status == 'COMPLETED';
    }).length;

    final canceledCount = completedOrders.where((order) {
      final status = order['status']?.toString().toUpperCase() ?? '';
      return status == 'CANCELED';
    }).length;

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: Column(
        children: [
          // Summary section
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$completedCount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$canceledCount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'Canceled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${completedOrders.fold<double>(0, (sum, order) => sum + (order['totalPrice'] ?? 0.0)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF424242),
                        ),
                      ),
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final order = completedOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusColor = _getStatusColor(order['status'] ?? '');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['orderId']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(statusColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(order['status'] ?? ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(int.parse(statusColor.replaceAll('#', '0xFF'))),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (userRole?.toUpperCase() == 'LAUNDRY')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${order['customerName'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Update Status:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                      SizedBox(width: 8),
                      StatefulBuilder(
                        builder: (context, setStateDropdown) {
                          bool isUpdating = false;
                          String? selectedStatus = order['status'];
                          final List<String> statusOptions = [
                            'PLACED',
                            'IN_PROGRESS',
                            'READY_FOR_PICKUP',
                            'OUT_FOR_DELIVERY',
                            'COMPLETED',
                            'CANCELED',
                          ];
                          return Row(
                            children: [
                              DropdownButton<String>(
                                value: selectedStatus,
                                items: statusOptions.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(_getStatusDisplayName(status)),
                                  );
                                }).toList(),
                                onChanged: (newStatus) async {
                                  if (newStatus == null || newStatus == order['status']) return;
                                  setStateDropdown(() => isUpdating = true);
                                  final result = await ApiService.updateOrderStatus(order['orderId'], newStatus);
                                  setStateDropdown(() => isUpdating = false);
                                  if (result['success']) {
                                    Fluttertoast.showToast(
                                      msg: 'Order status updated',
                                      backgroundColor: Colors.green,
                                      textColor: Colors.white,
                                    );
                                    _loadOrders();
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: result['message'] ?? 'Failed to update status',
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                    );
                                  }
                                },
                              ),
                              if (isUpdating)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              )
            else
              Text(
                'Laundry: ${order['laundryName'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            SizedBox(height: 4),
            Text(
              'Total: \$${(order['totalPrice'] ?? 0.0).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Date: ${DateTime.parse(order['orderDate'] ?? DateTime.now().toIso8601String()).toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            if (order['items'] != null && (order['items'] as List).isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Items:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              ...(order['items'] as List).take(3).map((item) => Text(
                '• ${item['itemName']} (${item['quantity']}x)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )).toList(),
              if ((order['items'] as List).length > 3)
                Text(
                  '... and ${(order['items'] as List).length - 3} more items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
