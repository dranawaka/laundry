import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';
import 'laundry_detail_page.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Favorite Screen',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar with QR Scanner
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  // This will trigger the listener and filter results
                  // No need for additional logic here
                },
                decoration: InputDecoration(
                  hintText: 'Search laundry services...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterServices();
                          },
                        ),
                      IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Color(0xFF6C4FA3)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QRScannerPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Pickup & Drop-off Toggle Section
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6C4FA3).withOpacity(0.1),
                  child: Icon(
                    Icons.local_shipping,
                    color: Color(0xFF6C4FA3),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup & Drop-off',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isPickupDropOffEnabled ? 'Service enabled' : 'Tap to enable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isPickupDropOffEnabled,
                  onChanged: (value) {
                    setState(() {
                      isPickupDropOffEnabled = value;
                    });

                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isPickupDropOffEnabled
                              ? 'Pickup & Drop-off enabled'
                              : 'Pickup & Drop-off disabled',
                        ),
                        backgroundColor: Color(0xFF6C4FA3),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  activeColor: Color(0xFF6C4FA3),
                  activeTrackColor: Color(0xFF6C4FA3).withOpacity(0.3),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Search Results Count
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Found ${filteredServices.length} result(s) for "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          if (_searchController.text.isNotEmpty) SizedBox(height: 12),

          // Laundry Service Cards
          Expanded(
            child: filteredServices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _searchController.text.isEmpty
                          ? Icons.favorite_outline
                          : Icons.search_off,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No favorite laundries yet'
                        : 'No results found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Add laundries to your favorites'
                        : 'Try searching with different keywords',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterServices();
                      },
                      child: Text(
                        'Clear search',
                        style: TextStyle(
                          color: Color(0xFF6C4FA3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
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
                    child: Column(
                      children: [
                        // Top section with heart icon and image placeholder
                        Container(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Purple heart icon (favorite)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    service['isFavorite'] = !service['isFavorite'];

                                    // Remove from favorites list if unfavorited
                                    if (!service['isFavorite']) {
                                      laundryServices.removeWhere((s) => s['id'] == service['id']);
                                      _filterServices(); // Refresh the filtered list
                                    }
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        service['isFavorite']
                                            ? 'Added to favorites'
                                            : 'Removed from favorites',
                                      ),
                                      backgroundColor: Color(0xFF6C4FA3),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: service['isFavorite']
                                        ? Color(0xFF6C4FA3)
                                        : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    service['isFavorite']
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),

                              // Image placeholder
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_laundry_service,
                                  color: Color(0xFF6C4FA3),
                                  size: 30,
                                ),
                              ),
                              SizedBox(width: 12),

                              // Service details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Distance: ${service['distance']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: service['isOpen'] ? Colors.green : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Open ${service['openTime']} - Close ${service['closeTime']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: service['isOpen'] ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      service['services'].join(' • '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price and rating
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    service['price'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    service['priceUnit'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Star rating
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < service['rating'].floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Purple bottom section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6C4FA3),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Spacer(),
                              if (isPickupDropOffEnabled)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pickup Available',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
