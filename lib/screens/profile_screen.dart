import 'dart:io';
import 'package:drp/screens/main_shell.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _courseController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearGroupController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestInputController = TextEditingController();

  File? _imageFile;
  String? _existingAvatarUrl;
  final List<String> _interests = [];
  bool _isLoading = false;

  // Max interest cap to prevent abuse / matching issues
  static const int _maxInterests = 10;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch user row from your users table
      final userdata = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Fetch existing interests
      final interestsData = await supabase
          .from('user_interests')
          .select('interest')
          .eq('user_id', userId);

      if (userdata != null) {
        setState(() {
          _nameController.text = userdata['name'] ?? '';
          _universityController.text = userdata['university'] ?? '';
          _courseController.text = userdata['course'] ?? '';
          _bioController.text = userdata['bio'] ?? '';
          _yearGroupController.text = userdata['year_group'] ?? '';
          _locationController.text = userdata['location'] ?? '';

          // Pre-populate avatar if one already exists
          _existingAvatarUrl = userdata['avatar_url'];

          // Pre-populate interests list
          _interests.clear();
          _interests.addAll(
            (interestsData as List).map((e) => e['interest'] as String),
          );
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError('Failed to load profile: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Unexpected error loading profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _courseController.dispose();
    _bioController.dispose();
    _yearGroupController.dispose();
    _locationController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _addInterest() {
    // Normalise to lowercase to prevent duplicate mismatches
    final text = _interestInputController.text.trim().toLowerCase();

    if (text.isEmpty) return;

    if (_interests.length >= _maxInterests) {
      _showError('You can add a maximum of $_maxInterests interests.');
      return;
    }

    if (_interests.contains(text)) {
      _showError('You\'ve already added "$text".');
      return;
    }

    setState(() {
      _interests.add(text);
      _interestInputController.clear();
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Use Supabase live session
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError('User session not found. Please log in again.');
      setState(() => _isLoading = false); // Reset spinner
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_imageFile != null) {
        await uploadProfilePicture(_imageFile!, userId);
      }

      await updateDetails(
        userId,
        _nameController.text.trim(),
        _universityController.text.trim(),
        _courseController.text.trim(),
        _bioController.text.trim(),
        _yearGroupController.text.trim(),
        _locationController.text.trim(),
        _interests,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred while saving.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // Logout now signs out from Supabase + confirms with user first
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Sign out from Supabase so StreamBuilder in main.dart reacts
    await supabase.auth.signOut();
    await SessionManager.clearSession();

    if (mounted) Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Setup Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF84DCC6)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : _existingAvatarUrl != null
                                    ? NetworkImage(_existingAvatarUrl!)
                                    : null,
                                child:
                                    (_imageFile == null &&
                                        _existingAvatarUrl == null)
                                    ? Icon(
                                        Icons.camera_alt_outlined,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0XFF84DCC6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Required fields only
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _universityController,
                        label: 'University',
                        icon: Icons.school_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      // Optional fields — no validator block
                      _buildTextField(
                        controller: _courseController,
                        label: 'Course / Major',
                        icon: Icons.book_outlined,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _yearGroupController,
                        label: 'Year Group (e.g. Year 2, Alumnus)',
                        icon: Icons.calendar_today_outlined,
                        required: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        required: false,
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Bio (optional)',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40.0),
                            child: Icon(Icons.description_outlined),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interests
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Interests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_interests.length}/$_maxInterests',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _interestInputController,
                              decoration: InputDecoration(
                                hintText: 'Add an interest (e.g. tennis)',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onFieldSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addInterest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF84DCC6),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(
                              interest,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            backgroundColor: Colors.grey.shade200,
                            deleteIcon: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onDeleted: () =>
                                setState(() => _interests.remove(interest)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF84DCC6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SAVE PROFILE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFD5757),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'LOG OUT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Required flag controls whether validator fires
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool required,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: required ? label : '$label (optional)',
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your $label'
                : null
          : null,
    );
  }
}
