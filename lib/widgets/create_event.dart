import 'dart:io';
import 'package:drp/widgets/pick_location_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Data class returned when the user confirms the form.
class NewEventData {
  final String name;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final String location;
  final double? latitude;
  final double? longitude;
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
    required this.latitude,
    required this.longitude,
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
  double? existingLatitude,
  double? existingLongitude,
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
      existingLongitude: existingLongitude,
      existingLatitude: existingLatitude,
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
  final double? existingLatitude;
  final double? existingLongitude;
  final double? existingPrice;
  final String? existingDescription;

  const _CreateEventForm({
    this.existingName,
    this.existingStartDate,
    this.existingStartTime,
    this.existingEndDate,
    this.existingEndTime,
    this.existingLocation,
    this.existingLongitude,
    this.existingLatitude,
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

  // Location
  LatLng? _pickedLocation;

  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate text controllers with existing data or default to empty strings
    _nameController = TextEditingController(text: widget.existingName ?? '');
    _locationController = TextEditingController(
      text: widget.existingLocation ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingPrice != null
          ? widget.existingPrice!
                .toStringAsFixed(2)
                .replaceAll(RegExp(r'\.00$'), '')
          : '',
    );
    _descController = TextEditingController(
      text: widget.existingDescription ?? '',
    );

    // Pre-populate dates and times
    _startDate = widget.existingStartDate;
    _startTime = widget.existingStartTime;
    _endDate = widget.existingEndDate;
    _endTime = widget.existingEndTime;

    // pre-populate coords
    _pickedLocation =
        (widget.existingLatitude != null && widget.existingLongitude != null)
        ? LatLng(widget.existingLatitude!, widget.existingLongitude!)
        : null;
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
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final first = isStart
        ? (widget.existingStartDate ?? now)
        : (_startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
          ),
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
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) setState(() => _imageFile = File(file.path));
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationMap(initialLocation: _pickedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _pickedLocation = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Custom check: Ensure either typed location or map coordinate is chosen
    final textLocation = _locationController.text.trim();
    if (textLocation.isEmpty && _pickedLocation == null) {
      _snack('Please type an address or select a location on the map.');
      return;
    }

    if (_startDate == null || _startTime == null) {
      _snack('Please set a start date and time.');
      return;
    }
    if (_endDate == null || _endTime == null) {
      _snack('Please set an end date and time.');
      return;
    }

    final startDT = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDT = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
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
      // If text string is empty but pin exists, fallback to a readable coordinate string
      location: textLocation.isNotEmpty 
          ? textLocation 
          : '${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}',
      latitude: _pickedLocation?.latitude,
      longitude: _pickedLocation?.longitude,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      image: _imageFile,
    );

    debugPrint('pickedLocation: $_pickedLocation');
    debugPrint('result lat: ${result.latitude}');
    debugPrint('result lng: ${result.longitude}');

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
            Container(
              width: double.infinity,
              color: const Color.fromARGB(255, 131, 187, 219),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                isEditingMode ? 'EDIT EVENT' : 'NEW EVENT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lora',
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
                      const SizedBox(height: 25),

                      _field(
                        controller: _nameController,
                        label: 'Event Name',
                        icon: Icons.celebration_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      _SectionLabel(
                        label: 'Start Date & Time',
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(isStart: true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(_fmt(_startDate)),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(isStart: true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  prefixIcon: const Icon(
                                    Icons.access_time_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(_fmtTime(_startTime)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _SectionLabel(
                        label: 'End Date & Time',
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(isStart: false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(_fmt(_endDate)),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(isStart: false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  prefixIcon: const Icon(
                                    Icons.access_time_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(_fmtTime(_endTime)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Type an address or pick on map',
                          prefixIcon: Icon(
                            _pickedLocation != null
                                ? Icons.location_pin
                                : Icons.location_on_outlined,
                            color: _pickedLocation != null
                                ? const Color(0xFF84DCC6)
                                : null,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_pickedLocation != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Clear map pin',
                                  onPressed: () =>
                                      setState(() => _pickedLocation = null),
                                ),
                              IconButton(
                                icon: const Icon(Icons.map_outlined),
                                tooltip: 'Pick on map',
                                onPressed: _pickLocation,
                              ),
                            ],
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Removed strict validator here so form can process logic dynamically in _save()
                      ),

                      if (_pickedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Color(0xFF84DCC6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Map pin attached',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),

                      _field(
                        controller: _priceController,
                        label: 'Price (£)',
                        icon: Icons.currency_pound_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter a price (0 if free)';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Enter a valid number';
                          }
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
                        label: _isSaving
                            ? ''
                            : (isEditingMode ? 'SAVE CHANGES' : 'CREATE EVENT'),
                        color: const Color.fromARGB(255, 164, 204, 228),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 10),

                      _ActionButton(
                        label: 'Cancel',
                        color: const Color.fromARGB(255, 217, 218, 219),
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
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.2,
        color: color,
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
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: Color(0xFF4D5359),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add banner image (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4D5359),
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0XFF84DCC6),
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child ??
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
      ),
    );
  }
}