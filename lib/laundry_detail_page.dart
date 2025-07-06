import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LaundryDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const LaundryDetailPage({Key? key, required this.service}) : super(key: key);

  @override
  State<LaundryDetailPage> createState() => _LaundryDetailPageState();
}

class _LaundryDetailPageState extends State<LaundryDetailPage> {
  int _selectedTab = 0;
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchReviews();
  }

  Future<List<dynamic>> _fetchReviews() async {
    final id = widget.service['id'];
    if (id == null) return [];
    return await ApiService.getLaundryReviews(id);
  }

  void _refreshReviews() {
    setState(() {
      _reviewsFuture = _fetchReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final String name = service['name']?.toString() ?? 'Laundry';
    final String address = service['address']?.toString() ?? '4140 parker rd. allentown, new mexico 31134 (1.2KM)';
    final String hours = service['hours']?.toString() ?? '7AM - 11PM';
    final double rating = (service['rating'] is num) ? service['rating'].toDouble() : 4.2;
    final int reviews = service['reviews'] ?? 4200;
    final String image = service['image']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Store details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rounded image header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: image.isNotEmpty
                        ? Image.network(image, width: double.infinity, height: 180, fit: BoxFit.cover)
                        : Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.local_laundry_service, size: 60, color: Colors.grey),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                      const SizedBox(height: 6),
                      Text(address, style: const TextStyle(color: Colors.black54, fontSize: 15)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(hours, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                          const SizedBox(width: 18),
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$rating', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(width: 4),
                          Text('($reviews reviews)', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionIcon(Icons.language, 'Website'),
                      _actionIcon(Icons.call, 'Call'),
                      _actionIcon(Icons.directions, 'Direction'),
                      _actionIcon(Icons.share, 'Share'),
                    ],
                  ),
                ),
                const Divider(height: 32, thickness: 1.2),
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _tabItem('Price list', 0),
                      _tabItem('About', 1),
                      _tabItem('Services', 2),
                      _tabItem('Offer', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab content
                Builder(
                  builder: (context) {
                    if (_selectedTab == 0) {
                      // Price list tab
                      return Column(
                        children: [
                          // Category chips
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                _categoryChip('Man', true, 'https://randomuser.me/api/portraits/men/1.jpg'),
                                const SizedBox(width: 8),
                                _categoryChip('Woman', false, 'https://randomuser.me/api/portraits/women/1.jpg'),
                                const SizedBox(width: 8),
                                _categoryChip('Kids', false, 'https://randomuser.me/api/portraits/men/2.jpg'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Price list (expandable cards, static for now)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _priceCard('T-shirts', 'https://img.icons8.com/color/48/000000/t-shirt.png'),
                                const SizedBox(height: 12),
                                _priceCard('Suit', 'https://img.icons8.com/color/48/000000/business-suit.png'),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (_selectedTab == 1) {
                      // About tab
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('About us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 8),
                            const Text(
                              'It is a long established fact that a reader will be distracted by\nthe readable content of a page when looking at its layout. the point of using lorem Ipsum is that it has a more-or-less\nnormal distribution of letters, It is a long established fac Read more',
                              style: TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                            const SizedBox(height: 18),
                            const Text('Working hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Monday - friday :  08:00AM - 08:00PM', style: TextStyle(fontSize: 15, color: Colors.black87)),
                            const Text('Saturday - sunday :  08:00AM - 01:00PM', style: TextStyle(fontSize: 15, color: Colors.black87)),
                            const SizedBox(height: 18),
                            // Rate this laundry button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: _showReviewDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Rate this laundry'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('View all', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Review list
                            FutureBuilder<List<dynamic>>(
                              future: _reviewsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return const Text('Failed to load reviews', style: TextStyle(color: Colors.red));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Text('No reviews yet.', style: TextStyle(color: Colors.black54));
                                }
                                final reviews = snapshot.data!;
                                return Column(
                                  children: reviews.map((review) {
                                    return _reviewCard(review);
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    } else if (_selectedTab == 2) {
                      // Services tab
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _serviceCard('Wash & fold', '48 hours', 'https://img.icons8.com/color/48/000000/laundry.png'),
                            const SizedBox(height: 12),
                            _serviceCard('Ironing & fold', '40 hours', 'https://img.icons8.com/color/48/000000/iron.png'),
                            const SizedBox(height: 12),
                            _serviceCard('Hello World', 'Hello World', 'https://img.icons8.com/color/48/000000/clothes.png'),
                            const SizedBox(height: 12),
                            _serviceCard('Hello World', 'Hello World', 'https://img.icons8.com/color/48/000000/washing-machine.png'),
                          ],
                        ),
                      );
                    } else {
                      // Offer tab
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _offerCard(
                              imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=400&q=80',
                              title: 'Flat 30%  off on dry cleaning services',
                              code: 'LAVTYUSD',
                              validity: 'valid till 01 nov 2025',
                            ),
                            const SizedBox(height: 14),
                            _offerCard(
                              imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                              title: 'Flat 10%  off on washing & fold',
                              code: 'LAVTYREDF',
                              validity: 'valid till 01 nov 2025',
                            ),
                            const SizedBox(height: 14),
                            _offerCard(
                              imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=400&q=80',
                              title: 'Flat 10%  off on household laundry services',
                              code: 'LAVTYHLD',
                              validity: 'valid till 01 nov 2025',
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Add to cart button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add to cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _tabItem(String label, int index) {
    final bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: selected ? Colors.black : Colors.black54,
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, String imageUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String title, String iconUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Image.network(iconUrl, width: 36, height: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _serviceCard(String title, String subtitle, String iconUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Image.network(iconUrl, width: 36, height: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 18),
        ],
      ),
    );
  }

  Widget _reviewCard(dynamic review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review['customerName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  // Optionally show date or other info here
                ],
              ),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 2),
              Text((review['rating']?.toString() ?? '0.0'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['reviewText'] ?? '',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() async {
    double rating = 5;
    String reviewText = '';
    bool loading = false;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate this laundry'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    TextFormField(
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Write your review',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your review' : null,
                      onChanged: (val) => reviewText = val,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final customerId = int.tryParse(prefs.getString('user_id') ?? '') ?? 0;
                            final laundryId = widget.service['id'];
                            final resp = await ApiService.submitLaundryReview(
                              laundryId: laundryId,
                              customerId: customerId,
                              rating: rating,
                              reviewText: reviewText,
                            );
                            if (resp['id'] != null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green),
                              );
                              _refreshReviews();
                            } else {
                              setState(() => loading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resp['message'] ?? 'Failed to submit review'), backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            setState(() => loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _offerCard({required String imageUrl, required String title, required String code, required String validity}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Coupon code', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Row(
                  children: [
                    Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                    const SizedBox(width: 10),
                    Text('($validity)', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
