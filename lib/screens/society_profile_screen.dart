import 'dart:typed_data';
import 'package:drp/tools/scalloped_clipper.dart';
import 'package:drp/tools/stitched_border_painter.dart';
import 'package:drp/tools/stitched_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/session_manager.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/society_service.dart';
import 'package:drp/services/utils.dart';

class SocietyProfileScreen extends StatefulWidget {
  const SocietyProfileScreen({super.key});

  @override
  State<SocietyProfileScreen> createState() => _SocietyProfileScreenState();
}

class _SocietyProfileScreenState extends State<SocietyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String _societyId = '';
  String? _societyName;
  String? _existingImageUrl;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  bool _canContact = false;
  final _aboutController = TextEditingController();
  List<Map<String, dynamic>> _committee = [];
  bool _disposed = false;

  final SocietyService _societyService = SocietyService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/textures/bg_texture.jpg'), context);
  }

  @override
  void dispose() {
    _disposed = true;
    _aboutController.dispose();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    if (_disposed) return;
    setState(() => _isLoading = true);
    try {
      _societyId = await loadUserId();
      if (_societyId.isEmpty || _disposed) return;

      final socData = await supabase
          .from('users')
          .select()
          .eq('id', _societyId)
          .maybeSingle();

      final committeeData = await _societyService.getCommittee(_societyId);

      if (_disposed || !mounted) return;

      if (socData != null) {
        setState(() {
          _societyName = socData['name'] ?? '';
          _aboutController.text = socData['bio'] ?? '';
          // _about = aboutController.text;
          _existingImageUrl = socData['avatar_url'];
          _canContact = socData['can_message'] ?? false;
          _committee = committeeData;
        });
      }
    } catch (e) {
      if (_disposed || !mounted) return;
      if (e.toString().contains('User session not found')) return;
      _snack('Failed to load profile.');
    } finally {
      if (!_disposed && mounted) setState(() => _isLoading = false);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveDetails() async {
    if (_disposed || !_formKey.currentState!.validate()) return;
    if (_societyId.isEmpty) {
      _snack('User session not found. Please log in again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Image is already uploaded in _pickImage, just save bio here
      await _societyService.updateSocDetails(
        id: _societyId,
        bio: _aboutController.text.trim(),
      );
      if (_disposed) return;
      await _loadProfile();
      if (!_disposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully!')),
        );
      }
    } catch (e) {
      _snack('An unexpected error occurred while saving.');
    } finally {
      if (!_disposed && mounted) setState(() => _isLoading = false);
    }
  }

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();

    // Show preview immediately
    setState(() {
      _imageBytes = bytes;
    });

    // Upload straight away — no save button needed
    if (_societyId.isEmpty) {
      _snack('Session not found. Please log in again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _societyService.uploadSocImage(picked, _societyId);
      if (_disposed || !mounted) return;

      // Re-fetch the saved URL from DB so it displays correctly
      final socData = await supabase
          .from('users')
          .select('avatar_url')
          .eq('id', _societyId)
          .maybeSingle();

      if (_disposed || !mounted) return;

      setState(() {
        _existingImageUrl = socData?['avatar_url'];
        // Clear the local file/bytes — now using the remote URL
        _imageBytes = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      if (!_disposed && mounted) _snack('Failed to upload image.');
      // Revert preview on failure
      setState(() {
        _imageBytes = null;
      });
    } finally {
      if (!_disposed && mounted) setState(() => _isLoading = false);
    }
  }

  // ── Edit about dialog ──────────────────────────────────────────────────────
  void _editAbout() {
    final tempController = TextEditingController(text: _aboutController.text);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit About Section',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              content: TextField(
                controller: tempController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell others about your society...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = tempController.text.trim();
                    final nav = Navigator.of(ctx);

                    try {
                      await _societyService.updateSocDetails(
                        id: _societyId,
                        bio: text,
                      );
                    } catch (e) {
                      if (mounted) _snack('Failed to update about section.');
                      return; //
                    }

                    if (!mounted) return;
                    setState(() => _aboutController.text = text);
                    nav.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84DCC6),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      tempController.dispose();
    });
  }

  // ── Contact toggle ─────────────────────────────────────────────────────────
  Future<void> _updateContactStatus(bool value) async {
    if (_disposed) return;
    setState(() => _canContact = value);
    try {
      await supabase
          .from('users')
          .update({'can_message': value})
          .eq('id', _societyId);
    } catch (e) {
      if (_disposed) return;
    }
  }

  // ── Committee ──────────────────────────────────────────────────────────────
  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Committee Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  roleController.text.isNotEmpty) {
                final nav = Navigator.of(ctx);
                try {
                  await _societyService.addCommitteeMember(
                    societyId: _societyId,
                    name: nameController.text,
                    role: roleController.text,
                  );
                  await _loadProfile();
                } catch (_) {
                  _snack('Failed to add committee member.');
                }
                nav.pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(dynamic id) async {
    try {
      await _societyService.removeCommitteeMember(id);
      if (_disposed) return;
      await _loadProfile();
    } catch (e) {
      _snack('Failed to remove member.');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await supabase.auth.signOut();
      await SessionManager.clearSession();

      // auth listener in main.dart handles navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _snack(String msg) {
    if (_disposed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // BACKGROUND IMG
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/textures/bg_texture.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0xFFF5F0F6).withValues(alpha: 0.4),
                    BlendMode.multiply,
                  ),
                ),
              ),
            ),
          ),
        ),

        // CONTENT
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 10),
            child: ClipPath(
              clipper: ScallopedClipper(),
              child: AppBar(
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontFamily: 'Lora',
                  ),
                ),
                flexibleSpace: Opacity(
                  opacity: 0.6,
                  child: Image(
                    image: AssetImage('assets/images/teal_gingham.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                centerTitle: true,
                foregroundColor: const Color(0xFF222222),
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF222222),
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.save),
                          tooltip: 'Save Details',
                          onPressed: _saveDetails,
                        ),
                ],
              ),
            ),
          ),

          body: _isLoading && _societyName == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // ── Avatar ───────────────────────────────────────────
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              // ── Avatar in build — use MemoryImage for preview like ProfileScreen ──────
                              CircleAvatar(
                                // ✅ Key forces Flutter to rebuild the widget when the URL changes
                                key: ValueKey(_existingImageUrl),
                                radius: 60,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: _imageBytes != null
                                    ? MemoryImage(_imageBytes!) as ImageProvider
                                    : (_existingImageUrl != null &&
                                          _existingImageUrl!.isNotEmpty)
                                    ? NetworkImage(_existingImageUrl!)
                                    : null,
                                child:
                                    (_imageBytes == null &&
                                        (_existingImageUrl == null ||
                                            _existingImageUrl!.isEmpty))
                                    ? const Icon(
                                        Icons.person,
                                        size: 65,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),

                              const Positioned(
                                bottom: 0,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFF4D5359),
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Society name ─────────────────────────────────────
                        Text(
                          _societyName ?? 'UNKNOWN',
                          style: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Contact toggle ───────────────────────────────────
                        _StitchedCard(
                          color: const Color(0xFFEEDDEE),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _canContact,
                                onChanged: (val) {
                                  if (val != null) _updateContactStatus(val);
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Check this box if your committee members can be contacted on this app!',
                                  style: TextStyle(
                                    color: Color(0xFF222222),
                                    fontSize: 13,
                                    fontFamily: 'Montserrat',
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Committee members ────────────────────────────────
                        if (_canContact) ...[
                          const SizedBox(height: 10),
                          _StitchedCard(
                            color: const Color(0xFFEEDDEE),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'COMMITTEE MEMBERS',
                                      style: TextStyle(
                                        color: Color(0xFF222222),
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Color(0xFF4F3E92),
                                      ),
                                      onPressed: _showAddMemberDialog,
                                      tooltip: 'Add Member',
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.black12),
                                if (_committee.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Text(
                                      'No committee members added yet.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _committee.length,
                                    itemBuilder: (context, index) {
                                      final member = _committee[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.white60,
                                          child: Icon(
                                            Icons.person,
                                            color: Color(0xFF222222),
                                          ),
                                        ),
                                        title: Text(
                                          member['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        subtitle: Text(
                                          member['role'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              _removeMember(member['id']),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // ── About ────────────────────────────────────────────
                        _StitchedCard(
                          color: const Color(0x5F79C99E),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ABOUT THE SOCIETY',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      color: Color(0xFF4D5359),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Color(0xFF4D5359),
                                    ),
                                    onPressed: _editAbout,
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _aboutController.text.isNotEmpty
                                    ? _aboutController.text
                                    : 'No description provided yet. Click the edit icon to write something!',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  color: Color(0x9F4D5359),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Logout ───────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: StitchedButton(
                            label: 'LOG OUT',
                            onPressed: _isLoading ? null : _logout,
                            backgroundColor: const Color(0xFFfd5757),
                            stitchColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StitchedCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const _StitchedCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: StitchedBorderPainter(
        stitchColor: Colors.white.withValues(alpha: 0.8),
        strokeWidth: 2.6,
        dashLength: 8.0,
        gapLength: 8.0,
        borderRadius: 16.0,
        inset: 6.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}
