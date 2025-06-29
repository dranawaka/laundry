import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';
import 'laundry_detail_page.dart';
import 'order_screen.dart';
import 'favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFavorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Initialize favorites service
      await FavoritesService.initialize();
      
      // Load favorites from backend if user is logged in
      await FavoritesService.loadFavoritesFromBackend();
      
      // Update filtered list
      _filterFavorites();
      
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterFavorites();
  }

  void _filterFavorites() {
    String query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredFavorites = List.from(FavoritesService.favorites);
      } else {
        filteredFavorites = FavoritesService.favorites.where((favorite) {
          String name = favorite['name']?.toString().toLowerCase() ?? '';
          List<String> services = (favorite['services'] as List<dynamic>?)
              ?.map((s) => s.toString().toLowerCase())
              .toList() ?? [];

          // Check if query matches name or any service type
          bool nameMatch = name.contains(query);
          bool serviceMatch = services.any((serviceType) => serviceType.contains(query));

          return nameMatch || serviceMatch;
        }).toList();
      }
    });
  }

  Future<void> _removeFromFavorites(int laundryId) async {
    try {
      final success = await FavoritesService.removeFromFavorites(laundryId);
      if (success) {
        _filterFavorites(); // Refresh the filtered list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Color(0xFF424242),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from favorites'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (FavoritesService.isNotEmpty)
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF424242)),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: FavoritesSearchDelegate(FavoritesService.favorites),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF424242),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading favorites...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : FavoritesService.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No favorite laundries yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add laundries to your favorites to see them here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to dashboard to browse laundries
              Navigator.pushNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF424242),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Browse Laundries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search favorites...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Favorites count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filteredFavorites.length} favorite${filteredFavorites.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              if (FavoritesService.favoritesCount > 0)
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Clear All Favorites'),
                        content: Text('Are you sure you want to remove all favorites?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await FavoritesService.clearFavorites();
                      _filterFavorites();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('All favorites cleared'),
                          backgroundColor: Color(0xFF424242),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Favorites list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              final favorite = filteredFavorites[index];
              return _buildFavoriteCard(favorite);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFF424242).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_laundry_service,
            color: Color(0xFF424242),
            size: 24,
          ),
        ),
        title: Text(
          favorite['name'] ?? 'Laundry',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  favorite['distance'] ?? 'Distance not available',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  '${favorite['rating'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 8),
                Text(
                  favorite['priceText'] ?? 'Price not available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.favorite, color: Color(0xFF424242)),
              onPressed: () => _removeFromFavorites(favorite['id']),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderScreen(laundry: favorite),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Search delegate for favorites
class FavoritesSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> favorites;

  FavoritesSearchDelegate(this.favorites);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredFavorites = favorites.where((favorite) {
      String name = favorite['name']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredFavorites.length,
      itemBuilder: (context, index) {
        final favorite = filteredFavorites[index];
        return ListTile(
          title: Text(favorite['name'] ?? 'Laundry'),
          subtitle: Text(favorite['distance'] ?? 'Distance not available'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderScreen(laundry: favorite),
              ),
            );
          },
        );
      },
    );
  }
}
