import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _locationController = TextEditingController();

  bool isPickupDropOffEnabled = false;
  bool isLocationExpanded = false;

  Map<String, bool> selectedServices = {
    'Wash': false,
    'Iron': false,
    'Wash + Iron': false,
    'Dry Clean': false,
  };

  Map<String, bool> selectedTimes = {
    'Open - Dropdown': false,
    'Close - Dropdown': false,
  };

  RangeValues priceRange = RangeValues(0, 100000);
  bool isPickupDelivery = false;

  List<Map<String, dynamic>> allLaundries = [
    {
      'name': 'Laundry Mama',
      'distance': '10 KM',
      'rating': 4.5,
      'price': 35000,
      'priceText': 'Rp. 35,000',
      'services': ['Wash', 'Iron'],
      'isOpen': true,
      'hasPickup': true,
      'openTime': '8 am',
      'closeTime': '8 pm',
      'days': 'Mon - Fri',
      'satTime': '8 am - 5 pm',
      'sunStatus': 'Closed on Sunday',
      'isFavorite': false,
    },
    {
      'name': 'Laundry Mama 2',
      'distance': '15 KM',
      'rating': 4.0,
      'price': 50000,
      'priceText': 'Rp. 50,000',
      'services': ['Wash + Iron'],
      'isOpen': true,
      'hasPickup': true,
      'openTime': '7 am',
      'closeTime': '9 pm',
      'days': 'Mon - Fri',
      'satTime': '7 am - 6 pm',
      'sunStatus': 'Closed on Sunday',
      'isFavorite': false,
    },
    {
      'name': 'Laundry Mama 3',
      'distance': '20 KM',
      'rating': 3.5,
      'price': 70000,
      'priceText': 'Rp. 70,000',
      'services': ['Dry Clean'],
      'isOpen': false,
      'hasPickup': false,
      'openTime': '9 am',
      'closeTime': '6 pm',
      'days': 'Mon - Fri',
      'satTime': '9 am - 4 pm',
      'sunStatus': 'Closed on Sunday',
      'isFavorite': false,
    },
  ];

  List<Map<String, dynamic>> filteredLaundries = [];

  @override
  void initState() {
    super.initState();
    filteredLaundries = List.from(allLaundries);
    _searchController.addListener(_filterLaundries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _filterLaundries() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredLaundries = List.from(allLaundries);
      } else {
        filteredLaundries = allLaundries.where((laundry) {
          String laundryName = laundry['name'].toString().toLowerCase();
          List<String> serviceTypes = (laundry['services'] as List<dynamic>)
              .map((s) => s.toString().toLowerCase())
              .toList();

          bool nameMatch = laundryName.contains(query);
          bool serviceMatch = serviceTypes.any((serviceType) => serviceType.contains(query));

          return nameMatch || serviceMatch;
        }).toList();
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('Price', true),
                    SizedBox(width: 8),
                    _buildFilterChip('Distance', false),
                    SizedBox(width: 8),
                    _buildFilterChip('More Filters', false),
                    Spacer(),
                    _buildFilterChip('Sort By', false),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SERVICES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedServices.keys.map((service) {
                          return _buildServiceChip(
                            service,
                            selectedServices[service]!,
                                (value) {
                              setModalState(() {
                                selectedServices[service] = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'OPEN/CLOSE TIME',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: selectedTimes.keys.map((time) {
                          return _buildServiceChip(
                            time,
                            selectedTimes[time]!,
                                (value) {
                              setModalState(() {
                                selectedTimes[time] = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Price Range / Distance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      RangeSlider(
                        values: priceRange,
                        min: 0,
                        max: 100000,
                        divisions: 10,
                        activeColor: Color(0xFF9A7ED0),
                        labels: RangeLabels(
                          'Rp ${priceRange.start.round()}',
                          'Rp ${priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            priceRange = values;
                          });
                        },
                      ),
                      Row(
                        children: [
                          _buildAmountButton('Amount Min'),
                          SizedBox(width: 12),
                          _buildAmountButton('Amount Max'),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildServiceChip(
                        'Free Pick Up / Delivery',
                        isPickupDelivery,
                            (value) {
                          setModalState(() {
                            isPickupDelivery = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            selectedServices.updateAll((key, value) => false);
                            selectedTimes.updateAll((key, value) => false);
                            priceRange = RangeValues(0, 100000);
                            isPickupDelivery = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF9A7ED0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      filteredLaundries = allLaundries.where((laundry) {
        bool serviceMatch = selectedServices.values.every((v) => !v) ||
            selectedServices.entries.any((entry) =>
            entry.value && laundry['services'].contains(entry.key));

        bool priceMatch = laundry['price'] >= priceRange.start &&
            laundry['price'] <= priceRange.end;

        bool pickupMatch = !isPickupDelivery || laundry['hasPickup'];

        return serviceMatch && priceMatch && pickupMatch;
      }).toList();
    });
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF9A7ED0) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label, bool isSelected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF9A7ED0) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountButton(String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLaundryCard(Map<String, dynamic> laundry) {
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
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          laundry['isFavorite'] = !laundry['isFavorite'];
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              laundry['isFavorite']
                                  ? 'Added to favorites'
                                  : 'Removed from favorites',
                            ),
                            backgroundColor: Color(0xFF9A7ED0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: laundry['isFavorite']
                              ? Color(0xFF9A7ED0)
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          laundry['isFavorite']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_laundry_service,
                    color: Color(0xFF9A7ED0),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            laundry['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              return Icon(
                                index < laundry['rating'].floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Distance: ${laundry['distance']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Open ${laundry['openTime']} - Close ${laundry['closeTime']} (${laundry['days']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Open ${laundry['satTime']} (Sat)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        laundry['sunStatus'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      laundry['priceText'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/ Per Kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    if (laundry['hasPickup'])
                      Text(
                        'Free Delivery',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (laundry['services'].contains('Iron'))
                          Container(
                            margin: EdgeInsets.only(right: 4),
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.iron,
                              size: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF9A7ED0),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  laundry['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Distance: ${laundry['distance']}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox.shrink(),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Row(
                    children: [
                      Switch(
                        value: isPickupDropOffEnabled,
                        onChanged: (value) {
                          setState(() {
                            isPickupDropOffEnabled = value;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isPickupDropOffEnabled
                                    ? 'Pickup/Drop-off enabled'
                                    : 'Pickup/Drop-off disabled',
                              ),
                              backgroundColor: Color(0xFF9A7ED0),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        activeColor: Color(0xFF9A7ED0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'PICKUP / DROP OFF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            ),
            if (isLocationExpanded)
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter location...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isLocationExpanded = !isLocationExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, color: Colors.grey[600]),
                        SizedBox(width: 12),
                        Text(
                          'Where to?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          isLocationExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search laundry services...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterModal,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF9A7ED0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedServices.values.any((v) => v) || isPickupDelivery)
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (selectedServices['Wash'] == true)
                      _buildActiveFilterTag('Wash'),
                    if (selectedServices['Iron'] == true)
                      _buildActiveFilterTag('Iron'),
                    if (isPickupDelivery)
                      _buildActiveFilterTag('Free Delivery'),
                  ],
                ),
              ),
            Expanded(
              child: filteredLaundries.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No laundry services found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try searching with different keywords',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredLaundries.length,
                itemBuilder: (context, index) {
                  return _buildLaundryCard(filteredLaundries[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTag(String label) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF9A7ED0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                if (label == 'Wash') selectedServices['Wash'] = false;
                if (label == 'Iron') selectedServices['Iron'] = false;
                if (label == 'Free Delivery') isPickupDelivery = false;
                _applyFilters();
              });
            },
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
