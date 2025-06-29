import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';
import 'laundry_detail_page.dart';
import 'dashboard_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredServices = [];
  bool isPickupDropOffEnabled = false;

  // Dummy data for laundry services
  List<Map<String, dynamic>> laundryServices = [
    {
      'id': 1,
      'name': 'Laundry Mama',
      'distance': '0.5 km',
      'rating': 4.5,
      'price': 'Rp 35,000',
      'priceUnit': 'Per Kg',
      'services': ['Wash', 'Dry', 'Iron'],
      'openTime': '08:00',
      'closeTime': '18:00',
      'isOpen': true,
      'isFavorite': true,
    },
    {
      'id': 2,
      'name': 'Clean Express',
      'distance': '1.2 km',
      'rating': 4.2,
      'price': 'Rp 30,000',
      'priceUnit': 'Per Kg',
      'services': ['Wash', 'Dry'],
      'openTime': '07:00',
      'closeTime': '20:00',
      'isOpen': true,
      'isFavorite': true,
    },
    {
      'id': 3,
      'name': 'Quick Wash',
      'distance': '2.1 km',
      'rating': 4.0,
      'price': 'Rp 25,000',
      'priceUnit': 'Per Kg',
      'services': ['Wash', 'Iron'],
      'openTime': '09:00',
      'closeTime': '17:00',
      'isOpen': false,
      'isFavorite': true,
    },
    {
      'id': 4,
      'name': 'Super Clean',
      'distance': '1.8 km',
      'rating': 4.7,
      'price': 'Rp 40,000',
      'priceUnit': 'Per Kg',
      'services': ['Dry Clean', 'Iron'],
      'openTime': '08:30',
      'closeTime': '19:00',
      'isOpen': true,
      'isFavorite': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredServices = List.from(laundryServices);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterServices();
  }

  void _filterServices() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredServices = List.from(laundryServices);
      } else {
        filteredServices = laundryServices.where((service) {
          String serviceName = service['name'].toString().toLowerCase();
          List<String> serviceTypes = (service['services'] as List<dynamic>)
              .map((s) => s.toString().toLowerCase())
              .toList();

          // Check if query matches name or any service type
          bool nameMatch = serviceName.contains(query);
          bool serviceMatch = serviceTypes.any((serviceType) => serviceType.contains(query));

          return nameMatch || serviceMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access the static favoriteLaundries from DashboardScreen
    final favoriteLaundries = DashboardScreen.favoriteLaundriesGlobal;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Favorite Laundries',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: favoriteLaundries.isEmpty
                ? Center(
                      child: Text(
                'No favorite laundries yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: favoriteLaundries.length,
              itemBuilder: (context, index) {
                final service = favoriteLaundries[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LaundryDetailPage(service: service),
                      ),
                    );
                  },
                  child: Container(
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
                    child: ListTile(
                      leading: Icon(Icons.local_laundry_service, color: Color(0xFF6C4FA3)),
                      title: Text(service['name'] ?? 'Laundry'),
                      subtitle: Text('Distance: ${service['distance'] ?? '-'}'),
                      trailing: Icon(Icons.favorite, color: Color(0xFF6C4FA3)),
                    ),
                  ),
                );
              },
      ),
    );
  }
}
