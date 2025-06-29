import 'package:flutter/material.dart';
import 'checkout_screen.dart';

const kPrimaryColor = Color(0xFF6C4FA3);

class CartScreen extends StatefulWidget {
  final Map<String, dynamic> laundry;
  final Map<String, int> selectedServices;
  final List<dynamic> availableServices;
  final String expressType;
  const CartScreen({Key? key, required this.laundry, required this.selectedServices, required this.availableServices, required this.expressType}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, int> selectedServices = {};

  @override
  void initState() {
    super.initState();
    selectedServices = Map.from(widget.selectedServices);
  }

  void _updateServiceCount(String serviceId, int count) {
    setState(() {
      if (count > 0) {
        selectedServices[serviceId] = count;
      } else {
        selectedServices.remove(serviceId);
      }
    });
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (final entry in selectedServices.entries) {
      final serviceId = entry.key;
      final count = entry.value;
      final service = widget.availableServices.firstWhere(
        (s) => s['id'].toString() == serviceId,
        orElse: () => {},
      );
      
      if (service.isNotEmpty) {
        final pricePerItem = service['pricePerItem'] ?? 0.0;
        final pricePerKg = service['pricePerKg'] ?? 0.0;
        // Use price per item if available, otherwise price per kg
        final price = pricePerItem > 0 ? pricePerItem : pricePerKg;
        subtotal += price * count;
      }
    }
    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    final laundry = widget.laundry;
    final expressType = widget.expressType;
    final subtotal = _calculateSubtotal();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cart', style: TextStyle(color: kPrimaryColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laundry['name'] ?? 'LAUNDRY NAME',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor),
                        ),
                        Text(
                          'Pick up from (Customer Address)',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: expressType,
                      underline: SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: kPrimaryColor),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                      items: [
                        DropdownMenuItem(value: 'Express (24 Hr)', child: Text('Express (24 Hr)')),
                        DropdownMenuItem(value: 'Normal (48 Hr)', child: Text('Normal (48 Hr)')),
                      ],
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
            ),
            // Selected Services
            Expanded(
              child: selectedServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No services selected', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedServices.length,
                      itemBuilder: (context, index) {
                        final serviceId = selectedServices.keys.elementAt(index);
                        final count = selectedServices[serviceId]!;
                        final service = widget.availableServices.firstWhere(
                          (s) => s['id'].toString() == serviceId,
                          orElse: () => {},
                        );

                        if (service.isEmpty) return SizedBox.shrink();

                        final pricePerItem = service['pricePerItem'] ?? 0.0;
                        final pricePerKg = service['pricePerKg'] ?? 0.0;
                        final price = pricePerItem > 0 ? pricePerItem : pricePerKg;
                        final serviceSubtotal = price * count;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service['serviceName'] ?? 'Service',
                                            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                                          ),
                                          if (service['description'] != null && service['description'].isNotEmpty)
                                            Text(
                                              service['description'],
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline, color: kPrimaryColor),
                                          onPressed: () => _updateServiceCount(serviceId, count - 1),
                                        ),
                                        Container(
                                          width: 32,
                                          alignment: Alignment.center,
                                          child: Text(count.toString().padLeft(2, '0'), style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline, color: kPrimaryColor),
                                          onPressed: () => _updateServiceCount(serviceId, count + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${price.toStringAsFixed(2)} × $count',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                    Text(
                                      '${serviceSubtotal.toStringAsFixed(2)}',
                                      style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Total
            if (selectedServices.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
                    ),
                    Text(
                      '${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: selectedServices.isNotEmpty ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          laundry: laundry,
                          selectedServices: selectedServices,
                          availableServices: widget.availableServices,
                          expressType: expressType,
                          subtotal: subtotal,
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text('GO TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 