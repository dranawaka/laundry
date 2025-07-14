import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'config.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  final int userId;
  const EditProfileScreen({Key? key, required this.initialProfile, required this.userId}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedProfilePicUrl;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;
  late TextEditingController _websiteController;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p['name'] ?? '');
    _emailController = TextEditingController(text: p['email'] ?? '');
    _phoneController = TextEditingController(text: p['phone'] ?? '');
    _addressController = TextEditingController(text: p['address'] ?? '');
    _cityController = TextEditingController(text: p['city'] ?? '');
    _stateController = TextEditingController(text: p['state'] ?? '');
    _zipController = TextEditingController(text: p['zipCode'] ?? '');
    _countryController = TextEditingController(text: p['country'] ?? '');
    _websiteController = TextEditingController(text: p['websiteUrl'] ?? '');
    _latitude = p['latitude'] is double ? p['latitude'] : (p['latitude'] != null ? double.tryParse(p['latitude'].toString()) : null);
    _longitude = p['longitude'] is double ? p['longitude'] : (p['longitude'] != null ? double.tryParse(p['longitude'].toString()) : null);
    _uploadedProfilePicUrl = p['profilePicture'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadProfilePicture(File imageFile) async {
    final url = Uri.parse('${Config.getApiBaseUrl()}/auth/user/${widget.userId}/upload-profile-picture');
    var request = http.MultipartRequest('POST', url); // Changed from PUT to POST
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    // Add auth headers if needed
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final respJson = jsonDecode(respStr);
      return respJson['profilePicture'] ?? respJson['url'] ?? null;
    }
    return null;
  }

  Future<bool> _updateProfile() async {
    setState(() => _isLoading = true);
    String? profilePicUrl = _uploadedProfilePicUrl;
    if (_selectedImage != null) {
      profilePicUrl = await _uploadProfilePicture(_selectedImage!);
      if (profilePicUrl == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile picture'), backgroundColor: Colors.red),
        );
        return false;
      }
    }
    final profileData = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "profilePicture": profilePicUrl,
      "address": _addressController.text.trim(),
      "latitude": _latitude,
      "longitude": _longitude,
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "zipCode": _zipController.text.trim(),
      "country": _countryController.text.trim(),
      "websiteUrl": _websiteController.text.trim(),
    };
    final url = Uri.parse('${Config.getApiBaseUrl()}/auth/user/${widget.userId}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );
    setState(() => _isLoading = false);
    return response.statusCode == 200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      bool success = await _updateProfile();
                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
                          );
                          Navigator.pop(context, true);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_uploadedProfilePicUrl != null && _uploadedProfilePicUrl!.isNotEmpty)
                                ? NetworkImage(_uploadedProfilePicUrl!) as ImageProvider
                                : null,
                        child: _selectedImage == null && (_uploadedProfilePicUrl == null || _uploadedProfilePicUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 48, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to change profile picture'),
                    const SizedBox(height: 24),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Email required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
                    ),
                    const SizedBox(height: 16),
                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 16),
                    // State
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                    const SizedBox(height: 16),
                    // Zip
                    TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'Zip Code'),
                    ),
                    const SizedBox(height: 16),
                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
} 