import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Data class returned when the user confirms the form.
class NewEventData {
  final String name;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final String location;
  final double price;
  final String? description;
  final File? image;

  const NewEventData({
    required this.name,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.location,
    required this.price,
    this.description,
    this.image,
  });
}

/// Shows the popup and returns [NewEventData] if the user saves, or null if cancelled.
/// Optional named parameters handle autofilling when editing an existing event.
Future<NewEventData?> showNewEventPopup(
  BuildContext context, {
  String? existingName,
  DateTime? existingStartDate,
  TimeOfDay? existingStartTime,
  DateTime? existingEndDate,
  TimeOfDay? existingEndTime,
  String? existingLocation,
  double? existingPrice,
  String? existingDescription,
}) {
  return showDialog<NewEventData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateEventForm(
      existingName: existingName,
      existingStartDate: existingStartDate,
      existingStartTime: existingStartTime,
      existingEndDate: existingEndDate,
      existingEndTime: existingEndTime,
      existingLocation: existingLocation,
      existingPrice: existingPrice,
      existingDescription: existingDescription,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _CreateEventForm extends StatefulWidget {
  final String? existingName;
  final DateTime? existingStartDate;
  final TimeOfDay? existingStartTime;
  final DateTime? existingEndDate;
  final TimeOfDay? existingEndTime;
  final String? existingLocation;
  final double? existingPrice;
  final String? existingDescription;

  const _CreateEventForm({
    this.existingName,
    this.existingStartDate,
    this.existingStartTime,
    this.existingEndDate,
    this.existingEndTime,
    this.existingLocation,
    this.existingPrice,
    this.existingDescription,
  });

  @override
  State<_CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<_CreateEventForm> {
  static const _teal = Color(0XFF84DCC6);
  static const _dark = Color(0XFF222222);

  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  // Date / time state
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate text controllers with existing data or default to empty strings
    _nameController = TextEditingController(text: widget.existingName ?? '');
    _locationController = TextEditingController(text: widget.existingLocation ?? '');
    _priceController = TextEditingController(
      text: widget.existingPrice != null ? widget.existingPrice!.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '') : '',
    );
    _descController = TextEditingController(text: widget.existingDescription ?? '');

    // Pre-populate dates and times
    _startDate = widget.existingStartDate;
    _startTime = widget.existingStartTime;
    _endDate = widget.existingEndDate;
    _endTime = widget.existingEndTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime? d) =>
      d == null ? 'Select date' : '${d.day}/${d.month}/${d.year}';

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Select time' : t.format(context);

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final first = isStart ? (widget.existingStartDate ?? now) : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? _startTime ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _imageFile = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null) {
      _snack('Please set a start date and time.');
      return;
    }
    if (_endDate == null || _endTime == null) {
      _snack('Please set an end date and time.');
      return;
    }

    final startDT = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    final endDT = DateTime(
      _endDate!.year, _endDate!.month, _endDate!.day,
      _endTime!.hour, _endTime!.minute,
    );

    if (!endDT.isAfter(startDT)) {
      _snack('End must be after start.');
      return;
    }

    setState(() => _isSaving = true);

    final result = NewEventData(
      name: _nameController.text.trim(),
      startDate: _startDate!,
      startTime: _startTime!,
      endDate: _endDate!,
      endTime: _endTime!,
      location: _locationController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      image: _imageFile,
    );

    if (mounted) Navigator.of(context).pop(result);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditingMode = widget.existingName != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header adapts conditionally based on mode
            Container(
              width: double.infinity,
              color: _teal,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                isEditingMode ? 'EDIT EVENT' : 'NEW EVENT',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ImagePicker(file: _imageFile, onTap: _pickImage),
                      const SizedBox(height: 20),

                      _field(
                        controller: _nameController,
                        label: 'Event Name',
                        icon: Icons.celebration_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 14),

                      _SectionLabel(label: 'START', color: _teal),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _DateTimeTile(
                            icon: Icons.calendar_today_outlined,
                            value: _fmt(_startDate),
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateTimeTile(
                            icon: Icons.access_time_outlined,
                            value: _fmtTime(_startTime),
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      _SectionLabel(label: 'END', color: _teal),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _DateTimeTile(
                            icon: Icons.calendar_today_outlined,
                            value: _fmt(_endDate),
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateTimeTile(
                            icon: Icons.access_time_outlined,
                            value: _fmtTime(_endTime),
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      _field(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a location' : null,
                      ),
                      const SizedBox(height: 14),

                      _field(
                        controller: _priceController,
                        label: 'Price (£)',
                        icon: Icons.currency_pound_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter a price (0 if free)';
                          if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _field(
                        controller: _descController,
                        label: 'Description (optional)',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      _ActionButton(
                        label: _isSaving ? '' : (isEditingMode ? 'SAVE CHANGES' : 'CREATE EVENT'),
                        color: _teal,
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _ActionButton(
                        label: 'Cancel',
                        color: Colors.grey.shade300,
                        foreground: _dark,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0XFF84DCC6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16, vertical: maxLines > 1 ? 14 : 0,
        ),
      ),
    );
  }
}

// (Keep all your small reusable sub-widgets exactly the same below)
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: color,
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: isPlaceholder ? Colors.grey.shade400 : const Color(0XFF222222),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  const _ImagePicker({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          image: file != null
              ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
              : null,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text(
                    'Add banner image (optional)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0XFF84DCC6),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;
  final Widget? child;

  const _ActionButton({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
    this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child ??
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
      ),
    );
  }
}