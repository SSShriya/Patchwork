import 'package:drp/widgets/pick_location_map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class DMMeetingPopup extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final String? initialLocation;
  final double? initialLat;
  final double? initialLng;

  const DMMeetingPopup({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialLocation,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DMMeetingPopup> createState() => _DMMeetingPopupState();
}

class _DMMeetingPopupState extends State<DMMeetingPopup> {
  static const _purple = Color(0xFF8789C0);

  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _pickedLatLng; // null  →  no map pin attached

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!);
    }
    if (widget.initialTime != null) {
      final parts = widget.initialTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (widget.initialLocation != null) {
      _locationController.text = widget.initialLocation!;
    }
    if (widget.initialLat != null && widget.initialLng != null) {
      _pickedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF222222),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _purple,
            onSurface: Color(0xFF222222),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  /// Opens the full-screen map picker and stores the result.
  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationMap(initialLocation: _pickedLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLatLng = result;
        // Clear any manual text so the coords are the source of truth,
        // but only if the field is currently empty.
        if (_locationController.text.trim().isEmpty) {
          _locationController.text =
              '${result.latitude.toStringAsFixed(5)}, '
              '${result.longitude.toStringAsFixed(5)}';
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _selectedDate != null && _selectedTime != null;

    final String dateButtonText = _selectedDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)
        : 'Choose Date *';

    final String timeButtonText = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Choose Time *';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Suggest a Meeting',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // optional: prevent text wrapping
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // ── Date ─────────────────────────────────────────────────────
              const Text(
                'Date *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Bitter',
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month, color: _purple),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateButtonText,
                    style: TextStyle(
                      color: _selectedDate != null
                          ? const Color(0xFF222222)
                          : Colors.grey[600],
                      fontWeight: _selectedDate != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontFamily: 'Bitter',
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: _selectedDate != null
                        ? Colors.grey[400]!
                        : _purple.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Time ─────────────────────────────────────────────────────
              const Text(
                'Time *',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time_filled, color: _purple),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeButtonText,
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      color: _selectedTime != null
                          ? const Color(0xFF222222)
                          : Colors.grey[600],
                      fontWeight: _selectedTime != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: _selectedTime != null
                        ? Colors.grey[400]!
                        : _purple.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Location ─────────────────────────────────────────────────
              const Text(
                'Location (Optional)',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),

              // Text field
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter a venue or postcode...',
                  hintStyle: const TextStyle(fontFamily: 'Bitter'),
                  prefixIcon: Icon(
                    _pickedLatLng != null
                        ? Icons.location_pin
                        : Icons.location_on,
                    color: _pickedLatLng != null
                        ? const Color(0xFF84DCC6)
                        : _purple,
                  ),
                  // Clear-pin button appears once a pin is attached
                  suffixIcon: _pickedLatLng != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Remove map pin',
                          onPressed: () => setState(() => _pickedLatLng = null),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),

              // "Pick on Map" button — sits directly below the text field
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: _pickedLatLng != null
                      ? const Color(0xFF409A83)
                      : _purple,
                ),
                label: Text(
                  _pickedLatLng != null ? 'Map pin attached ✓' : 'Pick on Map',
                  style: TextStyle(
                    fontFamily: 'Bitter',
                    fontSize: 13,
                    color: _pickedLatLng != null
                        ? const Color(0xFF409A83)
                        : _purple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: _pickedLatLng != null
                        ? const Color(0xFF84DCC6)
                        : _purple.withValues(alpha: 0.4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Confirm ───────────────────────────────────────────────────
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid ? _purple : Colors.grey[300],
                  foregroundColor: isFormValid
                      ? Colors.white
                      : Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isFormValid ? 2 : 0,
                ),
                onPressed: () {
                  if (!isFormValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Please select both a Date and Time to continue.',
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                    'time': _selectedTime!.format(context),
                    'location': _locationController.text.trim(),
                    // null when no pin was placed — buildInvitePayload handles this
                    'lat': _pickedLatLng?.latitude,
                    'lng': _pickedLatLng?.longitude,
                  });
                },
                child: Text(
                  widget.initialDate != null
                      ? 'Update Invitation'
                      : 'Send Invitation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
