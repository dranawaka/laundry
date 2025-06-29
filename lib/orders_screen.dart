import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? userRole;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final userData = await ApiService.getCurrentUser();
      setState(() {
        userRole = userData['role'];
        userId = int.tryParse(userData['id'] ?? '');
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
        msg: "Error loading orders: ${e.toString()}",
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
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF6C4FA3)),
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
                    color: Color(0xFF6C4FA3),
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
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFFDFCEFF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          size: 40,
                          color: Color(0xFF6C4FA3),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        userRole?.toUpperCase() == 'LAUNDRY' 
                            ? 'Orders from customers will appear here'
                            : 'Your orders will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
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
                                  color: Color(0xFF6C4FA3),
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
                    },
                  ),
                ),
    );
  }
}
