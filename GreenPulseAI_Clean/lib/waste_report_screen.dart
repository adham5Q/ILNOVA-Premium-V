import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class WasteReportScreen extends StatefulWidget {
  const WasteReportScreen({super.key});

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedWasteType;
  String? _selectedPriority;
  XFile? _attachedImage;
  bool _isSaving = false;

  final List<String> _wasteTypes = [
    'Accumulated Garbage',
    'Construction Waste',
    'Plastic Waste',
    'Water Pollution',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() {
          _attachedImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    if (_selectedWasteType == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select waste type and priority.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final description = _descriptionController.text.trim();

      // 1. Save locally in SQLite
      await DatabaseHelper.instance.insertReport(
        wasteType: _selectedWasteType!,
        priority: _selectedPriority!,
        description: description,
      );

      // 2. Save in Cloud Firestore
      await FirebaseFirestore.instance.collection('waste_reports').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
        'wasteType': _selectedWasteType,
        'priority': _selectedPriority,
        'description': description,
        'imagePath': _attachedImage?.path,
        'status': 'Submitted',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Environmental report saved successfully!'),
          backgroundColor: Color(0xFF16865C),
        ),
      );

      _formKey.currentState!.reset();
      _descriptionController.clear();

      setState(() {
        _selectedWasteType = null;
        _selectedPriority = null;
        _attachedImage = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved locally. Cloud sync warning: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16865C);
    const dark = Color(0xFF145A3A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Waste Issue'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  size: 64,
                  color: green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Report an Environmental Issue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Provide details about the waste problem in your area to help clean up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 28),
                DropdownButtonFormField<String>(
                  key: ValueKey('wasteType_$_selectedWasteType'),
                  initialValue: _selectedWasteType,
                  decoration: const InputDecoration(
                    labelText: 'Waste Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.delete_outline, color: green),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _wasteTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedWasteType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a waste type' : null,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  key: ValueKey('priority_$_selectedPriority'),
                  initialValue: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority Level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a priority' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description & Location',
                    hintText: 'Describe the issue location and details...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined, color: green),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Enter at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                if (_attachedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_attachedImage!.path),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_outlined, color: green),
                  label: Text(
                    _attachedImage == null ? 'Attach Photo (Camera)' : 'Change Photo',
                    style: const TextStyle(color: green),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitReport,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isSaving ? 'Saving Report...' : 'Submit Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Reports are saved to local database & synchronized to Cloud Firestore.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
