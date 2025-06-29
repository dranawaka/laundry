import 'package:flutter/material.dart';
import 'api_service.dart';

const kPrimaryColor = Color(0xFF6C4FA3);

class LaundryServicesManagementScreen extends StatefulWidget {
  final int laundryId;
  const LaundryServicesManagementScreen({Key? key, required this.laundryId}) : super(key: key);

  @override
  State<LaundryServicesManagementScreen> createState() => _LaundryServicesManagementScreenState();
}

class _LaundryServicesManagementScreenState extends State<LaundryServicesManagementScreen> {
  List<dynamic> services = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() { isLoading = true; error = null; });
    print('Fetching services for laundryId: \'${widget.laundryId}\'');
    try {
      final result = await ApiService.getServicesByLaundry(widget.laundryId);
      print('Fetched services: $result');
      setState(() { services = result; isLoading = false; });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  void _showServiceDialog({Map<String, dynamic>? service}) {
    final isEdit = service != null;
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: service?['serviceName'] ?? '');
    final descController = TextEditingController(text: service?['description'] ?? '');
    final pricePerItemController = TextEditingController(text: service?['pricePerItem']?.toString() ?? '');
    final pricePerKgController = TextEditingController(text: service?['pricePerKg']?.toString() ?? '');
    final minOrderController = TextEditingController(text: service?['minOrderAmount']?.toString() ?? '');
    final deliveryController = TextEditingController(text: service?['estimatedDeliveryHours']?.toString() ?? '');
    final specialController = TextEditingController(text: service?['specialInstructions'] ?? '');
    String category = service?['serviceCategory'] ?? 'WASH_AND_FOLD';
    bool isAvailable = service?['isAvailable'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Service' : 'Add Service'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Service Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: pricePerItemController,
                  decoration: InputDecoration(labelText: 'Price Per Item'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: pricePerKgController,
                  decoration: InputDecoration(labelText: 'Price Per Kg'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: minOrderController,
                  decoration: InputDecoration(labelText: 'Min Order Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: deliveryController,
                  decoration: InputDecoration(labelText: 'Estimated Delivery Hours'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: [
                    'WASH_AND_FOLD','WASH_AND_IRON','DRY_CLEAN','IRONING_ONLY','STARCHING','STAIN_REMOVAL','BULK_WASHING','EXPRESS_SERVICE','PREMIUM_SERVICE','ECO_FRIENDLY','DELICATE_CARE','CURTAIN_CLEANING','RUG_CLEANING','SHOE_CLEANING','BAG_CLEANING'
                  ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat.replaceAll('_', ' ')))).toList(),
                  onChanged: (v) => category = v ?? category,
                ),
                SwitchListTile(
                  value: isAvailable,
                  onChanged: (v) => setState(() => isAvailable = v),
                  title: Text('Available'),
                  activeColor: kPrimaryColor,
                ),
                TextFormField(
                  controller: specialController,
                  decoration: InputDecoration(labelText: 'Special Instructions'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final data = {
                  'serviceName': nameController.text,
                  'description': descController.text,
                  'pricePerItem': double.tryParse(pricePerItemController.text),
                  'pricePerKg': double.tryParse(pricePerKgController.text),
                  'minOrderAmount': double.tryParse(minOrderController.text),
                  'estimatedDeliveryHours': int.tryParse(deliveryController.text),
                  'isAvailable': isAvailable,
                  'serviceCategory': category,
                  'specialInstructions': specialController.text,
                };
                if (isEdit) {
                  await ApiService.updateLaundryService(service['id'], widget.laundryId, data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service updated successfully!'), backgroundColor: Colors.green),
                  );
                } else {
                  await ApiService.createLaundryService(widget.laundryId, data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Service added successfully!'), backgroundColor: Colors.green),
                  );
                }
                Navigator.pop(context);
                _fetchServices();
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Manage Services', style: TextStyle(color: kPrimaryColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: kPrimaryColor),
            onPressed: _fetchServices,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add, color: kPrimaryColor),
            onPressed: () => _showServiceDialog(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : error != null
              ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
              : services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_laundry_service, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No services found. Tap + to add.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final s = services[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(s['serviceName'] ?? '', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                            subtitle: Text(s['description'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(s['isAvailable'] == true ? Icons.check_circle : Icons.cancel, color: s['isAvailable'] == true ? Colors.green : Colors.red),
                                  tooltip: 'Toggle Availability',
                                  onPressed: () async {
                                    await ApiService.toggleServiceAvailability(s['id'], widget.laundryId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Availability updated!'), backgroundColor: Colors.blue),
                                    );
                                    _fetchServices();
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: kPrimaryColor),
                                  onPressed: () => _showServiceDialog(service: s),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await ApiService.deleteLaundryService(s['id'], widget.laundryId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Service deleted!'), backgroundColor: Colors.red),
                                    );
                                    _fetchServices();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 