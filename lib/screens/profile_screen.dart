// import 'dart:io';
import 'package:drp/screens/main_shell.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/widgets/society_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/session_manager.dart';
import '../models/useful_data.dart';
import '../models/interest_data.dart';
import '../services/interest_suggestion_service.dart';
import '../widgets/interests_categories.dart';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  final bool isSociety;
  const ProfileScreen({super.key, this.isSociety = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestInputController = TextEditingController();

  String? _selectedUniversity;
  String? _selectedBorough;
  String? _selectedYearGroup;

  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _existingAvatarUrl;
  bool _isLoading = false;

  static const int _maxInterests = 10;

  // ── Interests with optional photo ────────────────────────────────────────
  // Key: interest name (lowercase)
  // Value: {'url': String?, 'bytes': Uint8List?, 'file': XFile?}
  //   - url   → already saved in Supabase
  //   - bytes → newly picked, not yet saved
  //   - file  → newly picked file (needed for upload)
  final Map<String, Map<String, dynamic>> _interestData = {};

  // Ordered list of interest names (preserves display order)
  final List<String> _interests = [];

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

      final userdata = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Now also fetches photo_url per interest
      final interestsData = await supabase
          .from('user_interests')
          .select('interest, photo_url')
          .eq('user_id', userId);

      if (userdata != null) {
        setState(() {
          _nameController.text = userdata['name'] ?? '';
          _courseController.text = userdata['course'] ?? '';
          _bioController.text = userdata['bio'] ?? '';

          final savedUniversity = userdata['university'] as String?;
          _selectedUniversity = londonUniversities.contains(savedUniversity)
              ? savedUniversity
              : null;

          final savedLocation = userdata['location'] as String?;
          _selectedBorough = londonBoroughs.contains(savedLocation)
              ? savedLocation
              : null;

          final savedYear = userdata['year_group'] as String?;
          _selectedYearGroup = yearGroups.contains(savedYear)
              ? savedYear
              : null;

          _existingAvatarUrl = userdata['avatar_url'];

          _interests.clear();
          _interestData.clear();

          for (final row in interestsData as List) {
            final name = row['interest'] as String;
            final url = row['photo_url'] as String?;
            _interests.add(name);
            _interestData[name] = {
              'url': url, // existing saved photo (nullable)
              'bytes': null, // no new photo yet
              'file': null,
            };
          }
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
    _courseController.dispose();
    _bioController.dispose();
    _interestInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  // ── Pick a photo for a specific interest ─────────────────────────────────
  Future<void> _pickInterestPhoto(String interest) async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _interestData[interest] = {
          ..._interestData[interest]!,
          'bytes': bytes,
          'file': picked,
        };
      });
    }
  }

  // ── Remove a photo from an interest (clears both saved + new) ────────────
  void _removeInterestPhoto(String interest) {
    setState(() {
      _interestData[interest] = {
        ..._interestData[interest]!,
        'url': null,
        'bytes': null,
        'file': null,
      };
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _showError('User session not found. Please log in again.');
      return;
    }
    if (_selectedUniversity == null) {
      _showError('Please select your university.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Profile picture ──────────────────────────────────────────────
      if (_imageFile != null) {
        await uploadProfilePicture(_imageFile!, userId);
      }

      // ── Upload any new interest photos & build final url map ─────────
      // Map<interestName, finalPhotoUrl (nullable)>
      final Map<String, String?> finalPhotoUrls = {};

      for (final interest in _interests) {
        final data = _interestData[interest]!;
        final XFile? newFile = data['file'] as XFile?;
        final String? existingUrl = data['url'] as String?;

        if (newFile != null) {
          // Upload new photo and use its URL
          final urls = await uploadGalleryPhotos([newFile], userId);
          finalPhotoUrls[interest] = urls.isNotEmpty ? urls.first : existingUrl;
        } else {
          // Keep existing URL (or null if they removed it)
          finalPhotoUrls[interest] = existingUrl;
        }
      }

      // ── Save interests + photo URLs in one go ────────────────────────
      await updateDetails(
        userId,
        _nameController.text.trim(),
        _selectedUniversity!,
        _courseController.text.trim(),
        _bioController.text.trim(),
        widget.isSociety ? '' : (_selectedYearGroup ?? ''),
        widget.isSociety ? '' : (_selectedBorough ?? ''),
        // Pass interests as before — updateDetails handles the upsert
        widget.isSociety ? [] : _interests,
      );

      // ── Update photo_url per interest row ────────────────────────────
      if (!widget.isSociety) {
        for (final interest in _interests) {
          await supabase
              .from('user_interests')
              .update({'photo_url': finalPhotoUrls[interest]})
              .eq('user_id', userId)
              .eq('interest', interest);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                widget.isSociety ? const SocietyNavBar() : const MainShell(),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

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

    await supabase.auth.signOut();
    await SessionManager.clearSession();
    if (mounted) Navigator.pushReplacementNamed(context, '/signup');
  }

  // ── Interest Photo Gallery Section ───────────────────────────────────────
  Widget _buildPhotoGallery() {
    if (_interests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interest Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap an interest to add an optional photo!',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // ── Horizontal scrollable chip row ───────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _interests.map((interest) {
              final data = _interestData[interest]!;
              final bool hasPhoto =
                  data['bytes'] != null || data['url'] != null;
              final displayName =
                  interest[0].toUpperCase() + interest.substring(1);

              return GestureDetector(
                onTap: () => _openInterestPhotoSheet(interest),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    // Highlight if a photo has been added
                    color: hasPhoto
                        ? const Color(0xFF84DCC6).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasPhoto
                          ? const Color(0xFF84DCC6)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasPhoto
                            ? Icons.check_circle_outline
                            : Icons.add_photo_alternate_outlined,
                        size: 16,
                        color: hasPhoto
                            ? const Color(0xFF84DCC6)
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: hasPhoto
                              ? const Color(0xFF84DCC6)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _openInterestPhotoSheet(String interest) async {
    final displayName = interest[0].toUpperCase() + interest.substring(1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // StatefulBuilder so the sheet can rebuild on photo pick/remove
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final data = _interestData[interest]!;
            final Uint8List? newBytes = data['bytes'] as Uint8List?;
            final String? savedUrl = data['url'] as String?;
            final bool hasPhoto = newBytes != null || savedUrl != null;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Handle bar ─────────────────────────────────────────
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Title ──────────────────────────────────────────────
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a photo that represents this interest.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // ── Photo preview or empty state ───────────────────────
                  if (hasPhoto)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: newBytes != null
                              ? Image.memory(
                                  newBytes,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  savedUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF84DCC6),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Remove button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              _removeInterestPhoto(interest);
                              // Also update the sheet's local state
                              setSheetState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // ── Empty placeholder ────────────────────────────────
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No photo yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Action button ──────────────────────────────────────
                  // ── Action buttons ─────────────────────────────────────────────────
                  Row(
                    children: [
                      // Change / Choose photo
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _pickInterestPhoto(interest);
                            setSheetState(() {});
                          },
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: Text(
                            hasPhoto ? 'Change Photo' : 'Choose Photo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF84DCC6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      // Only show confirm if a photo exists
                      if (hasPhoto) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF84DCC6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF84DCC6),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAutocompleteField({
    required String initialValue,
    required List<String> options,
    required String label,
    required IconData prefixIcon,
    required IconData itemIcon,
    required Color itemIconColor,
    required ValueChanged<String> onSelected,
    Key? key,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return options;
        return options.where(
          (option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, filteredOptions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = filteredOptions.elementAt(index);
                  return InkWell(
                    onTap: () => onSelectedOption(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(itemIcon, size: 18, color: itemIconColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        );
      },
      onSelected: (String value) {
        onSelected(value);
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildUniversityField() {
    return _buildAutocompleteField(
      key: const ValueKey('university'),
      initialValue: _selectedUniversity ?? '',
      options: londonUniversities,
      label: 'University',
      prefixIcon: Icons.school_outlined,
      itemIcon: Icons.school_outlined,
      itemIconColor: const Color(0xFF84DCC6),
      onSelected: (value) => setState(() => _selectedUniversity = value),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please select your university'
          : null,
    );
  }

  Widget _buildBoroughField() {
    return _buildAutocompleteField(
      key: const ValueKey('borough'),
      initialValue: _selectedBorough ?? '',
      options: londonBoroughs,
      label: 'Borough (optional)',
      prefixIcon: Icons.location_on_outlined,
      itemIcon: Icons.location_on_outlined,
      itemIconColor: const Color(0xFF84DCC6),
      onSelected: (value) => setState(() => _selectedBorough = value),
    );
  }

  Widget _buildYearGroupField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedYearGroup,
      decoration: InputDecoration(
        labelText: 'Year Group (optional)',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      hint: const Text('Select year group'),
      items: yearGroups.map((year) {
        final bool isPostgrad = year == 'Masters' || year == 'PhD';
        return DropdownMenuItem<String>(
          value: year,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPostgrad
                      ? const Color(0xFF84DCC6)
                      : year == 'Alumnus'
                      ? Colors.grey.shade400
                      : Colors.blue.shade200,
                ),
              ),
              Text(year),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedYearGroup = value),
    );
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
                      // ── Profile Picture ────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Column(
                            children: [
                              const Text(
                                'Profile Picture',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Upload a picture, preferably with you in it!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _imageBytes != null
                                        ? MemoryImage(_imageBytes!)
                                              as ImageProvider
                                        : _existingAvatarUrl != null
                                        ? NetworkImage(_existingAvatarUrl!)
                                        : null,
                                    child:
                                        (_imageBytes == null &&
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      const SizedBox(height: 16),

                      _buildUniversityField(),
                      const SizedBox(height: 16),

                      if (!widget.isSociety) ...[
                        _buildTextField(
                          controller: _courseController,
                          label: 'Course / Major',
                          icon: Icons.book_outlined,
                          required: false,
                        ),
                        const SizedBox(height: 16),

                        _buildYearGroupField(),
                        const SizedBox(height: 16),

                        _buildBoroughField(),
                        const SizedBox(height: 16),

                        // ── Interests ──────────────────────────────────
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
                        const SizedBox(height: 4),
                        const Text(
                          'Pick categories to explore interests',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: interestCategories.map((category) {
                            return GestureDetector(
                              onTap: () => _openCategorySheet(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      category.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        if (_interests.isNotEmpty) ...[
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _interests.map((interest) {
                              return Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                backgroundColor: Colors.grey.shade200,
                                deleteIcon: const Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onDeleted: () => setState(() {
                                  _interests.remove(interest);
                                  _interestData.remove(interest);
                                }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // ── Interest Photos ────────────────────────────
                          _buildPhotoGallery(),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // ── Bio ───────────────────────────────────────────
                      const Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Introduce yourself!',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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

  Future<void> _openCategorySheet(InterestCategory category) async {
    List<String> promotedInterests = [];
    try {
      promotedInterests = await fetchPromotedInterests(category.name);
    } catch (_) {}

    final allOptions = [
      ...category.subcategories,
      ...promotedInterests.where(
        (p) => !category.subcategories
            .map((s) => s.toLowerCase())
            .contains(p.toLowerCase()),
      ),
    ];

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => CategorySheet(
        category: category,
        allOptions: allOptions,
        promotedInterests: promotedInterests,
        selectedInterests: _interests,
        maxInterests: _maxInterests,
        onToggle: (interest) {
          final normalised = interest.toLowerCase();
          setState(() {
            if (_interests.contains(normalised)) {
              _interests.remove(normalised);
              _interestData.remove(normalised);
            } else if (_interests.length < _maxInterests) {
              _interests.add(normalised);
              // Initialise with no photo
              _interestData[normalised] = {
                'url': null,
                'bytes': null,
                'file': null,
              };
            } else {
              _showError('Maximum of $_maxInterests interests reached.');
            }
          });
        },
        onCustomAdd: (text) async {
          if (_interests.contains(text)) {
            _showError('You\'ve already added "$text".');
            return;
          }
          if (_interests.length >= _maxInterests) {
            _showError('Maximum of $_maxInterests interests reached.');
            return;
          }
          try {
            await suggestInterest(interest: text, category: category.name);
          } catch (_) {}
          setState(() {
            _interests.add(text);
            _interestData[text] = {'url': null, 'bytes': null, 'file': null};
          });
        },
      ),
    );
  }

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
