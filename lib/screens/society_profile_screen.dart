import 'dart:io';

import 'package:drp/services/society_events_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SocietyProfileScreen extends StatefulWidget {
  const SocietyProfileScreen({super.key});

  @override
  State<SocietyProfileScreen> createState() => _SocietyProfileScreenState();
}

class _SocietyProfileScreenState extends State<SocietyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickSocietyImage(SocietySharedState state) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      await state.saveProfileImage(File(pickedFile.path));
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveDetails(SocietySharedState state) async {
    if (!_formKey.currentState!.validate()) return;
    if (state.societyId.isEmpty) {
      _snack('User session not found. Please log in again.');
      return;
    }
    try {
      await state.saveDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully!')),
        );
      }
    } catch (_) {
      _snack('An unexpected error occurred while saving.');
    }
  }

  // ── Edit about dialog ──────────────────────────────────────────────────────
  void _editAboutMe(SocietySharedState state) {
    final tempController = TextEditingController(
      text: state.aboutController.text,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await state.updateAbout(tempController.text.trim());
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84DCC6),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Add committee member dialog ────────────────────────────────────────────
  void _showAddMemberDialog(SocietySharedState state) {
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
                  await state.addCommitteeMember(
                    nameController.text,
                    roleController.text,
                  );
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

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout(SocietySharedState state) async {
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
    if (confirmed != true) return;
    await state.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/signup');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SocietySharedState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF84DCC6),
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          state.isLoading
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
                  onPressed: () => _saveDetails(state),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // ── Avatar ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _pickSocietyImage(state),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: state.imageFile != null
                          ? FileImage(state.imageFile!)
                          : (state.existingImageUrl != null &&
                                state.existingImageUrl!.isNotEmpty)
                          ? NetworkImage(state.existingImageUrl!)
                                as ImageProvider
                          : null,
                      child:
                          (state.imageFile == null &&
                              (state.existingImageUrl == null ||
                                  state.existingImageUrl!.isEmpty))
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

              // ── Society name ─────────────────────────────────────────────
              Text(
                state.societyName ?? 'UNKNOWN',
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 24),

              // ── Contact toggle ───────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFFEEDDEE),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: state.canContact,
                        onChanged: (val) async {
                          if (val != null) {
                            await state.updateContactStatus(val);
                          }
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
              ),

              // ── Committee members ────────────────────────────────────────
              if (state.canContact) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFEEDDEE),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              onPressed: () => _showAddMemberDialog(state),
                              tooltip: 'Add Member',
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black12),
                        if (state.committee.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.committee.length,
                            itemBuilder: (context, index) {
                              final member = state.committee[index];
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
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      state.removeCommitteeMember(member['id']),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── About ────────────────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0x5F79C99E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            onPressed: () => _editAboutMe(state),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.aboutController.text.isNotEmpty
                            ? state.aboutController.text
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
              ),
              const SizedBox(height: 32),

              // ── Logout ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () => _logout(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfd5757),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
