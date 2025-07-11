import 'package:flutter/material.dart';
import 'api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic> laundry;
  final Map<String, int> selectedServices;
  final List<dynamic> availableServices;
  final String expressType;
  const CartScreen({
    Key? key,
    required this.laundry,
    required this.selectedServices,
    required this.availableServices,
    required this.expressType,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, int> selectedServices = {};
  late String expressType;

  @override
  void initState() {
    super.initState();
    selectedServices = Map.from(widget.selectedServices);
    expressType = widget.expressType;
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
        final price = pricePerItem > 0 ? pricePerItem : pricePerKg;
        subtotal += price * count;
      }
    }
    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    final laundry = widget.laundry;
    final subtotal = _calculateSubtotal();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Laundry Info
                  Text(
                    laundry['name'] ?? 'Laundry Name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick up from (Customer Address)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  // Express Type Dropdown
                  DropdownButtonFormField<String>(
                    value: expressType,
                    items: const [
                      DropdownMenuItem(value: 'Express (24 Hr)', child: Text('Express (24 Hr)')),
                      DropdownMenuItem(value: 'Normal (48 Hr)', child: Text('Normal (48 Hr)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => expressType = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Service Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Selected Services
                  if (selectedServices.isEmpty)
                    Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No services selected', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ...selectedServices.entries.map((entry) {
                          final serviceId = entry.key;
                          final count = entry.value;
                          final service = widget.availableServices.firstWhere(
                            (s) => s['id'].toString() == serviceId,
                            orElse: () => {},
                          );
                          if (service.isEmpty) return const SizedBox.shrink();
                          final pricePerItem = service['pricePerItem'] ?? 0.0;
                          final pricePerKg = service['pricePerKg'] ?? 0.0;
                          final price = pricePerItem > 0 ? pricePerItem : pricePerKg;
                          final serviceSubtotal = price * count;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['serviceName'] ?? 'Service',
                                        style: const TextStyle(
                                            color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
                                      ),
                                      if (service['description'] != null && service['description'].isNotEmpty)
                                        Text(
                                          service['description'],
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Subtotal: \$${serviceSubtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.black),
                                      onPressed: () => _updateServiceCount(serviceId, count - 1),
                                    ),
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Text(count.toString().padLeft(2, '0'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                                      onPressed: () => _updateServiceCount(serviceId, count + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 32),
                  // Subtotal and Checkout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedServices.isEmpty ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              laundry: widget.laundry,
                              selectedServices: selectedServices,
                              availableServices: widget.availableServices,
                              expressType: expressType,
                              subtotal: subtotal,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001A36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 