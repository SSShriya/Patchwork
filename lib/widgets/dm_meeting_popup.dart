import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DMMeetingPopup extends StatefulWidget {
  final String? initialDate;
  final String? initialTime;
  final String? initialLocation;

  const DMMeetingPopup({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialLocation,
  });

  @override
  State<DMMeetingPopup> createState() => _DMMeetingPopupState();
}

class _DMMeetingPopupState extends State<DMMeetingPopup> {
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

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
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0XFF8789C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0XFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0XFF8789C0),
              onSurface: Color(0XFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine validation status to drive UI changes dynamically
    final bool isFormValid = _selectedDate != null && _selectedTime != null;

    final String dateButtonText = _selectedDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!)
        : 'Choose Date *'; // Appended asterisk for required hint

    final String timeButtonText = _selectedTime != null
        ? _selectedTime!.format(context)
        : 'Choose Time *';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Suggest a Meeting',
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0XFF8789C0),
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

              // 1. Date Selector Button
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
                icon: const Icon(
                  Icons.calendar_month,
                  color: Color(0XFF8789C0),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateButtonText,
                    style: TextStyle(
                      color: _selectedDate != null
                          ? const Color(0XFF222222)
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
                        : const Color(0XFF8789C0).withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Time Selector Button
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
                icon: const Icon(
                  Icons.access_time_filled,
                  color: Color(0XFF8789C0),
                ),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeButtonText,
                    style: TextStyle(
                      fontFamily: 'Bitter',
                      color: _selectedTime != null
                          ? const Color(0XFF222222)
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
                        : const Color(0XFF8789C0).withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Location Input Field
              const Text(
                'Location (Optional)',
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter a venue or postcode...',
                  hintStyle: const TextStyle(fontFamily: 'Bitter'),
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0XFF8789C0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0XFF8789C0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Action Confirmation Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Dynamic color tuning based on complete status
                  backgroundColor: isFormValid
                      ? const Color(0XFF8789C0)
                      : Colors.grey[300],
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
                  // Hard stop: Guard clause evaluating missing selections
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
                    return; // Terminates execution out early
                  }

                  // Safe formatting execution block
                  final String finalDate = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_selectedDate!);
                  final String finalTime = _selectedTime!.format(context);

                  Navigator.pop(context, {
                    'date': finalDate,
                    'time': finalTime,
                    'location': _locationController.text.trim(),
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
