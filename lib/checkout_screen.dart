import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

const kPrimaryColor = Color(0xFF424242); // Dark gray

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> laundry;
  final Map<String, int> selectedServices;
  final List<dynamic> availableServices;
  final String expressType;
  final double subtotal;
  const CheckoutScreen({Key? key, required this.laundry, required this.selectedServices, required this.availableServices, required this.expressType, required this.subtotal}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String expressType = 'Express (24 Hr)';
  DateTime? pickUpDate;
  TimeOfDay? pickUpTime;
  double deliveryCharge = 50.0;
  double tax = 0.0;
  bool isLoading = false;
  final TextEditingController specialInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    expressType = widget.expressType;
    // Calculate tax as 5% of subtotal
    tax = widget.subtotal * 0.05;
  }

  @override
  void dispose() {
    specialInstructionsController.dispose();
    super.dispose();
  }

  double get total => widget.subtotal + deliveryCharge + tax;

  Future<void> _placeOrder() async {
    // Validate required fields
    if (pickUpDate == null) {
      Fluttertoast.showToast(
        msg: "Please select pickup date",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (pickUpTime == null) {
      Fluttertoast.showToast(
        msg: "Please select pickup time",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get current user data
      final userData = await ApiService.getCurrentUser();
      final customerId = int.tryParse(userData['id'] ?? '');
      
      if (customerId == null) {
        throw Exception('Invalid customer ID');
      }

      // Calculate pickup and delivery dates
      final pickupDateTime = DateTime(
        pickUpDate!.year,
        pickUpDate!.month,
        pickUpDate!.day,
        pickUpTime!.hour,
        pickUpTime!.minute,
      );

      // Calculate delivery date based on express type
      final deliveryDateTime = expressType == 'Express (24 Hr)' 
          ? pickupDateTime.add(Duration(hours: 24))
          : pickupDateTime.add(Duration(hours: 48));

      // Prepare items for the order
      final items = widget.selectedServices.entries.map((entry) {
        final serviceId = entry.key;
        final quantity = entry.value;
        final service = widget.availableServices.firstWhere(
          (s) => s['id'].toString() == serviceId,
          orElse: () => {},
        );

        return {
          'itemName': service['serviceName'] ?? 'Service',
          'quantity': quantity,
          'serviceId': int.parse(serviceId),
          'specialInstructions': '', // Could be enhanced to allow per-item instructions
        };
      }).toList();

      // Place the order
      final result = await ApiService.placeOrder(
        customerId: customerId,
        laundryId: widget.laundry['id'],
        pickupDate: pickupDateTime,
        deliveryDate: deliveryDateTime,
        pickupAddress: 'Home (saved address)', // Could be enhanced to allow address selection
        deliveryAddress: 'Home (saved address)',
        specialInstructions: specialInstructionsController.text.isNotEmpty 
            ? specialInstructionsController.text 
            : null,
        items: items,
      );

      setState(() => isLoading = false);

      if (result['success']) {
        Fluttertoast.showToast(
          msg: "Order placed successfully! Order ID: ${result['data']['orderId']}",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        
        // Navigate back to orders screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Fluttertoast.showToast(
          msg: result['message'],
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(
        msg: "Error placing order: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout', style: TextStyle(color: kPrimaryColor)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top info section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text('Pick Up', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
                SizedBox(height: 12),
                // Address
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.home, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Home (saved address)', style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Express, Date, Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Container(
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
                            DropdownMenuItem(value: 'Express (24 Hr)', child: Text('Express (24 Hr)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            DropdownMenuItem(value: 'Normal (48 Hr)', child: Text('Normal (48 Hr)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => expressType = v);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 30)),
                          );
                          if (date != null) setState(() => pickUpDate = date);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: kPrimaryColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pickUpDate == null ? 'Pick Up Date' : '${pickUpDate!.toLocal()}'.split(' ')[0],
                                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) setState(() => pickUpTime = time);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: kPrimaryColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pickUpTime == null ? 'Pick Up Time' : pickUpTime!.format(context),
                                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Shopping cart
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Shopping cart', style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor)),
                          Spacer(),
                          Icon(Icons.keyboard_arrow_down, color: kPrimaryColor),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...widget.selectedServices.entries.map((entry) {
                        final serviceId = entry.key;
                        final count = entry.value;
                        final service = widget.availableServices.firstWhere(
                          (s) => s['id'].toString() == serviceId,
                          orElse: () => {},
                        );

                        if (service.isEmpty) return SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Checkbox(value: true, onChanged: null, activeColor: kPrimaryColor),
                              Expanded(
                                child: Text(
                                  service['serviceName'] ?? 'Service',
                                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  count.toString().padLeft(2, '0'),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Special Instructions
                Text('SPECIAL INSTRUCTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: specialInstructionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any special instructions for your order...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.6)),
                    ),
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
                SizedBox(height: 16),
                // Payment
                Text('PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.credit_card, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Saved card/Bank number (****6789)', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right, color: kPrimaryColor),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Add promo code', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right, color: kPrimaryColor),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                // Totals
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sub Total', style: TextStyle(color: Colors.black)),
                          Text('Delivery Charge', style: TextStyle(color: Colors.black)),
                          Text('Tax + Other Fees', style: TextStyle(color: Colors.black)),
                          SizedBox(height: 6),
                          Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${widget.subtotal.toStringAsFixed(2)}', style: TextStyle(color: Colors.black)),
                          Text('\$${deliveryCharge.toStringAsFixed(2)}', style: TextStyle(color: Colors.black)),
                          Text('\$${tax.toStringAsFixed(2)}', style: TextStyle(color: Colors.black)),
                          SizedBox(height: 6),
                          Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator()
                        : Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 