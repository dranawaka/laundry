import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'api_service.dart';

const kPrimaryColor = Color(0xFF424242); // Dark gray

class OrderScreen extends StatefulWidget {
  final Map<String, dynamic> laundry;
  const OrderScreen({Key? key, required this.laundry}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> availableServices = [];
  bool isLoading = true;
  String? error;
  String expressType = 'Express (24 Hr)';
  Map<String, int> selectedServices = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailableServices();
  }

  Future<void> _fetchAvailableServices() async {
    setState(() { isLoading = true; error = null; });
    try {
      // Debug: Print laundry object to see what fields are available
      print('=== ORDER SCREEN DEBUG ===');
      print('Laundry object: ${widget.laundry}');
      print('Laundry ID: ${widget.laundry['id']}');
      print('Laundry name: ${widget.laundry['name']}');
      
      // Check if laundry has an ID
      if (widget.laundry['id'] == null) {
        setState(() { 
          error = 'Laundry ID is missing. Cannot fetch services.'; 
          isLoading = false; 
        });
        return;
      }
      
      final services = await ApiService.getServicesByLaundry(widget.laundry['id']);
      print('Services fetched: ${services.length}');
      print('Services data: $services');
      
      // Filter only available services
      final available = services.where((service) => service['isAvailable'] == true).toList();
      print('Available services: ${available.length}');
      print('=== END ORDER SCREEN DEBUG ===');
      
      setState(() { 
        availableServices = available; 
        isLoading = false; 
      });
    } catch (e) {
      print('=== ORDER SCREEN ERROR ===');
      print('Error fetching services: $e');
      print('=== END ORDER SCREEN ERROR ===');
      setState(() { error = e.toString(); isLoading = false; });
    }
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

  @override
  Widget build(BuildContext context) {
    final laundry = widget.laundry;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('', style: TextStyle(color: kPrimaryColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text('Pick Up', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: kPrimaryColor),
                        SizedBox(width: 4),
                        Text('Search', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Laundry info card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.favorite_border, size: 32, color: kPrimaryColor),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            Icon(Icons.image, size: 48, color: kPrimaryColor.withOpacity(0.2)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_laundry_service, size: 28, color: kPrimaryColor),
                              SizedBox(width: 8),
                              Icon(Icons.iron, size: 28, color: kPrimaryColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.map, size: 32, color: Colors.green[400]),
                  ),
                ],
              ),
            ),
            // Laundry avatar and name
            Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Icon(Icons.image, size: 40, color: kPrimaryColor),
                ),
                SizedBox(height: 8),
                Text(
                  laundry['name'] ?? 'Laundry Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 2),
                    Text('${laundry['rating'] ?? '4.5'}', style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor)),
                    SizedBox(width: 4),
                    Text('(200+)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Express dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
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
                      onChanged: (v) {
                        if (v != null) setState(() => expressType = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Available Services
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                  : error != null
                      ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
                      : availableServices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_laundry_service, size: 64, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text('No services available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: availableServices.length,
                              itemBuilder: (context, index) {
                                final service = availableServices[index];
                                final serviceId = service['id'].toString();
                                final currentCount = selectedServices[serviceId] ?? 0;
                                
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      service['serviceName'] ?? 'Service',
                                      style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (service['description'] != null && service['description'].isNotEmpty)
                                          Text(
                                            service['description'],
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (service['pricePerItem'] != null)
                                              Text(
                                                '\$${service['pricePerItem']}/item',
                                                style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500, fontSize: 12),
                                              ),
                                            if (service['pricePerItem'] != null && service['pricePerKg'] != null)
                                              Text(' | ', style: TextStyle(color: Colors.grey[400])),
                                            if (service['pricePerKg'] != null)
                                              Text(
                                                '\$${service['pricePerKg']}/kg',
                                                style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w500, fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline, color: kPrimaryColor),
                                          onPressed: () => _updateServiceCount(serviceId, currentCount - 1),
                                        ),
                                        Container(
                                          width: 32,
                                          alignment: Alignment.center,
                                          child: Text(
                                            currentCount.toString().padLeft(2, '0'),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline, color: kPrimaryColor),
                                          onPressed: () => _updateServiceCount(serviceId, currentCount + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            // View Cart button
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
                        builder: (context) => CartScreen(
                          laundry: laundry,
                          selectedServices: selectedServices,
                          availableServices: availableServices,
                          expressType: expressType,
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
                  child: Text('VIEW CART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 