import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // To access AppState.currentUserId
import 'home_screen.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields based on your schema
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _courseController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearGroupController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestInputController = TextEditingController();

  File? _imageFile;
  final List<String> _interests = [];
  bool _isLoading = false;

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

  // Pick an image from the mobile device gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compresses image slightly for faster mobile uploads
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Method to append a new interest string to the local list
  void _addInterest() {
    final text = _interestInputController.text.trim();
    if (text.isNotEmpty && !_interests.contains(text)) {
      setState(() {
        _interests.add(text);
        _interestInputController.clear();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AppState.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User session not found.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // update details
    try {
      if (_imageFile != null) {
        await uploadProfilePicture(_imageFile!, userId);
      }

      await updateDetails(userId, 
                          _nameController.text.trim(), 
                          _universityController.text.trim(), 
                          _courseController.text.trim(),
                          _bioController.text.trim(),
                          _yearGroupController.text.trim(),
                          _locationController.text.trim(),
                          _interests);      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        // Take them straight to the main app dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF84DCC6))))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture Picker UI Component
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                                child: _imageFile == null
                                    ? Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade600)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0XFF84DCC6), shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Text Fields
                      _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _universityController, label: 'University', icon: Icons.school_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _courseController, label: 'Course / Major', icon: Icons.book_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _yearGroupController, label: 'Year Group (e.g. Year 2, Alumnus)', icon: Icons.calendar_today_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _locationController, label: 'Location', icon: Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      
                      // Custom Multi-Line Bio Field
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40.0),
                            child: Icon(Icons.description_outlined),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dynamic Interests Input Title
                      const Text('Your Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 8),

                      // Custom Interest Tag Row Input View
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _interestInputController,
                              decoration: InputDecoration(
                                hintText: 'Add an interest (e.g. Tennis)',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              onFieldSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addInterest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF84DCC6),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Wrap widget to dynamically stack interactive Interest Chips
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(interest, style: const TextStyle(color: Colors.black87)),
                            backgroundColor: Colors.grey.shade200,
                            deleteIcon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                            onDeleted: () {
                              setState(() {
                                _interests.remove(interest);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),

                      // Submit Configuration Profile Button
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF84DCC6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('SAVE PROFILE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Small helper block builder function to clean up layout repetition
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your $label' : null,
    );
  }
}